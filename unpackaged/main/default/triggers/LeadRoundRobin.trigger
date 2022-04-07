trigger LeadRoundRobin on Lead (after insert, after update) {
	List<Group> sdrLeadTrackers = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];
    if (sdrLeadTrackers.size() != 1) {
        System.debug(LoggingLevel.ERROR, 'Cannot find SDR Lead Distribution Queue');
        return;
    }
    
  	Id sdrLeadTrackerId = sdrLeadTrackers.get(0).Id;
    
    List<Lead> updatedLeads = new List<Lead>();
    
    List<User> sdrs = [SELECT Id, Name FROM User WHERE UserRole.DeveloperName = 'Sales_Development_Representative' ORDER BY Email];
    if (sdrs.size() == 0) {
        return;
    }
    
    for (Lead l : Trigger.new) {
        if (l.OwnerId != sdrLeadTrackerId) {
            continue;
        }
        
        Integer leadId = Integer.valueOf(l.Lead_Id__c.substring(5));
        
        User potentialNewOwner = LeadAssignmentRules.getRepForLead(l.Email);
        
        Id newOwnerId;
        if (potentialNewOwner == null) {
            newOwnerId = sdrs.get(math.mod(leadId, sdrs.size())).Id;
        } else {
            newOwnerId = potentialNewOwner.Id;
        }
        
        updatedLeads.add(new Lead(
        	Id = l.Id,
            OwnerId = newOwnerId
        ));
    }
    
    update updatedLeads;
}