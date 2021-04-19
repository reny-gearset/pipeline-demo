import { fromPipedrivePerson } from "pipedrive/Person"

export interface User {
    name: string;
    email: string;
    id: number;
}

export function fromPipedriveUser(user: any): User {
    interface PdUser {
        id: number;
        name: string;
        email: string;
    }

    const pdUser = user as PdUser;

    return pdUser;
}