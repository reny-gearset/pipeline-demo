import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getTeamMemberLoginStats from '@salesforce/apex/TeamRoutes.getTeamMemberLoginStats';

// Jan 11, 2019, 11:53 PM
const dateFormat = {
    'day': '2-digit',
    'month': 'short',
    'year': 'numeric',

    'hour': 'numeric',
    'minute': 'numeric',
    'hour12': 'true',
    'time-zone-name': 'short'
};

const columns = [
    { label: 'Name', fieldName: 'display_name', sortable: true },
    { label: 'Gearset User ID', fieldName: 'user_id', sortable: true },
    { label: 'Last logged in', fieldName: 'latest_login', sortable: true, type: 'date', typeAttributes: dateFormat },
    { label: 'Number of times logged in', fieldName: 'number_of_logins', sortable: true }
];

export default class TeamLoginDetailsComponent extends LightningElement {

    @api recordId
    @track teamId
    @api teamIdField
    errorMessage = '';
    columns = columns;
    data = [];

    sortedBy = 'latest_login';
    sortedDirection = 'asc';

    @wire(getRecord, { recordId: '$recordId', fields: '$teamIdField' })
    async recordLoaded({ error, data }) {
        if (error) {

            // TODO: lightning-datatable has an errors attribute, but I can't get it to do anything
            this.errorMessage = 'Failed to retrieve team login details';

        } else if (data) {

            this.teamId = getFieldValue(data, this.teamIdField);
        }
    }

    @wire(getTeamMemberLoginStats, { teamId: '$teamId' })
    loginStatsLoaded({ error, data }) {
        if (error) {

            // TODO: lightning-datatable has an errors attribute, but I can't get it to do anything
            this.errorMessage = 'Failed to retrieve team login details';

        } else if (data) {

            this.sort(data);
        }
    }

    sort(data) {
        const copyData = [...data];

        copyData.sort((row1, row2) => {

            // default the two values to something so that all the blanks appear together
            let value1 = row1[this.sortedBy] || '';
            let value2 = row2[this.sortedBy] || '';

            // compare strings ignoring case
            if (typeof value1 === 'string' && typeof value2 === 'string') {
                value1 = value1.toLocaleUpperCase();
                value2 = value2.toLocaleUpperCase();
            }

            if (value1 == value2) {
                return 0;
            }

            // if it's less and not descending, or it's greater and descending, then it comes before
            return (value1 < value2) ^ (this.sortedDirection == 'desc') ? -1 : 1;
        });

        this.data = copyData;
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;

        this.sort(this.data);
    }

}