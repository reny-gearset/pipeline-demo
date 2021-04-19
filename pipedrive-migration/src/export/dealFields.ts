const timezones = [
    {
        "label": "PST",
        "id": 39
    },
    {
        "label": "MST",
        "id": 40
    },
    {
        "label": "CST",
        "id": 41
    },
    {
        "label": "EST",
        "id": 42
    },
    {
        "label": "Brazil Standard Time",
        "id": 58
    },
    {
        "label": "GMT",
        "id": 43
    },
    {
        "label": "CEST",
        "id": 44
    },
    {
        "label": "GST",
        "id": 63
    },
    {
        "label": "IST",
        "id": 45
    },
    {
        "label": "Far East",
        "id": 47
    },
    {
        "label": "AEST",
        "id": 46
    },
    {
        "label": "AWST",
        "id": 100
    },
    {
        "label": "Moscow ST",
        "id": 101
    }
];

const leadSources = [
    {
        "label": "Calendly",
        salesforce: 'Inbound',
        "id": 67
    },
    {
        "label": "AppExchange",
        salesforce: 'Salesforce',
        "id": 1
    },
    {
        "label": "Dreamforce",
        salesforce: 'Event',
        "id": 4
    },
    {
        "label": "Dreamforce17",
        salesforce: 'Event',
        "id": 33
    },
    {
        "label": "Dreamforce18-DevZone",
        salesforce: 'Event',
        "id": 56
    },
    {
        "label": "Dreamforce18-MainExpo",
        salesforce: 'Event',
        "id": 57
    },
    {
        "label": "Dreamforce19-DevZone",
        salesforce: 'Event',
        "id": 102
    },
    {
        "label": "Dreamforce19-DevZone-Talks",
        salesforce: 'Event',
        "id": 103
    },
    {
        "label": "Forcelandia-19",
        salesforce: 'Event',
        "id": 99
    },
    {
        "label": "InboundEmail",
        salesforce: 'Email',
        "id": 65
    },
    {
        "label": "Londons-Calling-2019",
        salesforce: 'Event',
        "id": 68
    },
    {
        "label": "Londons-Calling-2020",
        salesforce: 'Event',
        "id": 124
    },
    {
        "label": "Meetup",
        salesforce: 'Event',
        "id": 24
    },
    {
        "label": "Midwest-dreamin-19",
        salesforce: 'Event',
        "id": 98
    },
    {
        "label": "Organic",
        salesforce: 'Trialist',
        "id": 3
    },
    {
        "label": "Outbound Prospecting",
        salesforce: 'Outbound',
        "id": 96
    },
    {
        "label": "Partner",
        salesforce: 'Partner',
        "id": 2
    },
    {
        "label": "PhillyForce19",
        salesforce: 'Event',
        "id": 91
    },
    {
        "label": "SalesProspecting",
        salesforce: 'Prospecting into base',
        "id": 66
    },
    {
        "label": "South-East-Dreaming-2019",
        salesforce: 'Event',
        "id": 73
    },
    {
        "label": "TDX18",
        salesforce: 'Event',
        "id": 36
    },
    {
        "label": "TDX19",
        salesforce: 'Event',
        "id": 97
    },
    {
        "label": "WorldTour-Boston-19",
        salesforce: 'Event',
        "id": 79
    },
    {
        "label": "WorldTour-NewYork-18",
        salesforce: 'Event',
        "id": 64
    },
    {
        "label": "Event-2019-WT-NYC",
        salesforce: 'Event',
        "id": 104
    },
    {
        "label": "Organic - Accepting Invite",
        salesforce: 'Joining team',
        "id": 131
    },
    {
        "label": "Backup-webinar",
        salesforce: 'Event',
        "id": 146
    },
    {
        "label": "Git for Admins NYC",
        salesforce: 'Event',
        "id": 147
    },
    {
        "label": "Website",
        salesforce: 'Inbound',
        "id": 158
    },
    {
        "label": "usergroup-follow-up",
        salesforce: 'Inbound',
        "id": 159
    },
    {
        "label": "Tweets",
        salesforce: 'Inbound',
        "id": 160
    },
    {
        "label": "Regular linkedin posts",
        salesforce: 'Inbound',
        "id": 161
    },
    {
        "label": "Linkedin",
        salesforce: 'Inbound',
        "id": 162
    },
    {
        "label": "Emails",
        salesforce: 'Inbound',
        "id": 163
    },
    {
        "label": "Email to larger webinar + email groups",
        salesforce: 'Event',
        "id": 164
    },
    {
        "label": "Discord",
        salesforce: 'Inbound',
        "id": 165
    }
];

export function getTimeZone(pdId: number): string {
    const timezoneObj = timezones.find(timezone => timezone.id === pdId);
    if (!timezoneObj) {
        throw new Error(`Bad timezone ID: ${pdId}`);
    }

    return timezoneObj.label;
}

export function getSource(pdId: number): string {
    const sourceObj = leadSources.find(s => s.id === pdId);
    if (!sourceObj) {
        throw new Error(`Bad source ID: ${pdId}`);
    }

    return sourceObj.salesforce;
}