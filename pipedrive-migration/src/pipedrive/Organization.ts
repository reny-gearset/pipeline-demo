export interface Organization {
    readonly id: number;
    readonly name: string;
    readonly address: string;
    readonly website: string;
    readonly createdAt: string;
    readonly updatedAt: string;
    readonly ownerId: number | undefined;
}

export function fromPipedriveOrganization(org: any): Organization {
    interface PDOrganization {
        id: number;
        name: string;
        "0897a1ba0ac014fee6826ebc15b324084a13cd53": string; // website lol
        address_formatted_address: string;
        update_time: string;
        add_time: string;
        owner_id: {id: number} | undefined;
    }

    const pdOrg = org as PDOrganization;

    return {
        id: pdOrg.id,
        name: pdOrg.name,
        address: pdOrg.address_formatted_address,
        website: pdOrg["0897a1ba0ac014fee6826ebc15b324084a13cd53"],
        createdAt: pdOrg.add_time,
        updatedAt: pdOrg.update_time,
        ownerId: pdOrg.owner_id?.id,
    };
}