trigger EnsureOpportunityTypeIsFilledDuringLeadConversion on Lead (after update) {
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
    String newOpportunityType;
    
	// Map Lead Status to appropriate Opportunity Type
	switch on l.Status {
        when 'Demo Booked', 
            'Existing Account', 
            'No Demo - Provided Enough Info' {
            newOpportunityType = 'New';
        }
        when 'Qualified as Expansion Opportunity' {
            newOpportunityType = 'Expansion';
        }
    }
    
	// Only update if have mapped to a type
    if (newOpportunityType == null) {
        return;
    }
    
    List<Opportunity> opps = [SELECT Id from Opportunity WHERE Id = :opportunityId AND Type = null];
    
    // Skip if Type has been defined
    if (opps.isEmpty()) {
        return;
    }
    
    opps[0].Type = newOpportunityType;
    update opps[0];
}