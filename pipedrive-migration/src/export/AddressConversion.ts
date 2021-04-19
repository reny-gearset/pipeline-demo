interface PdAddress {
    address_street_number: string | null;
    address_route: string | null;
    address_sublocality: string | null;
    address_locality: string | null;
    address_admin_area_level_1: string | null;
    address_admin_area_level_2: string | null;
    address_country: string | null;
    address_postal_code: string | null;
}

interface SfAddress {
    Street: string | undefined;
    City: string | undefined;
    State: string | undefined;
    Country: string | undefined;
    PostalCode: string | undefined;
}

export function pdAddressToSfAddress(pdAddress: PdAddress): SfAddress {    
    const street = [pdAddress.address_street_number, pdAddress.address_route].filter(x => x).join(' ') || undefined;
    return {
        Street: street,
        City: pdAddress.address_locality || undefined,
        State: pdAddress.address_admin_area_level_1 || undefined,
        Country: pdAddress.address_country || undefined,
        PostalCode: pdAddress.address_postal_code || undefined,
    }
}
