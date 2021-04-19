export interface Activity {
    id: number;
    orgId: number;
    dealId: number;
    personId: number;
    createdByUserId: number;
    assignedToUserId: number;
    subject: string;
    done: boolean;
    dueDate: string;
    dueTime: string;
    type: string;
}

export function fromPipedriveActivity(activity: any): Activity {
    interface PdActivity {
        id: number;
        org_id: number;
        deal_id: number;
        person_id: number;
        user_id: number;
        assigned_to_user_id: number;
        subject: string;
        done: boolean;
        due_date: string;
        due_time: string;
        type: string;
    }

    const pdActivity = activity as PdActivity;

    return {
        id: pdActivity.id,
        orgId: pdActivity.org_id,
        dealId: pdActivity.deal_id,
        personId: pdActivity.person_id,
        createdByUserId: pdActivity.user_id,
        assignedToUserId: pdActivity.assigned_to_user_id,
        subject: pdActivity.subject,
        done: pdActivity.done,
        dueDate: pdActivity.due_date,
        dueTime: pdActivity.due_time,
        type: pdActivity.type,
    };
}