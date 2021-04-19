import * as csvFormat from '@fast-csv/format';
import * as csvParse from '@fast-csv/parse';

import * as fs from 'fs';

function uniquifyHeaders(headers: string[]): string[] {
    const result: string[] = [];
    for (const header of headers) {
        if (result.includes(header)) {
            let proposedAddition = 1;
            let proposedNewHeader = '';
            do {
                proposedNewHeader = `${header}${proposedAddition++}`;
            } while (result.includes(proposedNewHeader));

            result.push(proposedNewHeader);
        } else {
            result.push(header);
        }
    }

    return result;
}

export async function readCsv<T>(filename: string, transform: (original: any) => T): Promise<T[]> {
    const result: T[] = [];

    let doneReadingCb: (() => void) | null = null;
    const doneReadingPromise = new Promise(resolve => { doneReadingCb = resolve });
    const csvReadStream = csvParse.parse<any, T>({
        headers: uniquifyHeaders
    })
        .transform(transform)
        .on('data', (row: T) => {
            result.push(row);
        })
        .on('end', () => doneReadingCb!());
    
    const fileReadStream = fs.createReadStream(filename);
    fileReadStream.pipe(csvReadStream);
    await doneReadingPromise;

    csvReadStream.end();
    return result;
}

export class CsvWriter {
    private readonly fileStream: fs.WriteStream
    private readonly csvStream: csvFormat.CsvFormatterStream<csvFormat.Row, csvFormat.Row>

    private numberOfColumns: number | null = null

    public constructor(filename: string) {
        this.fileStream = fs.createWriteStream(filename);
        this.csvStream = csvFormat.format();
        this.csvStream.pipe(this.fileStream);
    }

    public writeRow(row: (string | undefined | null)[]) {
        if (this.numberOfColumns === null) {
            this.numberOfColumns = row.length;
        } else if (this.numberOfColumns !== row.length) {
            throw new Error(`Row ${row} has ${row.length} columns but expect ${this.numberOfColumns} columns`);
        }

        this.csvStream.write(row);
    }

    public end() {
        this.csvStream.end();
    }
}