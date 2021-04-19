export interface Person {
    readonly id: number;
    readonly organizationId: number | undefined;
    readonly firstName: string;
    readonly lastName: string;
    readonly name: string; // seems redundant, but is used to link up people with deals
    readonly phone: string;
    readonly email: string;
    readonly intercomUrl: string;
    readonly linkedinUrl: string;
    readonly updatedAt: string;
    readonly createdAt: string;
    readonly ownerId: number | undefined;
}

export function fromPipedrivePerson(person: any): Person {
    interface PDPerson {
        id: number;
        company_id: number;
        name: string;
        first_name: string;
        last_name: string;
        phone: {value: string, primary: boolean}[];
        email: {value: string, primary: boolean}[];
        org_id?: {value: number};
        "82743f165194c4e17c12070abbfe83af38e5faf1": string; // intercom url
        "d0a3c88aa615a181c2ddd8381dfdc849aaf418bc": string; // linkedin url
        add_time: string;
        update_time: string;
        owner_id: { id: number } | undefined;
    }

    const pdPerson = person as PDPerson;

    return {
        id: pdPerson.id,
        organizationId: pdPerson.org_id?.value,
        firstName: pdPerson.first_name,
        lastName: pdPerson.last_name,
        name: pdPerson.name,
        phone: pdPerson.phone[0].value,
        email: pdPerson.email[0].value,
        intercomUrl: pdPerson["82743f165194c4e17c12070abbfe83af38e5faf1"],
        linkedinUrl: pdPerson["d0a3c88aa615a181c2ddd8381dfdc849aaf418bc"],
        updatedAt: pdPerson.update_time,
        createdAt: pdPerson.add_time,
        ownerId: pdPerson.owner_id?.id,
    };
}