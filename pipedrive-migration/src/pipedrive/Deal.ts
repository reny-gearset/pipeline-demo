export interface Deal {
    readonly id: number;
    readonly name: string;
    readonly value: number;
    readonly status: string;
    readonly personId?: number;
    readonly organizationId?: number;

    readonly createdAt: string;
    readonly updatedAt: string;

    readonly stageId: number;
    readonly pipelineId: number;
    readonly lostReason?: string;
    readonly ownerId?: number | undefined;

    readonly apContactId?: number;
    readonly dealQuality?: string;
    readonly estimatedNumberOfUsers?: number;
    readonly timezone?: string;
}

export function fromPipedriveDeal(deal: any): Deal {
    interface PDDeal {
        id: number;
        title: string;
        weighted_value: number;
        status: string;
        person_id?: {value: number};
        org_id?: {value: number};
        user_id: {id: number};

        stage_id: number;
        pipeline_id: number;
        lost_reason?: string;
        owner_name?: string;

        add_time: string;
        update_time: string;

        "2a5a6930743b4f5c156ec16cc9f7af6ff3eba733"?: {value: number}; // ap contact
        "30bd39dcbfebd46f214f0f6ac05fdafa6731a4a4"?: string; // deal quality
        "8d59c81fd7ec1a08532d015f4a3f09407dbf2fc6"?: number; // number of users
        "03a2c89777d3f5510fbc1345190582293546b2b0"?: string; // timezone
    }

    const pdDeal = deal as PDDeal;

    return {
        id: pdDeal.id,
        name: pdDeal.title,
        value: pdDeal.weighted_value,
        status: pdDeal.status,
        personId: pdDeal.person_id?.value,
        organizationId: pdDeal.org_id?.value,

        stageId: pdDeal.stage_id,
        pipelineId: pdDeal.pipeline_id,
        lostReason: pdDeal.lost_reason,
        ownerId: pdDeal.user_id?.id,

        createdAt: pdDeal.add_time,
        updatedAt: pdDeal.update_time,

        apContactId: pdDeal['2a5a6930743b4f5c156ec16cc9f7af6ff3eba733']?.value,
        timezone: pdDeal['03a2c89777d3f5510fbc1345190582293546b2b0'],
    };
}
