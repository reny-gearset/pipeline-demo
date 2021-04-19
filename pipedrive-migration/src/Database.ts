import { open, Database } from 'sqlite';
import * as sqlite3 from 'sqlite3';

import { Pool } from 'pg';

export interface IDatabase {
    exec(query: string): Promise<void>
    run(query: string, ...params: any[]): Promise<void>
    query<T>(query: string, ...params: any[]): Promise<T[]>
}

class SqliteDatabase implements IDatabase {
    private readonly db: Database;

    constructor(db: Database) {
        this.db = db;
    }

    public async exec(query: string): Promise<void> {
        try {
            await this.db.exec(query);
        } catch (err) {
            console.error(`Failed to run query ${query}`);
            throw new Error(err);
        }
    }

    public async run(query: string, ...params: any[]): Promise<void> {
        try {
            await this.db.run(query, ...params);
        } catch (err) {
            console.error(`Failed to run query ${query}`);
            throw new Error(err);
        }
    }

    public async query<T>(query: string, ...params: any[]): Promise<T[]> {
        try {
            return await this.db.all(query, ...params);
        } catch (err) {
            console.error(`Failed to run query ${query}`);
            throw new Error(err);
        }
    }
}

class PgDatabase implements IDatabase {
    private readonly pool: Pool;

    constructor(pool: Pool) {
        this.pool = pool;
    }

    public async exec(query: string): Promise<void> {
        await this.pool.query(query, []);
    }

    public async run(query: string, ...params: any[]): Promise<void> {
        await this.pool.query(this.toPgQuery(query), params);
    }

    public async query<T>(query: string, ...params: any[]): Promise<T[]> {
        const result = await this.pool.query(this.toPgQuery(query), params);
        return result.rows;
    }

    private toPgQuery(query: string) {
        let index = 1;
        return query.replace(/\?/g, () => `$${index++}`); // replace all ?'s with incrementing $n's
    }
}

// uses the standard PG* environment variables for server information
export async function newPostgresConnection(): Promise<IDatabase> {
    return new PgDatabase(new Pool());
}

export async function newSqliteConnection(connString: string): Promise<IDatabase> {
    return new SqliteDatabase(await open({
        filename: connString,
        driver: sqlite3.Database
    }));
}