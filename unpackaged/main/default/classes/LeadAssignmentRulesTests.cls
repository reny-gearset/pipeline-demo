@isTest
private class LeadAssignmentRulesTests {
    @testSetup
    public static void createTestUsers() {
        List<User> maritina = [SELECT Id FROM User WHERE Email = 'maritina.tsembelis@gearset.com'];
        if (maritina.size() == 0) {
            insert TestUtils.createStandardUser('Tsembeli', 'maritina.tsembelis@gearset.com');
        }
        
        List<User> frank = [SELECT Id FROM User WHERE Email = 'frank@gearset.com'];
        if (frank.size() == 0) {
            insert TestUtils.createStandardUser('Short', 'frank@gearset.com');
        }
    }
    
  	@isTest
    public static void shouldAssignGearsetComDomainsToNextInLine() {
        Lead l = new Lead(LastName = 'Test', Email = 'test@example.com');
        System.assertEquals(null, LeadAssignmentRules.getRepForLead(l.Email));
    }
    
    @isTest
    public static void shouldHandleLeadsWithoutAnEmail() {
        Lead l = new Lead(LastName = 'Test', Email = null);
        System.assertEquals(null, LeadAssignmentRules.getRepForLead(l.Email));
    }
    
    @isTest
    public static void shouldGiveAllSalesforceLeadsToMaritina() {
        Lead l = new Lead(LastName = 'Salesforce', Email = 'iwork@salesforce.com');
        User maritina = [SELECT Id FROM User WHERE Email = 'maritina.tsembelis@gearset.com'];
        System.assertEquals(maritina.Id, LeadAssignmentRules.getRepForLead(l.Email).Id);
    }
    
    @isTest
    public static void shouldGiveAllAmazonLeadsToFrank() {
        Lead l = new Lead(LastName = 'Salesforce', Email = 'iwork@amazon.com');
        User frank = [SELECT Id FROM User WHERE Email = 'frank@gearset.com'];
        System.assertEquals(frank.Id, LeadAssignmentRules.getRepForLead(l.Email).Id);
    }    
}