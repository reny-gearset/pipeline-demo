import { CsvWriter } from '../Csv';
import { IDatabase } from '../Database';
import { pdAddressToSfAddress } from './AddressConversion';
import { PersonLike, sanitisePerson } from './PersonLike';
import * as pipelines from './Pipelines';
import { Users } from './UserMatching';
import * as dealFields from './dealFields';

const unqualifiedPipelineId = pipelines.fromPipelinePdName('Unqualified')!;
const eventsPipelineId = pipelines.fromPipelinePdName('Events')!;

const sfLostReasons = [
    'Price',
    'No Response',
    'Competitor',
    'No valid use case',
    'Legal / procurement blocked',
    'Errors',
    'Features missing',
    'Trial solved need so no purchase',
    'Free tier',
    'Churn',
    'Not ready yet',
    'Coronavirus',
    'Region with low propensity to purchase'
];
const sfLostReasonsMap: { [lowerCase: string]: string; } = {};
sfLostReasons.forEach(reason => sfLostReasonsMap[reason.toLowerCase()] = reason);
sfLostReasonsMap['churn (update churn spreadsheet)'] = 'Churn';
function lostReasonFromPd(lostReason: string) {
    const sfReason = sfLostReasonsMap[lostReason.toLowerCase()];
    return sfReason ?? 'Other...';
}
export async function exportLeads(database: IDatabase, users: Users) {
    interface DbDeal {
        Id: number;
        Name: string;
        Status: string;
        OrgName: string | undefined;
        StageId: number;
        IntercomUrl: string | undefined;
        LostReason: string | undefined;
        Website: string | undefined;
        FirstName: string | undefined;
        LastName: string | undefined;
        Phone: string | undefined;
        Email: string | undefined;
        CreatedAt: string;
        UpdatedAt: string;
        OwnerEmail: string | undefined;
        PersonRawData: string;
        OrgRawData: string;
        QualifiedByEmail: string | undefined;
        PipelineId: number;
        PersonId: number | undefined;
        OrganizationId: number | undefined;
        Timezone: string | undefined;
        Source: string | undefined;
    };

    const deals = await database.query<DbDeal>(`
        SELECT
            deals.Id as Id,
            deals.Name as Name,
            deals.Status as Status,
            organizations.Name as OrgName,
            organizations.Website as Website,
            people.FirstName as FirstName,
            people.LastName as LastName,
            people.Email as Email,
            people.Phone as Phone,
            people.IntercomUrl as IntercomUrl,
            deals.StageId as StageId,
            deals.PipelineId,
            deals.LostReason as LostReason,
            deals.CreatedAt as CreatedAt,
            deals.UpdatedAt as UpdatedAt,
            json_extract(deals.Raw, '$.03a2c89777d3f5510fbc1345190582293546b2b0') AS Timezone,
            json_extract(deals.Raw, '$.60bd8aeaecb0c00699612adf78c52ec41f282c94') AS Source,
            owner.Email as OwnerEmail,
            people.Raw AS PersonRawData,
            organizations.Raw AS OrgRawData,
            qualified_by.Email As QualifiedByEmail,
            people.Id AS PersonId,
            organizations.Id AS OrganizationId
        FROM deals
        LEFT JOIN organizations ON deals.OrganizationId = organizations.Id
        LEFT JOIN people ON deals.PersonId = people.Id
        LEFT JOIN users owner ON deals.OwnerId = owner.Id
        LEFT JOIN users qualified_by
                   ON qualified_by.Id = json_extract(deals.Raw, '$.a9527277c7b0a87201ea6a3deaa29ddb21ab3f34.id')
        GROUP BY
            deals.Id
    `);

    const pdIdToSf = {
        [pipelines.fromStagePdName('Untriaged', unqualifiedPipelineId)]: 'New',
        [pipelines.fromStagePdName('Triaged', unqualifiedPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Customer replied', unqualifiedPipelineId)]: 'Customer Replied',
        [pipelines.fromStagePdName('Discovery Call', unqualifiedPipelineId)]: 'Discovery Call',
        [pipelines.fromStagePdName('Meeting Booked', unqualifiedPipelineId)]: 'Demo Booked',

        [pipelines.fromStagePdName('Scanned', eventsPipelineId)]: 'New',
        [pipelines.fromStagePdName('Triaged', eventsPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Contact1', eventsPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Contact2', eventsPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Contact3', eventsPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Contact4', eventsPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Contact5', eventsPipelineId)]: 'Researched',
        [pipelines.fromStagePdName('Replied', eventsPipelineId)]: 'Customer Replied',
        [pipelines.fromStagePdName('Interested', eventsPipelineId)]: 'Discovery Call',
    };

    const leadsCsvFile = new CsvWriter('Leads.csv');
    leadsCsvFile.writeRow(['Pipedrive_Id__c', 'FirstName', 'LastName', 'Email', 'Intercom_Url__c', 'Phone', 'Company', 'Website', 'Status', 'Lost_Reason__c', 'Lost_Reason_Notes__c', 'Reopen_if_logs_in__c', 'CreatedDate', 'LastModifiedDate', 'OwnerId', 'Street', 'City', 'State', 'Country', 'PostalCode', 'ConvertedAccount:Pipedrive_Id__c', 'ConvertedContact:Pipedrive_Id__c', 'ConvertedOpportunity:Pipedrive_Id__c', 'IsConverted', 'LeadSource', 'Timezone__c']);

    for (const deal of deals) {
        let person: PersonLike | undefined;
        try {
            person = sanitisePerson(deal);
        } catch (e) {
            const err = e as Error;
            console.log(`Failed to convert deal ${deal.Id} to a person: ${err.message}`);
            continue;
        }

        // For deals which are not unqualified, we should lose them as opportunities and not as
        // leads
        const isConverted = ((deal.PipelineId != unqualifiedPipelineId) && (deal.PipelineId !== eventsPipelineId)) || deal.Status === 'won';

        const isLost = isConverted ? false : deal.Status === 'lost';
        const status = isConverted ? 'Demo Booked' : (isLost ? 'Lost' : pdIdToSf[deal.StageId]);

        const shouldReopen = isLost && deal.LostReason === 'Low probability. Reopen if user signs in';
        const lostReason = isLost ? lostReasonFromPd(deal.LostReason ?? '') : null;
        
        const company = deal.OrgName ?? (status === 'New' ? `DON'T KNOW` : 'Unknown');
        const website = deal.Website?.trim();

        const createdAt = new Date(deal.CreatedAt).toISOString();
        const updatedAt = new Date(deal.UpdatedAt).toISOString();

        const ownerId = isConverted ?
            (deal.QualifiedByEmail ? await users.getUserIdForEmail(deal.QualifiedByEmail) : undefined) :
            (deal.OwnerEmail ? await users.getUserIdForEmail(deal.OwnerEmail) : undefined);

        const personRawData = JSON.parse(deal.PersonRawData);
        const personAddress = deal.PersonRawData ? {
            Street: [personRawData['988b24ed35a7f849561ead80c3311dcadfbf6f25'], personRawData['f40f68f687d1ccee700da270c6bd38dfdb766520']].filter(x => x).join('\n') || undefined,
            City: personRawData['9a8ff2fb4c535b16a264231f57eb84a4d899c01e'],
            State: personRawData['2b037ede0196b0c15c5b9d969daa3df305c98b86'],
            Country: personRawData['83beed14c86687fcc0cee831cc2d9ab2d4d2bb1f'],
            PostalCode: personRawData['fcd21140dd058f06a5d06edcb572a0c87aaff4d9'],
        } : undefined;

        const orgAddress = deal.OrgRawData ? pdAddressToSfAddress(JSON.parse(deal.OrgRawData)) : undefined;

        const source = deal.Source ? dealFields.getSource(+deal.Source) : undefined;
        const timezone = deal.Timezone ? dealFields.getTimeZone(+(deal.Timezone.split(',')[0])) : undefined;

        leadsCsvFile.writeRow([
            deal.Id.toString(),
            person.FirstName,
            person.LastName,
            person.Email,
            person.IntercomUrl,
            person.Phone,
            company,
            website,
            status,
            lostReason,
            deal.LostReason,
            shouldReopen.toString(),
            createdAt,
            updatedAt,
            ownerId,
            personAddress?.Street || orgAddress?.Street,
            personAddress?.City || orgAddress?.City,
            personAddress?.State || orgAddress?.State,
            personAddress?.Country || orgAddress?.Country,
            personAddress?.PostalCode || orgAddress?.PostalCode,
            isConverted ? deal.OrganizationId?.toString() : undefined,
            isConverted ? deal.PersonId?.toString() : undefined,
            isConverted ? deal.Id.toString() : undefined,
            isConverted,
            source,
            timezone,
        ]);
    }

    console.log('Please copy the success file from uploading Leads.csv to lead-upload.csv before exporting tasks next');
    leadsCsvFile.end();
}
