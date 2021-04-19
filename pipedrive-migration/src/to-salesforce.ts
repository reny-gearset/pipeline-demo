import { IDatabase, newSqliteConnection, newPostgresConnection } from './Database';
import { exportAccounts } from './export/exportAccounts';
import { exportContacts } from './export/exportContacts';
import { exportLeads } from './export/exportLeads';
import { exportTasks } from './export/exportTasks';
import { exportOpportunities } from './export/exportOpportunities';
import { exportOpportunityLineItems } from './export/exportOpportunityLineItems';
import { exportNotes } from './export/exportNotes';
import { Users } from './export/UserMatching'
import { exportEmails } from './export/exportEmails';

(async () => {
    const databaseFilename = process.argv[3];
    let database: IDatabase;

    if (databaseFilename) {
        console.log(`Using sqlite database with file name ${databaseFilename}`);
        database = await newSqliteConnection(databaseFilename);
    } else {
        console.log(`Using postgres database hosted at ${process.env.PGHOST}`);
        database = await newPostgresConnection();
    }

    const users = new Users('users.csv');

    switch (process.argv[2]) {
        case 'accounts':
            await exportAccounts(database, users);
            break;
        case 'contacts':
            await exportContacts(database, users);
            break;
        case 'leads':
            await exportLeads(database, users);
            break;
        case 'tasks':
        case 'activities':
            await exportTasks(database, users);
            break;
        case 'opportunities':
            await exportOpportunities(database, users);
            await exportOpportunityLineItems(database);
            break;
        case 'notes':
            await exportNotes(database, users);
            break;
        case 'emails':
            await exportEmails(database, users);
            break;
        default:
            console.log(`Don't know how to export ${process.argv[2]}`);
            break;
    }
})().catch(err => {
    console.log(err);
    console.log(err.stack);
});