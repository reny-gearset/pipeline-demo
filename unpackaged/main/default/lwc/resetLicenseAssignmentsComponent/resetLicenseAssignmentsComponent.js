import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import resetLicenseAssignments from '@salesforce/apex/TeamRoutes.resetLicenseAssignments';

import GEARSET_TEAM_ID_FIELD from "@salesforce/schema/Gearset_Team__c.Gearset_Team_Id__c";

export default class ResetLicenseAssignmentsComponent extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: "$recordId", fields: [GEARSET_TEAM_ID_FIELD] })
    team;

    async handleResetAssignmentsClick() {
        let toastEvent;
        
        try {
            const teamId = getFieldValue(this.team.data, GEARSET_TEAM_ID_FIELD);
            await resetLicenseAssignments({ teamId });

            toastEvent = new ShowToastEvent({
                title: 'License assignments reset!',
                message: "The team's assignments for this month have been reset. Note: the assignments table will still include these in the stats, but they'll no longer count towards the team's assignment limit",
                variant: 'success',
            });
        } catch (err) {
            toastEvent = new ShowToastEvent({
                title: 'Failed to reset license assignments',
                message: err.body?.message,
                variant: 'error',
            });
        }
        
        this.dispatchEvent(toastEvent); 
    }
}