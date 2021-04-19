import { CsvWriter } from "../Csv";
import { IDatabase } from "../Database";
import { getPdToSfMap } from "./SalesforceUploadResultParser";
import { Users } from "./UserMatching";

export async function exportEmails(database: IDatabase, users: Users) {
    const emailMessagesPart1 = new CsvWriter('EmailMessagesPart1.csv');
    const emailMessagesPart2 = new CsvWriter('EmailMessagesPart2.csv');
    const emailMessageRelations = new CsvWriter('EmailMessageRelations.csv');
    
    const leadIdToSfId = await getPdToSfMap('lead-upload.csv');
    const oppIdToSfId = await getPdToSfMap('opportunity-upload.csv');
    const personToSfId = await getPdToSfMap('contact-upload.csv');

    interface DbEmail {
        readonly Id: number;
        readonly DealId: number;
        readonly TimeAdded: string;
        readonly TimeUpdated: string;

        readonly FromAddress: string;
        readonly ToAddress: string;

        readonly ThreadId: number;

        readonly Subject: string;
        readonly Body: string;
    }

    interface DbPerson {
        readonly Id: number;
        readonly Email: string;
    }
    const dbPeople = await database.query<DbPerson>('SELECT Id, Email FROM people');
    const people: {[id: string]: number} = {};
    dbPeople.forEach(person => people[person.Email] = person.Id);

    emailMessagesPart1.writeRow([
        'Pipedrive_Id__c',
        'HtmlBody',
        'MessageDate',
        'RelatedToId',
        'Status',
        'Subject',
        'ThreadIdentifier',
        'CreatedDate', 'LastModifiedDate',
        'LastModifiedById',
    ]);
    emailMessagesPart2.writeRow(['Pipedrive_Id__c', 'Status']);

    emailMessageRelations.writeRow([
        'EmailMessage:Pipedrive_Id__c',
        'RelationId',
        'RelationType',
        'RelationAddress'
    ]);

    function addEmailMessageRelation(emailId: number, relationType: 'FromAddress' | 'ToAddress', sfId: string | undefined, email: string | undefined) {
        if (email?.endsWith('@pipedrivemail.com')) {
            return;
        }

        if (!email && !sfId) {
            return; // neither supplied, so not much we can do
        }

        emailMessageRelations.writeRow([
            emailId.toString(),
            sfId,
            relationType,
            sfId ? undefined : email
        ]);
    }

    const limit = 5000;
    let maximumId = -1;
    let emails: DbEmail[] = [];
    do {
        process.stdout.write(`fetching ${limit} emails from ID ${maximumId}...`);
        emails = await database.query<DbEmail>(`
            SELECT
                e.Id as Id,
                e.DealId as DealId,
                e.TimeAdded as TimeAdded,
                e.TimeUpdated as TimeUpdated,

                e.FromAddress as FromAddress,
                e.ToAddress as ToAddress,

                e.ThreadId as ThreadId,
                e.Subject as Subject,
                e.Body as Body
            FROM emails e
            WHERE id > ?
            ORDER BY e.Id
            LIMIT ?
        `, maximumId, limit);
        console.log('done');

        for (const email of emails) {
            maximumId = Math.max(email.Id, maximumId);

            const sfTimeAdded = new Date(email.TimeAdded).toISOString();
            const sfTimeModified = new Date(email.TimeUpdated).toISOString();

            let relatedId: string | undefined;
            const opp = oppIdToSfId[email.DealId];
            if (opp) {
                relatedId = opp;
                // try and work out who this was sent to
                const toEmails = email.ToAddress.split(',');

                for (const toEmail of toEmails) {
                    const relatedTo: string | undefined = personToSfId[people[toEmail]] || await users.getUserIdForEmail(toEmail);
                    addEmailMessageRelation(email.Id, 'ToAddress', relatedTo, toEmail);
                }
            } else {
                const toEmails = email.ToAddress.split(',');

                const lead = leadIdToSfId[email.DealId];

                if (lead) {
                    addEmailMessageRelation(email.Id, 'ToAddress', lead, undefined);
                } else {
                    for (const toEmail of toEmails) {
                        const relatedTo: string | undefined = personToSfId[people[toEmail]] || await users.getUserIdForEmail(toEmail);
                        addEmailMessageRelation(email.Id, 'ToAddress', relatedTo, toEmail);
                    }
                }      
            }

            const sender = await users.getUserIdForEmail(email.FromAddress ?? '');
            addEmailMessageRelation(email.Id, 'FromAddress', sender, email.FromAddress);

            emailMessagesPart1.writeRow([
                email.Id.toString(),
                emailBody(email.Body),
                sfTimeAdded,
                relatedId,
                '5', // draft
                email.Subject,
                email.ThreadId.toString(),
                sfTimeAdded, sfTimeModified,
                sender,
            ]);

            emailMessagesPart2.writeRow([
                email.Id.toString(),
                '3'
            ]);
        }
    } while (emails.length > 0);

    emailMessagesPart1.end();
    emailMessagesPart2.end();
    emailMessageRelations.end();
}

const maxEmailBodyLength = 32000;
function emailBody(body: string): string {
    if (body.length > maxEmailBodyLength) {
        const newBody = stripHtml(body, false);
        if (newBody.length > maxEmailBodyLength) {
            return newBody.substr(0, maxEmailBodyLength - 3) + '...';
        }
        
        return newBody;
    }

    return body;
}

function stripHtml(content: string, andNewLines: boolean): string {
    const tagAndNewLinesRegex = /(<[^>]+>|\n)/g;
    const tagRegex = /<[^>]+>/g;
    return content.replace(andNewLines ? tagAndNewLinesRegex : tagRegex, '');
}