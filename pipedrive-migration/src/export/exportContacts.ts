import { CsvWriter } from '../Csv';
import { IDatabase } from '../Database';
import { PersonLike, sanitisePerson } from './PersonLike';
import * as pipelines from './Pipelines';
import { Users } from './UserMatching';
import * as dealFields from './dealFields';

const unqualifiedPipelineId = pipelines.fromPipelinePdName('Unqualified')!;
const eventsPipelineId = pipelines.fromPipelinePdName('Events')!;

export async function exportContacts(database: IDatabase, users: Users) {
    interface PeopleDbResult { 
        Id: number; 
        OrgId: number | undefined;
        FirstName: string; 
        LastName: string; 
        Email: string; 
        Phone: string; 
        IntercomUrl: string | undefined; 
        LinkedInUrl: string;
        CreatedAt: string;
        UpdatedAt: string;
        OwnerEmail: string;
        Raw: string;
        Timezone: string | undefined;
    }

    await database.exec('CREATE INDEX IF NOT EXISTS deals_person_idx ON deals (PersonId)');

    const people = await database.query<PeopleDbResult>(`
        SELECT p.Id              AS Id,
            p.OrganizationId     AS OrgId,
            p.FirstName          AS FirstName,
            p.LastName           AS LastName,
            p.Email              AS Email,
            p.Phone              AS Phone,
            p.IntercomUrl        AS IntercomUrl,
            p.LinkedInUrl        AS LinkedInUrl,
            p.UpdatedAt          AS UpdatedAt,
            p.CreatedAt          AS CreatedAt,
            json_extract(d.Raw, '$.03a2c89777d3f5510fbc1345190582293546b2b0') AS Timezone,
            owner.Email          AS OwnerEmail,
            p.Raw                AS Raw
        FROM people p
        JOIN users owner ON p.OwnerId = owner.Id
        LEFT JOIN deals d ON d.PersonId = p.Id
        WHERE NOT EXISTS(
            SELECT 1
            FROM deals
            WHERE deals.PersonId = p.Id
            AND ((deals.PipelineId = ? OR deals.PipelineId = ?) AND deals.Status <> 'won'))
        GROUP BY p.Id
        ORDER BY p.OrganizationId -- order by to prevent too many lock failure from SF
    `, unqualifiedPipelineId, eventsPipelineId);

    const csvWriter = new CsvWriter('Contacts.csv');
    const errorWriter = new CsvWriter('Contacts-errors.csv');

    errorWriter.writeRow(['PipedriveId', 'Reason', 'First name', 'Last name', 'Email', 'Company', 'pd link']);

    csvWriter.writeRow(['Pipedrive_Id__c', 'FirstName', 'LastName', 'Email', 'Phone', 'Intercom_Url__c', 'Account:Pipedrive_Id__c', 'CreatedDate', 'LastModifiedDate', 'OwnerId', 'MailingStreet', 'MailingCity', 'MailingState', 'MailingCountry', 'MailingPostalCode', 'Timezone__c']);
    for (const person of people) {
        let accountId = '';
        if (person.OrgId) {
            accountId = person.OrgId.toString() || '';
        }

        let sanitised: PersonLike | undefined = undefined;
        try {
            sanitised = sanitisePerson(person);
        } catch (e) {
            const err = e as Error;
            errorWriter.writeRow([person.Id.toString(), err.message, person.FirstName, person.LastName, person.Email, person.OrgId?.toString(), `https://gearset.pipedrive.com/person/${person.Id}`]);
            continue;
        }

        const rawData = JSON.parse(person.Raw);
        const address = {
            Street: [rawData['988b24ed35a7f849561ead80c3311dcadfbf6f25'], rawData['f40f68f687d1ccee700da270c6bd38dfdb766520']].filter(x => x).join('\n') || undefined,
            City: rawData['9a8ff2fb4c535b16a264231f57eb84a4d899c01e'],
            State: rawData['2b037ede0196b0c15c5b9d969daa3df305c98b86'],
            Country: rawData['83beed14c86687fcc0cee831cc2d9ab2d4d2bb1f'],
            PostalCode: rawData['fcd21140dd058f06a5d06edcb572a0c87aaff4d9'],
        };

        const createdAt = new Date(person.CreatedAt).toISOString();
        const updatedAt = new Date(person.UpdatedAt).toISOString();
        const ownerId = person.OwnerEmail ? await users.getUserIdForEmail(person.OwnerEmail) : undefined;

        const timezone = person.Timezone ? dealFields.getTimeZone(parseInt(person.Timezone, 10)) : undefined;

        csvWriter.writeRow([
            person.Id.toString(), 
            sanitised.FirstName, 
            sanitised.LastName, 
            sanitised.Email, 
            sanitised.Phone, 
            sanitised.IntercomUrl, 
            accountId, 
            createdAt, 
            updatedAt, 
            ownerId,
            address.Street,
            address.City,
            address.State,
            address.Country,
            address.PostalCode,
            timezone,
        ]);
    }

    errorWriter.end();
    csvWriter.end();

    console.log('Upload Contacts.csv to Salesforce using the data loader and copy the success file to contacts-upload.csv before continuing with opportunities');
}
