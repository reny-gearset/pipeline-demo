trigger AddStakeholderSummaryToOpportunityDuringLeadConversion on Lead (after update) {
	// no bulk processessing, only run when updated in the UI
    if (Trigger.new.size() != 1) {
        return;
    }
    
    // only do this as the lead is being converted
    if (Trigger.old[0].isConverted || !Trigger.new[0].isConverted) {
        return;
    }
    
    Id opportunityId = Trigger.new[0].ConvertedOpportunityId;
    
    // Only run if an opportunity was actually created
    if (opportunityId == null) {
        return;
    }
    
    Opportunity opp = [SELECT Id from Opportunity WHERE Id = :opportunityId];
    
    String resultingStakeholderSummary = LeadUtilities.stakeholderSummary(Trigger.new[0]);
    opp.Stakeholder_Summary__c = resultingStakeholderSummary;
    
    update opp;
}