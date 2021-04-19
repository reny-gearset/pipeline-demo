import { readCsv } from '../Csv';

export async function getPdToSfMap(filename: string): Promise<{[pdId: number]: string}> {
    interface SFUploadResult { ID: string; PIPEDRIVE_ID__C: string; }

    const data = await readCsv<SFUploadResult>(filename, x => x);

    const resultMap: {[pdId: number]: string} = {};
    data.forEach(row => resultMap[parseInt(row.PIPEDRIVE_ID__C, 10)] = row.ID);
    return resultMap;
}