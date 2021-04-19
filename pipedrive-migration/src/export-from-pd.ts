'use strict';

import * as originalFetch from 'node-fetch';
import fetchRetry from 'fetch-retry';
import { Deal, fromPipedriveDeal } from './pipedrive/Deal';
import { Organization, fromPipedriveOrganization } from './pipedrive/Organization';
import { Person, fromPipedrivePerson } from './pipedrive/Person';
import { Note, fromPipedriveNote } from './pipedrive/Note';
import { User, fromPipedriveUser } from './pipedrive/User';
import { Email, fromPipedriveEmail } from './pipedrive/Email';
import { Activity, fromPipedriveActivity } from './pipedrive/Activity';
import { IDatabase, newPostgresConnection, newSqliteConnection } from './Database';
import { DealProduct, fromPipedriveDealProduct } from './pipedrive/DealProduct';
import { CsvWriter } from './Csv';

import { pipedriveApiKeys } from './PipedriveApiKeys';
import * as fs from 'fs';
import * as url from 'url';

import bbpromise from 'bluebird';

const wrappedFetch = fetchRetry(originalFetch as any);
async function fetch(url: string) {
    return await wrappedFetch(url, {
        retries: 10,
        retryDelay: 2000,
    });
}

const databaseFilename = process.argv[2];

if (databaseFilename) {
    console.log(`Using sqlite database with file name ${databaseFilename}`);
} else {
    console.log(`Using postgres database hosted at ${process.env.PGHOST}`);
}

let currentApiKey = 0;
function getPdApiKey() {
    return pipedriveApiKeys[currentApiKey++ % pipedriveApiKeys.length]
}

// annoyingly the node sqlite library doesn't do transactions properly and
// we need to add queuing code manually :/
const waitingQueries: (() => void)[] = [];
let queryRunning = false;

async function safeTransaction(db: IDatabase, fn: () => Promise<void>) {
    if (queryRunning) {
        await new Promise(resolve => waitingQueries.push(resolve));
    }

    if (queryRunning) {
        throw new Error('Query already running');
    }

    queryRunning = true;
    let success = false;
    try {
        await db.exec('BEGIN');
        await fn();
        success = true;
    } finally {
        try {
            if (success) {
                await db.exec('COMMIT');
            } else {
                await db.exec('ROLLBACK');
            }
        } finally {
            queryRunning = false;
            waitingQueries.pop()?.();
        }
    }
}

async function saveDeals(db: IDatabase, deals: (Deal & {raw: string})[]) {
    await safeTransaction(db, async () => {
        for (const deal of deals) {
            await db.run(
                `INSERT INTO deals (
                    Id,
                    Name,
                    Value,
                    Status,
                    PersonId,
                    OrganizationId,
                    StageId,
                    PipelineId,
                    LostReason,
                    OwnerId,
                    ApContactId,
                    CreatedAt,
                    UpdatedAt,
                    Raw
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                deal.id,
                deal.name,
                deal.value,
                deal.status,
                deal.personId,
                deal.organizationId,
                deal.stageId,
                deal.pipelineId,
                deal.lostReason,
                deal.ownerId,
                deal.apContactId,
                deal.createdAt,
                deal.updatedAt,

                deal.raw
            );
        }
    });
}

async function fetchDealProducts(deal: Deal) {
    const json = await makePipedriveCall(`https://gearset.pipedrive.com/api/v1/deals/${deal.id}/products?limit=500`);
    const dealProductsJson = json.data as any[];
    return dealProductsJson
        .map(rawDealProduct => 
            Object.assign(
                {
                    raw: JSON.stringify(rawDealProduct)
                },
                fromPipedriveDealProduct(rawDealProduct)
            )
        );
}

async function saveDealProducts(db: IDatabase, dealProducts: (DealProduct & {raw: string})[]) {
    await safeTransaction(db, async () => {
        for (const dealProduct of dealProducts) {
            await db.run(
                `INSERT INTO deal_products (
                    Id,
                    DealId,
                    ProductId,
                    Quantity,
                    ItemPrice,
                    Sum,

                    Raw
                ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
                dealProduct.id,
                dealProduct.dealId,
                dealProduct.productId,
                dealProduct.quantity,
                dealProduct.unitPrice,
                dealProduct.totalPrice,
                dealProduct.raw
            );
        }
    });
}

async function fetchParents<T extends {id: number}>(org: T): Promise<T & {parentId: number | undefined}> {
    const json = await makePipedriveCall(`https://gearset.pipedrive.com/api/v1/organizationRelationships?org_id=${org.id}`);

    const relationshipInfo = json.data as any[];
    const parent = relationshipInfo?.find(relationship => relationship.calculated_type === 'parent');

    const parentId = parent ? parent.calculated_related_org_id : undefined;
    return Object.assign({parentId}, org);
}

async function saveOrganizations(db: IDatabase, organizations: (Organization & {raw: string, parentId: number | undefined})[]) {
    await safeTransaction(db, async () => {
        for (const organization of organizations) {
            if (organization.parentId !== undefined) {
                console.log(`${organization.name} has a parent organization ${organization.parentId}!`);
            }

            await db.run(
                `INSERT INTO organizations (Id, Name, Address, Website, CreatedAt, UpdatedAt, OwnerId, ParentId, Raw) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                organization.id,
                organization.name,
                organization.address,
                organization.website,
                organization.createdAt,
                organization.updatedAt,
                organization.ownerId,
                organization.parentId,
                organization.raw
            )
        }
    });
}

async function savePeople(db: IDatabase, people: (Person & {raw: string})[]) {
    await safeTransaction(db, async () => {
        for (const person of people) {
            await db.run(
                `INSERT INTO people (
                    Id,
                    OrganizationId,
                    FirstName,
                    LastName,
                    Name,
                    Phone,
                    Email,
                    IntercomUrl,
                    LinkedinUrl,
                    CreatedAt,
                    UpdatedAt,
                    OwnerId,
                    Raw
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                person.id,
                person.organizationId,
                person.firstName,
                person.lastName,
                person.name,
                person.phone,
                person.email,
                person.intercomUrl,
                person.linkedinUrl,
                person.createdAt,
                person.updatedAt,
                person.ownerId,
                person.raw
            );
        }
    });
}

async function saveNotes(db: IDatabase, notes: (Note & {raw: string})[]) {
    await safeTransaction(db, async () => {
        for (const note of notes) {
            await db.run(
                `INSERT INTO notes (Id, DealId, PersonId, OrganizationId, UserId, PinnedToDeal, PinnedToPerson, PinnedToOrganization, Content, TimeAdded, TimeUpdated, Raw) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                note.id,
                note.dealId,
                note.personId,
                note.organizationId,
                note.userId,
                note.pinnedToDeal,
                note.pinnedToPerson,
                note.pinnedToOrganization,
                note.content,
                note.timeAdded,
                note.timeUpdated,
                note.raw
            );
        }
    });
}

async function saveUsers(db: IDatabase, users: (User & {raw: string})[]) {
    await safeTransaction(db, async () => {
        for (const user of users) {
            await db.run(
                `INSERT INTO users (
                    Id, Name, Email, Raw
                ) VALUES (?, ?, ?, ?)`,
                user.id,
                user.name,
                user.email,
                user.raw
            );
        }
    });
}

async function saveActivities(db: IDatabase, activities: (Activity & {raw: string})[]) {
    await safeTransaction(db, async () => {
        for (const activity of activities) {
            await db.run(
                `INSERT INTO activities (
                    Id,
                    OrgId,
                    DealId,
                    PersonId,
                    CreatedByUserId,
                    AssignedToUserId,
                    Subject,
                    Done,
                    DueDate,
                    DueTime,
                    Type,
                    Raw
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                activity.id,
                activity.orgId,
                activity.dealId,
                activity.personId,
                activity.createdByUserId,
                activity.assignedToUserId,
                activity.subject,
                activity.done,
                activity.dueDate,
                activity.dueTime,
                activity.type,
                activity.raw
            );
        }
    });
}

async function saveEmails(db: IDatabase, dealId: number, emails: (Email & {raw: string, body: string})[]) {
    await safeTransaction(db, async () => {
        for (const email of emails) {
            await db.run(`
                INSERT INTO emails (
                    Id,
                    DealId,
                    TimeAdded,
                    TimeUpdated,
                    FromAddress,
                    ToAddress,
                    Body,
                    CcAddresses,
                    Subject,
                    ThreadId,
                
                    Raw
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                email.id,
                dealId,
                email.timeAdded,
                email.timeUpdated,
                email.fromAddress,
                email.toAddresses.join(','),
                email.body,
                email.ccList.join(','),
                email.subject,
                email.threadId,
                email.raw,
            );
        }
    });
}

interface GearsetTeam { readonly owner_email: string; readonly team_id: string };
async function saveTeams(db: IDatabase, teams: GearsetTeam[]) {
    await safeTransaction(db, async () => {
        for (const team of teams) {
            await db.run(`INSERT INTO gearset_teams (
                    GearsetTeamId,
                    OwnerEmail
                ) VALUES (?, ?)`,
                team.team_id,
                team.owner_email
            );
        }
    });
}

async function delay(ms: number) {
    await new Promise(resolve => setTimeout(resolve, ms));
}

let shouldSleepAllPd = false;
async function makePipedriveCall(pdUrl: string): Promise<any> {
    if (shouldSleepAllPd) {
        await delay(2000); // PD rate limit resets every 2 seconds
        shouldSleepAllPd = false;
    }

    const parsedUrl = new url.URL(pdUrl);
    parsedUrl.searchParams.append('api_token', getPdApiKey());

    const response = await fetch(parsedUrl.toString());
    const json = await response.json();

    if (!json.success) {
        throw new Error(`Failed to fetch pipedrive data with url ${pdUrl}, body: ${JSON.stringify(json, null, 2)}`);
    }

    const rateLimitRemaining = parseInt(response.headers.get('x-ratelimit-remaining') || '10', 10);
    if (rateLimitRemaining < 10) {
        console.log(`Rate limit remaining: ${rateLimitRemaining}`);
    }

    if (rateLimitRemaining < 8) {
        console.log('Rate limit below 2, sleeping all PD activity for 2s');
        shouldSleepAllPd = true;
    }

    return json;
}

async function getPipedriveData(url: string, handleData: (data: any[]) => Promise<void>) {
    let start = 0;
    let shouldContinue = false;
    
    do {
        const newUrl = url + `&start=${start}`;
        console.log(`Fetching page ${start} ${newUrl}`);
        
        const json = await makePipedriveCall(newUrl);

        await handleData(json.data);

        shouldContinue = json.additional_data?.pagination?.more_items_in_collection;
        start = json.additional_data?.pagination?.next_start;
    } while (shouldContinue);
}

(async () => {
    const db = await (databaseFilename ? 
        newSqliteConnection(databaseFilename) : newPostgresConnection());

    await db.exec(`CREATE TABLE deals (
        Id INTEGER,
        Name TEXT,
        Value REAL,
        Status TEXT,
        PersonId INTEGER,
        OrganizationId INTEGER,
        StageId INTEGER,
        PipelineId INTEGER,
        OwnerId TEXT,
        LostReason TEXT,
        ApContactId INTEGER,
        CreatedAt TEXT,
        UpdatedAt TEXT,

        Raw TEXT
    )`);

    await db.exec(`CREATE TABLE organizations (
        Id INTEGER,
        Name TEXT,
        Address TEXT,
        Website TEXT,
        OwnerId INTEGER,
        CreatedAt TEXT,
        UpdatedAt TEXT,
        ParentId INTEGER,

        Raw TEXT
    )`);
    
    await db.exec(`CREATE TABLE people (
        Id INTEGER,
        OrganizationId INTEGER,
        FirstName TEXT,
        LastName TEXT,
        Name TEXT,
        Phone TEXT,
        Email TEXT,
        IntercomUrl TEXT,
        LinkedinUrl TEXT,
        OwnerId INTEGER,
        CreatedAt TEXT,
        UpdatedAt TEXT,

        Raw TEXT
    )`);

    await db.exec(`CREATE TABLE notes (
        Id INTEGER,
        DealId INTEGER,
        PersonId INTEGER,
        OrganizationId INTEGER,
        UserId INTEGER,

        PinnedToDeal BOOLEAN,
        PinnedToPerson BOOLEAN,
        PinnedToOrganization BOOLEAN,

        Content TEXT,
        TimeAdded TEXT,
        TimeUpdated TEXT,

        Raw TEXT
    )`);

    await db.exec(`CREATE TABLE users (
        Id INTEGER,
        Name TEXT,
        Email TEXT,

        Raw TEXT
    )`);

    await db.exec(`CREATE TABLE activities (
        Id INTEGER,
        OrgId INTEGER,
        DealId INTEGER,
        PersonId INTEGER,
        CreatedByUserId INTEGER,
        AssignedToUserId INTEGER,
        Subject TEXT,
        Done BOOLEAN,
        DueDate TEXT,
        DueTime TEXT,
        Type TEXT,

        Raw TEXT
    )`);

    await db.exec(`CREATE TABLE deal_products (
        Id INTEGER,
        DealId INTEGER,
        ProductId INTEGER,
        Quantity INTEGER,
        ItemPrice REAL,
        Sum REAL,

        Raw TEXT
    )`);

    await db.exec(`CREATE TABLE gearset_teams (
        GearsetTeamId TEXT,
        OwnerEmail TEXT
    )`);

    await db.exec(`CREATE TABLE emails (
        Id INTEGER,
        DealId INTEGER,
        TimeAdded TEXT,
        TimeUpdated TEXT,
        FromAddress TEXT,
        ToAddress TEXT,
        Body TEXT,
        CcAddresses TEXT,
        Subject TEXT,
        ThreadId INTEGER,
    
        Raw TEXT
    )`);

    {
        console.log('Fetching Gearset teams from admin site db');
        const teamsJson = fs.readFileSync('gearset-team-info.json').toString('utf8');

        const teams = JSON.parse(teamsJson) as GearsetTeam[];
        await saveTeams(db, teams);
    }

    const emailErrors = new CsvWriter('email-errors.csv');
    emailErrors.writeRow(['DealId', 'EmailId', 'Err']);
    
    const fetchDeals = async () => {
        console.log('Fetching deals');
        await getPipedriveData(`https://gearset.pipedrive.com/api/v1/deals?limit=500`, async dealsJson => {
            const deals = dealsJson.map(deal => Object.assign({raw: JSON.stringify(deal)}, fromPipedriveDeal(deal)));

            const dealsWithProducts = dealsJson.filter(deal => deal.products_count > 0);
            console.log('Fetching deal products');
            const dealProducts = (await bbpromise.map(dealsWithProducts, fetchDealProducts, {concurrency: pipedriveApiKeys.length})).flat();
            
            console.log('Fetching emails');
            await bbpromise.map(deals, async deal => {
                await getPipedriveData(`https://gearset.pipedrive.com/api/v1/deals/${deal.id}/mailMessages?limit=500`, async emailJson => {
                    if (!emailJson) {
                        return;
                    }

                    const emails = emailJson.map(e => Object.assign({raw: JSON.stringify(e)}, fromPipedriveEmail(e)));
                    const emailsWithBodies = await bbpromise.map(emails, async e => {
                        try {
                            const emailBody = await fetch(e.bodyUrl);
                            const emailBodyText = await emailBody.text();
                            return Object.assign({body: emailBodyText}, e);
                        } catch (err) {
                            emailErrors.writeRow([deal.id.toString(), e.id.toString(), err.message]);
                            return Object.assign({body: 'Failed to fetch email body'}, e);
                        }
                    }, {concurrency: 10});

                    await saveEmails(db, deal.id, emailsWithBodies);
                });
            }, {concurrency: pipedriveApiKeys.length * 2});

            await saveDeals(db, deals);
            await saveDealProducts(db, dealProducts);
        });
    };

    const fetchOrganizations = async () => {
        console.log('Fetching organizations');
        await getPipedriveData(`https://gearset.pipedrive.com/api/v1/organizations?limit=500`, async organizationsJson => {
            const organizations = organizationsJson.map(organization => Object.assign({raw: JSON.stringify(organization)}, fromPipedriveOrganization(organization)));
            console.log('fetching parents');
            const organizationsWithParents = await bbpromise.map(
                organizations,
                org => fetchParents(org),
                {
                    concurrency: pipedriveApiKeys.length
                }
            );

            await saveOrganizations(db, organizationsWithParents);
        });
    };

    const fetchPeople = async () => {
        console.log('Fetching people');
        await getPipedriveData(`https://gearset.pipedrive.com/api/v1/persons?limit=500`, async peopleJson => {
            const people = peopleJson.map(person => Object.assign({raw: JSON.stringify(person)}, fromPipedrivePerson(person)));
            await savePeople(db, people);
        });
    };

    const fetchNotes = async () => {
        console.log('Fetching notes');
        await getPipedriveData(`https://gearset.pipedrive.com/api/v1/notes?limit=500`, async notesJson => {
            const notes = notesJson.map(note => Object.assign({raw: JSON.stringify(note)}, fromPipedriveNote(note)));
            await saveNotes(db, notes);
        });
    };

    const fetchUsers = async () => {
        console.log('Fetching users');
        await getPipedriveData(`https://gearset.pipedrive.com/api/v1/users?limit=500`, async usersJson => {
            const users = usersJson.map(user => Object.assign({raw: JSON.stringify(user)}, fromPipedriveUser(user)));
            await saveUsers(db, users);
        });
    };

    const fetchActivities = async () => {
        console.log('Fetching activities');
        await getPipedriveData(`https://gearset.pipedrive.com/api/v1/activities?limit=500&user_id=0`, async activitiesJson => {
            const activities = activitiesJson.map(activity => Object.assign({raw: JSON.stringify(activity)}, fromPipedriveActivity(activity)));
            await saveActivities(db, activities);
        });
    };

    await Promise.all([
        fetchDeals(),
        fetchOrganizations(),
        fetchPeople(),
        fetchNotes(),
        fetchUsers(),
        fetchActivities(),
    ]);
})().catch(err => {
    console.error(err);
});