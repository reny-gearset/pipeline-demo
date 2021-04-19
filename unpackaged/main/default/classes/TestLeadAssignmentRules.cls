@isTest
private class TestLeadAssignmentRules {
    @testSetup
    public static void createKevinUser() {
        List<User> kevins = [SELECT Id FROM User WHERE Email = 'kevin@gearset.com'];
        if (kevins.size() == 0) {
            insert TestUtils.createStandardUser('Boyle', 'kevin@gearset.com');
        }
    }
    
	@isTest
    public static void shouldAssignGearsetComDomainsToNextInLine() {
        Lead l = new Lead(LastName = 'Test', Email = 'test@gearset.com');
        System.assertEquals(null, LeadAssignmentRules.getRepForLead(l.Email));
    }
    
    @isTest
    public static void shouldHandleLeadsWithoutAnEmail() {
        Lead l = new Lead(LastName = 'Test', Email = null);
        System.assertEquals(null, LeadAssignmentRules.getRepForLead(l.Email));
    }
    
    @isTest
    public static void shouldGiveAllSalesforceLeadsToKevin() {
        Lead l = new Lead(LastName = 'Salesforce', Email = 'iwork@salesforce.com');
        User kevin = [SELECT Id FROM User WHERE Email = 'kevin@gearset.com'];
        System.assertEquals(kevin.Id, LeadAssignmentRules.getRepForLead(l.Email).Id);
    }
}