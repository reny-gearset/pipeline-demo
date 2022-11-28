import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getUserOrgs from '@salesforce/apex/SdrRoutes.getUserOrgs';

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
    { label: 'Org ID', fieldName: 'orgid' },
    { label: 'Org type', fieldName: 'orgtype' },
    { label: 'User name', fieldName: 'username' },
    { label: 'First authorized', fieldName: 'first_authorized', type: 'date', typeAttributes: dateFormat }
];

export default class UserOrgsComponent extends LightningElement {

    @api recordId
    @track userEmail
    @api userEmailField
    errorMessage = '';
    columns = columns;
    data = [];

    sortedBy = 'first_authorized';
    sortedDirection = 'desc';

    @wire(getRecord, { recordId: '$recordId', fields: '$userEmailField' })
    async recordLoaded({ error, data }) {
        if (error) {

            // TODO: lightning-datatable has an errors attribute, but I can't get it to do anything
            this.errorMessage = 'Failed to retrieve record';

        } else if (data) {

            this.userEmail = getFieldValue(data, this.userEmailField);
        }
    }

    @wire(getUserOrgs, { userEmail: '$userEmail' })
    userOrgsLoaded({ error, data }) {
        if (error) {

            // TODO: lightning-datatable has an errors attribute, but I can't get it to do anything
            this.errorMessage = 'Failed to retrieve user org connection details';

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
}