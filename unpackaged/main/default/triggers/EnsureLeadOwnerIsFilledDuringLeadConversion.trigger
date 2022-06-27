trigger EnsureLeadOwnerIsFilledDuringLeadConversion on Lead (after update) {
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
    
    Lead l = Trigger.new[0];
    Id leadOwnerId = l.OwnerId;

    
    List<Opportunity> opps = [SELECT Id from Opportunity WHERE Id = :opportunityId AND LeadOwner__c = null];
    
    // Skip if Lead Owner has been defined
    if (opps.isEmpty()) {
        return;
    }
    
    opps[0].LeadOwner__c = leadOwnerId;
    update opps[0];
}