export interface Email {
    readonly id: number;
    readonly fromAddress: string | undefined;
    readonly toAddresses: string[];
    readonly ccList: string[];
    readonly bodyUrl: string;
    readonly userId: number;
    readonly threadId: number;
    readonly subject: string;
    readonly timeAdded: string;
    readonly timeUpdated: string;
}

export function fromPipedriveEmail(email: any): Email {
    interface PdEmail {
        readonly data: {
            readonly id: number;
            readonly from: {
                readonly email_address: string;
            }[] | undefined;
            readonly to: {
                readonly email_address: string;
                readonly name: string;
            }[] | undefined;
            readonly cc: {
                readonly email_address: string;
                readonly name: string;
            }[] | undefined;

            readonly body_url: string;
            readonly user_id: number;
            readonly mail_thread_id: number;
            readonly subject: string;

            readonly add_time: string;
            readonly update_time: string;
        }
    }

    const pdEmail = email as PdEmail;

    return {
        id: pdEmail.data.id,
        fromAddress: pdEmail.data.from?.map(email => email.email_address)[0],
        toAddresses: pdEmail.data.to?.map(email => email.email_address) || [],
        ccList: pdEmail.data.cc?.map(email => email.email_address) || [],

        bodyUrl: pdEmail.data.body_url,
        userId: pdEmail.data.user_id,
        threadId: pdEmail.data.mail_thread_id,
        subject: pdEmail.data.subject,

        timeAdded: pdEmail.data.add_time,
        timeUpdated: pdEmail.data.update_time,
    };
}