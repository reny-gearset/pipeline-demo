trigger OpportunityTrigger on Opportunity(before update) {
    for (Opportunity opp : Trigger.new) {
        String oldStageName = Trigger.oldMap.get(opp.Id).StageName;

        // skip if stage name hasn't changed or new stage is neither 'Invoice issued' nor 'Closed Won' 
        if (oldStageName == opp.StageName || !(opp.StageName == 'Invoice issued' || opp.StageName == 'Closed Won')) {
            continue;
        }

        PaymentTeamAssignmentService.onOpportunityReachInvoiceStageOrBeyond(opp);
    }
}
