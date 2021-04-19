import { CsvWriter } from '../Csv';
import { IDatabase } from '../Database';
import { getPdToSfMap } from './SalesforceUploadResultParser'
import { Users } from './UserMatching';

import * as fs from 'fs';
import * as path from 'path';

const maxUploadPerDay = 200_000;

export async function exportNotes(db: IDatabase, users: Users) {
    let notesCsv : CsvWriter | undefined;

    const leadIdToSfId = await getPdToSfMap('lead-upload.csv');
    const oppIdToSfId = await getPdToSfMap('opportunity-upload.csv');
    const orgIdToSfId = await getPdToSfMap('account-upload.csv');

    interface CsmDeal {
        OrgId: number;
        DealId: number;
    }

    interface DbNote {
        readonly Id: number;
        readonly DealId: number;
        readonly OwnerEmail: string;
        readonly Content: string;
        readonly TimeAdded: string;
        readonly TimeUpdated: string;
    }

    const csmDealsToOrgsMap: {[dealId: number]: number} = {};
    {
        const csmDealsToOrgs = await db.query<CsmDeal>(`
            SELECT d.Id as DealId, o.Id AS OrgId
            FROM (SELECT * FROM deals WHERE PipelineId = 25) d
                    LEFT JOIN people p ON p.Id = d.PersonId
                    LEFT JOIN organizations o
                            ON o.Id = d.OrganizationId OR o.id = p.OrganizationId OR o.Name = substr(d.Name, 8)
            WHERE o.Id IS NOT NULL
            GROUP BY d.Id
        `);

        csmDealsToOrgs.forEach(csmDeal => csmDealsToOrgsMap[csmDeal.DealId] = csmDeal.OrgId);
    }

    const notes = await db.query<DbNote>(`
        SELECT
            n.Id AS Id,
            n.DealId AS DealId,
            owner.Email AS OwnerEmail,
            n.Content AS Content,
            n.TimeAdded AS TimeAdded,
            n.TimeUpdated AS TimeUpdated
        FROM notes n
        JOIN users owner ON owner.Id = n.UserId
        WHERE
            n.DealId IS NOT NULL
        ORDER BY
            n.Id
    `);

    const totalNotes = notes.length;
    let currentPrintedNoteIndex = 0;
    let currentNoteIndex = 0;
    for (const note of notes) {
        currentPrintedNoteIndex++;

        if (currentPrintedNoteIndex % 10000 === 0) {
            console.log(`Exporting note ${currentPrintedNoteIndex} / ${totalNotes} (skipped ${currentPrintedNoteIndex - currentNoteIndex})`);
        }

        if (!isAnInterestingNote(note.Content)) {
            continue;
        }

        if (currentNoteIndex % maxUploadPerDay === 0) {
            console.log('Creating new content note file');
            notesCsv?.end();
            notesCsv = new CsvWriter(`ContentNotes-${currentNoteIndex}.csv`);
            notesCsv.writeRow(['Content', 'ReferenceId', 'OwnerId', 'Title', 'CreatedById', 'CreatedDate', 'LastModifiedDate', 'LastModifiedById', 'ShareType', 'Visibility']);
            currentNoteIndex++;
        }

        const orgIdForCsm = csmDealsToOrgsMap[note.DealId];

        const account = orgIdToSfId[orgIdForCsm];
        if (!account) {
            console.log(`Cannot find SF account with pipedrive ID ${orgIdForCsm}`);
            continue;
        }

        let relatedTo = account;
        if (!relatedTo) {
            const leadOrOpp = oppIdToSfId[note.DealId] || leadIdToSfId[note.DealId];
            if (!leadOrOpp) {
                // we get a surprising number of these
                //console.log(`Cannot find lead or opp for note ${note.Id}`);
                continue;
            }

            relatedTo = leadOrOpp;
        }

        currentNoteIndex++;

        const folderName = path.join('notes-export', ...Math.floor(note.Id / 1000).toString().padStart(10, '0').match(/.{1,3}/g)!);
        const filename = path.join(folderName, `${note.Id}.html`);
        
        await fs.promises.mkdir(folderName, { recursive: true });
        await fs.promises.writeFile(filename, stripHtml(note.Content, false));

        const contentLocation = path.join(process.cwd(), filename);

        const user = await users.getUserIdForEmail(note.OwnerEmail);

        const sfCreateTime = new Date(note.TimeAdded).toISOString();
        const sfUpdateTime = new Date(note.TimeUpdated).toISOString();

        let title = stripHtml(note.Content, true);
        title = title.length > 150 ? title.substring(0, 150) + '...' : title;

        notesCsv!.writeRow([
            contentLocation,
            relatedTo,
            user,
            title,
            user,
            sfCreateTime,
            sfUpdateTime,
            user,
            'I',
            'AllUsers',
        ]);
    }

    notesCsv!.end();
}

function isAnInterestingNote(noteContent: string): boolean {
    const intercomLoginRegex = /<a href="mailto:.*">.*<\/a> has just logged in \(Intercom Session Count: \d+\)/;
    const intercomConversationRegex = /^<strong><a href="https:\/\/app.intercom.(com|io)\/a\/apps\/h0kayiwv\/conversations\//;
    if (noteContent.match(intercomLoginRegex) || noteContent.match(intercomConversationRegex)) {
        return false;
    }

    return true;
}

function stripHtml(content: string, andNewLines: boolean): string {
    const tagAndNewLinesRegex = /(<[^>]+>|\n)/g;
    const tagRegex = /<[^>]+>/g;
    return content.replace(andNewLines ? tagAndNewLinesRegex : tagRegex, '');
}