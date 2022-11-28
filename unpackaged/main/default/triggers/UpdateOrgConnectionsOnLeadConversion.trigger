trigger UpdateOrgConnectionsOnLeadConversion on Lead (after update) {
	// no bulk processessing, only run when updated in the UI
    if (Trigger.new.size() != 1) {
        return;
    }
    
    // only do this as the lead is being converted
    Lead newLead = Trigger.new[0];
    if (Trigger.old[0].isConverted || !newLead.isConverted) {
        return;
    }
    
    Id convertedContactId = newLead.ConvertedContactId;
    
    List<Org_Connection__c> orgConnections = [SELECT Id FROM Org_Connection__c WHERE Lead__c = :newLead.Id];
    for (Org_Connection__c o : orgConnections) {
        o.Contact__c = convertedContactId;
    }
    
    update orgConnections;
}