import { CsvWriter } from '../Csv';
import { IDatabase } from '../Database';
import { Users } from './UserMatching';
import { pdAddressToSfAddress } from './AddressConversion';

import { fromPdStageId } from './Pipelines';

export async function exportAccounts(database: IDatabase, users: Users) {
    const csvWriter = new CsvWriter('Accounts.csv');
    const csvParentsWriter = new CsvWriter('Accounts-Parents.csv');

    const emailToOrgId = await getAllPeopleEmails(database);
    const orgsToGearsetTeamId = await getGearsetTeamIdForOrgId(database, emailToOrgId);

    interface DbOrg { Name: string; Id: number; Address: string; Website: string; CreatedAt: string; UpdatedAt: string; OwnerEmail: string | undefined, ParentId: number | undefined, Raw: string, SuccessStageId: number | undefined, CsmOwner: string | undefined, Value: number | undefined };
    const organizations = await database.query<DbOrg>(`
        WITH CsmOrg AS (SELECT owner.Email AS OwnerEmail, d.StageId AS happiness, o.Id AS OrgId, d.Value AS Value
            FROM (SELECT * FROM deals WHERE PipelineId = 25) d
                    LEFT JOIN people p ON p.Id = d.PersonId
                    LEFT JOIN organizations o
                            ON o.Id = d.OrganizationId OR o.id = p.OrganizationId OR o.Name = substr(d.Name, 8)
                    LEFT JOIN users owner ON d.OwnerId = owner.id
            WHERE o.Id IS NOT NULL
            GROUP BY d.Id)
        SELECT 
            o.Name            AS Name,
            o.Id              AS Id,
            o.Address         AS Address,
            o.Website         AS Website,
            o.CreatedAt       AS CreatedAt,
            o.UpdatedAt       AS UpdatedAt,
            owner.Email       AS OwnerEmail,
            o.ParentId        AS ParentId,
            csmorg.happiness  AS SuccessStageId,
            csmorg.OwnerEmail AS CsmOwner,
            csmorg.Value      AS Value,
            o.Raw             AS Raw
        FROM Organizations o
            LEFT JOIN users owner ON owner.Id = o.OwnerId
            LEFT JOIN CsmOrg csmorg ON csmorg.OrgId = o.Id
        GROUP BY o.Id
    `);

    csvWriter.writeRow(['Pipedrive_Id__c', 'Name', 'Website', 'Gearset_Team_Id__c', 'CreatedDate', 'LastModifiedDate', 'OwnerId', 'BillingCity', 'BillingCountry', 'BillingPostalCode', 'BillingState', 'BillingStreet', 'Churn_risk__c', 'MRR_c']);
    csvParentsWriter.writeRow(['Pipedrive_Id__c', 'Parent:Pipedrive_Id__c']);
    for (const org of organizations) {
        const pipedriveId = org.Id;
        const website = org.Website?.split(',')[0];
        const name = org.Name;
        const gearsetTeamId = orgsToGearsetTeamId[pipedriveId];

        const createdAt = new Date(org.CreatedAt).toISOString();
        const updatedAt = new Date(org.UpdatedAt).toISOString();

        const ownerId = await users.getUserIdForEmail(org.CsmOwner || org.OwnerEmail || 'kevin+gearbot@gearset.com');
    
        const rawData = JSON.parse(org.Raw);
        const address = pdAddressToSfAddress(rawData);

        const churnRisk = org.SuccessStageId ? fromPdStageId(org.SuccessStageId) : undefined;
        const mrr = org.Value?.toString();

        csvWriter.writeRow([pipedriveId.toString(), name, website, gearsetTeamId, createdAt, updatedAt, ownerId, address.City, address.Country, address.PostalCode, address.State, address.Street, churnRisk, mrr]);
    
        if (org.ParentId) {
            csvParentsWriter.writeRow([pipedriveId.toString(), org.ParentId.toString()]);
        }
    }

    csvWriter.end();
    csvParentsWriter.end();

    console.log('Upload Acccounts.csv using the salesforce data loader and then copy the success csv log to a file called account-upload.csv');
    console.log('Then upsert the Accounts-Parents.csv file.');
    console.log('You can then continue with contact export');
}

async function getAllPeopleEmails(database: IDatabase) {
    const peopleEmailToOrg: { [email: string]: {personId: number; orgId: number | undefined } } = {};
    interface DbPerson { Raw: string; OrganizationId: number | undefined; Id: number; };
    const people = await database.query<DbPerson>(`SELECT Id, OrganizationId, Raw FROM people`);
    people.forEach(person => {
        const raw = JSON.parse(person.Raw);
        const emails: { value: string; }[] = raw.email;
        emails.forEach(email => {
            if (!peopleEmailToOrg[email.value]?.orgId) {
                peopleEmailToOrg[email.value] = { personId: person.Id, orgId: person.OrganizationId}
            }
        });
    });
    
    return peopleEmailToOrg;
}

async function getGearsetTeamIdForOrgId(database: IDatabase, emails: {[email: string]: {personId: number, orgId: number | undefined}}) {
    interface GearsetTeamIdWithOwner { OwnerEmail: string; GearsetTeamId: string };
    const ownersAndTeamIds = await database.query<GearsetTeamIdWithOwner>(`SELECT OwnerEmail, GearsetTeamId FROM gearset_teams`);

    const gearsetTeamsWithoutOwners = new CsvWriter('Gearset-teams-without-organizations.csv');
    gearsetTeamsWithoutOwners.writeRow(['Gearset Team Id', 'Owner email', 'Pipedrive ID']);

    const orgIdToTeamId: { [orgId: number]: string } = {};
    ownersAndTeamIds.forEach(ownerAndTeamId => {
        const personInfo = emails[ownerAndTeamId.OwnerEmail];
        if (!personInfo) {
            gearsetTeamsWithoutOwners.writeRow([ownerAndTeamId.GearsetTeamId, ownerAndTeamId.OwnerEmail, 'unknown']);
            console.log(`Cannot find an org for team ID ${ownerAndTeamId.GearsetTeamId} with owner email ${ownerAndTeamId.OwnerEmail}`);
        } else {
            if (!personInfo.orgId) {
                gearsetTeamsWithoutOwners.writeRow([ownerAndTeamId.GearsetTeamId, ownerAndTeamId.OwnerEmail, personInfo.personId.toString()]);
            } else {
                orgIdToTeamId[personInfo.orgId] = ownerAndTeamId.GearsetTeamId;
            }
        }
    });

    gearsetTeamsWithoutOwners.end();

    const teamToOrgId: {[teamId: string]: number[]} = {};
    Object.entries(orgIdToTeamId).forEach(([orgId, teamId]) => (teamToOrgId[teamId] ??= []).push(+orgId));

    const teamsWithMoreThan1Org = new CsvWriter('Gearset-teams-with-mulitple-orgs.csv');
    Object.entries(teamToOrgId).forEach(([teamId, orgs]) => orgs.length > 1 ? teamsWithMoreThan1Org.writeRow([teamId, orgs.join(', ')]) : null);

    teamsWithMoreThan1Org.end();

    return orgIdToTeamId;
}