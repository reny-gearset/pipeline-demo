export interface Note {
    id: number;
    dealId?: number;
    personId?: number;
    organizationId?: number;
    userId: number;

    pinnedToDeal: boolean;
    pinnedToPerson: boolean;
    pinnedToOrganization: boolean;

    content: string;
    timeAdded: string;
    timeUpdated: string;
}

export function fromPipedriveNote(note: any): Note {
    interface PDNote {
        id: number;
        deal_id?: number;
        person_id?: number;
        org_id?: number;
        user_id: number;

        pinned_to_deal_flag: boolean;
        pinned_to_person_flag: boolean;
        pinned_to_organization_flag: boolean;

        content: string;
        add_time: string;
        update_time: string;
    }

    const pdNote = note as PDNote;

    return {
        id: pdNote.id,
        dealId: pdNote.deal_id,
        personId: pdNote.person_id,
        organizationId: pdNote.org_id,
        userId: pdNote.user_id,

        pinnedToDeal: pdNote.pinned_to_deal_flag,
        pinnedToPerson: pdNote.pinned_to_person_flag,
        pinnedToOrganization: pdNote.pinned_to_organization_flag,

        content: pdNote.content,
        timeAdded: pdNote.add_time,
        timeUpdated: pdNote.update_time,
    };
}