import { readCsv, CsvWriter } from '../Csv';
import { IDatabase } from '../Database';
import { getPdToSfMap } from './SalesforceUploadResultParser';
import { Users } from './UserMatching';

export async function exportTasks(db: IDatabase, users: Users) {
    const tasksCsv = new CsvWriter('Tasks.csv');

    const leadIdToSfId = await getPdToSfMap('lead-upload.csv');
    const oppIdToSfId = await getPdToSfMap('opportunity-upload.csv');
    const orgToSfId = await getPdToSfMap('account-upload.csv');
    const personToSfId = await getPdToSfMap('contact-upload.csv');

    interface DbActivity {
        Id: number;
        AssignedToEmail: string | undefined;
        CreatedByEmail: string | undefined;
        Subject: string;
        Done: boolean;
        DueDate: string;
        DueTime: string;
        DealId: number | undefined;
        PersonId: number;
        OrgId: number;
        Type: 'call' | 'task' | 'justcall_sms' | 'email' | 'deadline' | 'meeting' | 'intercom_conversation';
        Raw: string;
    }

    const activities = await db.query<DbActivity>(`
        SELECT
            activities.Id,
            activities.Subject,
            activities.Done,
            activities.DueDate,
            activities.DueTime,
            activities.Type,
            activities.DealId,
            activities.PersonId,
            activities.OrgId,
            createdBy.Email AS CreatedByEmail,
            assignee.Email AS AssignedToEmail,
            activities.Raw as Raw
        FROM activities
        LEFT JOIN users AS assignee ON activities.AssignedToUserId = assignee.Id
        LEFT JOIN users AS createdBy ON activities.CreatedByUserId = createdBy.Id
        LEFT JOIN deals ON deals.Id = activities.DealId
        ORDER BY activities.DealId, activities.PersonId, activities.OrgId
    `);

    tasksCsv.writeRow(['Pipedrive_Id__c', 'ActivityDate', 'Subject', 'Type', 'WhoId', 'Status', 'OwnerId', 'CreatedById', 'WhatId', 'Description']);

    const typeMapPdToSf = {
        'call': 'Call',
        'meeting': 'Meeting',
        'task': 'Other',
        'intercom_conversation': 'Intercom Chat',
        'email': 'Email',
        'justcall_sms': 'Other',
        'deadline': 'Other',
    };

    const activityRows = [];
    for (const activity of activities) {
        const parsedRaw = JSON.parse(activity.Raw);
        const comment = stripHtml(parsedRaw.note as string || '', false);

        if (activity.Subject.match(/^(Missed call from|Voicemail from |Outbound Call |Incoming Call from |New SMS from |SMS sent to )/) ||
            comment.match(/^(Read more at https:\/\/app\.intercom\.(io|com)\/a\/apps\/h0kayiwv\/conversations)/)) {
            // these are just call or intercom related activities, which we skip for the salesforce export
            continue;
        }

        let name = personToSfId[activity.PersonId];

        let relatedTo = oppIdToSfId[activity.DealId ?? -1];
        
        if (!relatedTo) {
            const lead = leadIdToSfId[activity.DealId ?? -1];
            name = lead;
        }

        if (!name) {
            relatedTo = orgToSfId[activity.OrgId];
        }

        const activityDate = `${activity.DueDate}T${activity.DueTime || '09:00'}:00Z`;
        const sfType = typeMapPdToSf[activity.Type];
        const status = activity.Done ? 'Completed' : 'Open';

        const assignedTo = await users.getUserIdForEmail(activity.AssignedToEmail!);
        const createdBy = activity.CreatedByEmail ? await users.getUserIdForEmail(activity.CreatedByEmail) : undefined;

        activityRows.push([activity.Id.toString(), activityDate, activity.Subject, sfType, name, status, assignedTo, createdBy, relatedTo, comment]);
    }

    activityRows.sort((a, b) => sortByIndex(a, b, 4, 6, 8)); // sort by WhoId, WhatId, OwnerId
    for (const activityRow of activityRows) {
        tasksCsv.writeRow(activityRow);
    }

    tasksCsv.end();
}

function findActivitySubject(ids: number[], searchMaps: {[pdId: number]: string}[]): string | undefined {
    for (let i = 0; i < ids.length; i++) {
        const result = searchMaps[i][ids[i]];
        if (result) {
            return result;
        }
    }
}

function stripHtml(content: string, andNewLines: boolean): string {
    const tagAndNewLinesRegex = /(<[^>]+>|\n)/g;
    const tagRegex = /<[^>]+>/g;
    return content.replace(andNewLines ? tagAndNewLinesRegex : tagRegex, '');
}

function sortByIndex(a: (string | undefined)[], b: (string | undefined)[], ...indices: number[]): number {
    for (const index of indices) {
        const aValue = a[index];
        const bValue = b[index];
        if (aValue && bValue) {
            return aValue.localeCompare(bValue)
        }
    }

    // which value is missing first?
    for (const index of indices) {
        const aValue = a[index];
        const bValue = b[index];

        if (aValue && !bValue) {
            return -1;
        } else if (bValue) {
            return 1;
        }
    }

    return 0;
}