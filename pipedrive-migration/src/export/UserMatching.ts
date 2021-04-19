import { readCsv } from '../Csv';
import * as fs from 'fs';

export class Users {
    private readonly filename: string;
    private usernameToSfId: {[username: string]: string} | undefined;
    private readonly warnedUsers: {[username: string]: void} = {};

    constructor(filename: string) {
        this.filename = filename;
    }

    async getUserIdForEmail(email: string): Promise<string | undefined> {
        if (!email.endsWith('@gearset.com')) {
            return;
        }

        const users = await this.getUsers();

        const lowerEmail = email.toLowerCase();
        const user = Object.entries(users)
            .find(([username, _]) => 
                username.toLowerCase().startsWith(lowerEmail))?.[1];
        
        if (!user && !this.warnedUsers.hasOwnProperty(email)) {
            console.log(`Failed to match an SF user with ${email}`);
            this.warnedUsers[email] = undefined;
        }

        return user;
    }

    private async getUsers() {
        if (this.usernameToSfId) {
            return this.usernameToSfId;
        }

        interface SfUsernameResult { Username: string; Id: string }

        if (!fs.existsSync(this.filename)) {
            throw new Error(`
Please ensure that users information csv from the target instance exist.

You can generate this by using salesforce workbench running the data query:
SELECT Email, Username, Id from User

and saving the resulting csv file to ${this.filename}
`)
        }
        const data = await readCsv<SfUsernameResult>(this.filename, x => x);

        this.usernameToSfId = {};
        for (const user of data) {
            this.usernameToSfId[user.Username] = user.Id;
        }

        return this.usernameToSfId;
    }
}