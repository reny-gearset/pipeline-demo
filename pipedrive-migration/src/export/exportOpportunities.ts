import { CsvWriter } from '../Csv';
import { IDatabase } from '../Database';
import * as pipelines from './Pipelines';
import { Users } from './UserMatching';
import * as dealFields from './dealFields';

const qualifiedPipelineId = pipelines.fromPipelinePdName('Qualified Pipeline')!;
const expansionsPipelineId = pipelines.fromPipelinePdName('Expansions')!;
const accountManagementPipelineId = pipelines.fromPipelinePdName('Account Management')!;
const backupPipelineId = pipelines.fromPipelinePdName('Backup')!;
const renewalsPipelineId = pipelines.fromPipelinePdName('Renewals')!;

const unqualifiedPipelineId = pipelines.fromPipelinePdName('Unqualified')!;
const eventsPipelineId = pipelines.fromPipelinePdName('Events')!;

const allOpportunityPipelines = [
    qualifiedPipelineId,
    expansionsPipelineId,
    accountManagementPipelineId,
    backupPipelineId,
    renewalsPipelineId,
];

const allLeadPipelines = [
    unqualifiedPipelineId,
    eventsPipelineId,
];

const sfLostReasons = [
    'Lost to Competitor',
    'Price',
    'No Budget / Lost Funding',
    'No Decision / Non-Responsive',
    'No valid use case',
    'Legal / procurement blocked',
    'Errors',
    'Features missing',
    'Trial solved need so no purchase',
    'Free tier',
    'Churn (UPDATE CHURN SPREADSHEET)',
    'Low probability. Reopen if user signs in',
    'Not ready yet',
    'Coronavirus',
    'Region with low propensity to purchase',
    'Other',
];
const sfLostReasonsMap: { [lowerCase: string]: string } = {};
sfLostReasons.forEach(reason => sfLostReasonsMap[reason.toLowerCase()] = reason);
function lostReasonFromPd(lostReason: string) {
    const sfReason = sfLostReasonsMap[lostReason];
    return sfReason ?? 'Other';
}

const opportunityType: { [pipelineId: number]: string } = {
    [qualifiedPipelineId]: 'New',
    [expansionsPipelineId]: 'Expansion',
    [accountManagementPipelineId]: 'Expansion',
    [backupPipelineId]: 'Expansion',
    [renewalsPipelineId]: 'Renewal',
};

const newOppRecordTypeId = '0124K000000pyVZQAY';
const renewalOppRecordTypeId = '0124K000000pyVaQAI';

export async function exportOpportunities(database: IDatabase, users: Users) {
    interface OpportunityDbResult {
        readonly Id: number;
        readonly Name: string;
        readonly PersonId: number;
        readonly OrganizationId: number;
        readonly Status: 'won' | 'lost' | 'open';
        readonly StageId: number;
        readonly CreatedAt: string;
        readonly UpdatedAt: string;
        readonly OwnerEmail: string;
        readonly LostReason: string;
        readonly PipelineId: number;
        readonly Source: string | undefined;
        readonly ProductCount: number;
        readonly Value: number | undefined;

        readonly Raw: string;
    }

    const opportunities = await database.query<OpportunityDbResult>(`
        SELECT
            d.Id as Id,
            d.Name as Name,
            d.PersonId as PersonId,
            d.OrganizationId as OrganizationId,
            d.Status as Status,
            d.StageId as StageId,
            owner.Email as OwnerEmail,
            d.CreatedAt as CreatedAt,
            d.UpdatedAt as UpdatedAt,
            d.LostReason as LostReason,
            d.Raw as Raw,
            json_extract(d.Raw, '$.60bd8aeaecb0c00699612adf78c52ec41f282c94') AS Source,
            d.PipelineId as PipelineId,
            json_extract(d.Raw, '$.products_count') AS ProductCount,
            d.Value AS Value
        FROM deals d
        JOIN users owner ON d.OwnerId = owner.Id
    `);

    const csvWriter = new CsvWriter('Opportunities.csv');
    const contactRoleWriter = new CsvWriter('OpportunityContactRoles.csv');
    const errorWriter = new CsvWriter('Opportunities-errors.csv');

    csvWriter.writeRow(['Pipedrive_Id__c', 'Name', 'Account:Pipedrive_Id__c', 'StageName', 'OwnerId', 'CreatedDate', 'LastModifiedDate', 'CloseDate', 'Loss_Reason__c', 'CreatedById', 'Pricebook2Id', 'RecordTypeId', 'LeadSource', 'Amount', 'Type']);
    contactRoleWriter.writeRow(['Contact:Pipedrive_Id__c', 'Opportunity:Pipedrive_Id__c', 'IsPrimary'])
    errorWriter.writeRow(['Pipedrive_Id__c', 'Reason']);

    const pdStageIdToSf = {
        // qualified pipeline
        [pipelines.fromStagePdName('Discovery', qualifiedPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Solution Validating', qualifiedPipelineId)]: 'Solution Validating',
        [pipelines.fromStagePdName('Negotiations and Approvals', qualifiedPipelineId)]: 'Negotiations and Approvals',
        [pipelines.fromStagePdName('Procurement', qualifiedPipelineId)]: 'Procurement',
        [pipelines.fromStagePdName('Invoice Issued', qualifiedPipelineId)]: 'Invoice Issued',

        // expansions pipeline
        [pipelines.fromStagePdName('Opportunity Identified', expansionsPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Champion Contacted', expansionsPipelineId)]: 'Solution Validating',
        [pipelines.fromStagePdName('Opportunity Confirmed', expansionsPipelineId)]: 'Solution Validating',
        [pipelines.fromStagePdName('Licensing Negotiation', expansionsPipelineId)]: 'Negotiations and Approvals',
        [pipelines.fromStagePdName('Quote Sent', expansionsPipelineId)]: 'Procurement',
        [pipelines.fromStagePdName('Invoice Out', expansionsPipelineId)]: 'Invoice Issued',

        // Account management pipeline
        [pipelines.fromStagePdName('Prospecting', accountManagementPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Discovery', accountManagementPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Solution Validating', accountManagementPipelineId)]: 'Solution Validating',
        [pipelines.fromStagePdName('Negotiations and Approvals', accountManagementPipelineId)]: 'Negotiations and Approvals',
        [pipelines.fromStagePdName('Procurement', accountManagementPipelineId)]: 'Procurement',
        [pipelines.fromStagePdName('Invoice Issued', accountManagementPipelineId)]: 'Invoice Issued',

        // Backup pipeline
        [pipelines.fromStagePdName('Lead In', backupPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Discover call arranged', backupPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Discovery call completed', backupPipelineId)]: 'Discovery',
        [pipelines.fromStagePdName('Solution Validating', backupPipelineId)]: 'Solution Validating',
        [pipelines.fromStagePdName('Negotiations Started', backupPipelineId)]: 'Negotiations and Approvals',

        // renewals pipeline
        [pipelines.fromStagePdName('Approaching renewal', renewalsPipelineId)]: 'Approaching Renewal',
        [pipelines.fromStagePdName('Contacted for renewal opportunity', renewalsPipelineId)]: 'Contacted for Renewal Opportunity',
        [pipelines.fromStagePdName('Licensing negotiation', renewalsPipelineId)]: 'Licensing Negotiation',
        [pipelines.fromStagePdName('Invoice issued', renewalsPipelineId)]: 'Invoice Issued',
    };
    const wonStageName = 'Closed Won';
    const lostStageName = 'Closed Lost';

    for (const opportunity of opportunities) {
        if (!allOpportunityPipelines.includes(opportunity.PipelineId)) {
            if (opportunity.Status === 'won' && allLeadPipelines.includes(opportunity.PipelineId)) {
                // this should've been an opportunity, but was marked as won while it was a lead, so we should
                // continue working with it
            } else {
                continue; // should be a lead or maybe an account status
            }
        }

        if (!opportunity.PersonId || !opportunity.OrganizationId) {
            errorWriter.writeRow([opportunity.Id.toString(), 'Missing account or contact']);
            continue;
        }

        let stageName: string;
        let lossReason: string | undefined;
        if (opportunity.Status === 'won') {
            stageName = wonStageName;
        } else if (opportunity.Status === 'lost') {
            stageName = lostStageName;
            lossReason = lostReasonFromPd(opportunity.LostReason);
        } else {
            stageName = pdStageIdToSf[opportunity.StageId];
        }

        const ownerId = opportunity.OwnerEmail ? await users.getUserIdForEmail(opportunity.OwnerEmail) : undefined;
        const createdAt = new Date(opportunity.CreatedAt).toISOString();
        const updatedAt = new Date(opportunity.UpdatedAt).toISOString();

        const parsedRaw = JSON.parse(opportunity.Raw);

        let expectedCloseDate = parsedRaw.expected_close_date;
        if (opportunity.Status !== 'open') {
            expectedCloseDate = parsedRaw.close_time;
        }

        if (!expectedCloseDate) {
            if (opportunity.Status !== 'open') {
                if (parsedRaw.close_time) {
                    expectedCloseDate = new Date(parsedRaw.close_time).toISOString();
                } else {
                    expectedCloseDate = updatedAt;
                }
            } else {
                errorWriter.writeRow([opportunity.Id.toString(), 'Missing close date']);
                // TODO(GK): We shouldn't have any of these
                // continue;
                // make something up for now
                const now = new Date();
                expectedCloseDate = new Date(now.getFullYear(), (now.getMonth() + 1) % 12, 1).toISOString();
            }
        }
        const expectedCloseDateSfFormat = new Date(expectedCloseDate).toISOString();

        const createdById = await users.getUserIdForEmail(parsedRaw.creator_user_id.email);
        const recordTypeId = opportunity.PipelineId === renewalsPipelineId ? renewalOppRecordTypeId : newOppRecordTypeId;

        const source = opportunity.Source ? dealFields.getSource(parseInt(opportunity.Source, 10)) : undefined;

        const amount = opportunity.ProductCount ? undefined : opportunity.Value?.toString();
        const type = opportunityType[opportunity.PipelineId];

        csvWriter.writeRow([
            opportunity.Id.toString(),
            opportunity.Name,
            opportunity.OrganizationId?.toString(),
            stageName,
            ownerId,
            createdAt,
            updatedAt,
            expectedCloseDateSfFormat,
            lossReason,
            createdById,
            '01s4K000002AlblQAC',
            recordTypeId,
            source,
            amount,
            type,
        ]);

        if (opportunity.PersonId) {
            contactRoleWriter.writeRow([
                opportunity.PersonId.toString(),
                opportunity.Id.toString(),
                true.toString(),
            ]);
        }
    }

    errorWriter.end();
    csvWriter.end();
    contactRoleWriter.end();

    console.log('Upload Opportunities.csv to salesforce using the data loader, followed by OpportunityContactRoles.csv and copy the opportunities success file to opportunities-upload.csv before continuing with leads');
}
