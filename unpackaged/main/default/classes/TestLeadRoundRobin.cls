@isTest
private class TestLeadRoundRobin {  
    private static User sdr1;
    
    @testSetup
    public static void createUsers() {
        List<User> kevins = [SELECT Id FROM User WHERE Email = 'kevin@gearset.com'];
        if (kevins.size() == 0) {
            insert TestUtils.createStandardUser('Boyle', 'kevin@gearset.com');
        }        
        Group sdrGroup = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];
        UserRole sdr = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Development_Representative' LIMIT 1];
        
        sdr1 = TestUtils.createStandardUser('SDR', 'sales@example.com');
        sdr1.UserRoleId = sdr.Id;
        insert sdr1;
    }
    
	@isTest
    public static void shouldNotChangeTheLeadOwnerIfItIsntTheSDRLeadDistributionQueue() {
        User owner = [SELECT Id FROM User LIMIT 1];
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', OwnerId = owner.Id, LeadSource = 'Inbound');
        insert l;

        System.assertEquals(owner.Id, l.OwnerId);
    }

    @isTest
    public static void shouldReassignLeadIfAssignedToSdrQueue() {
        Group sdrGroup = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];

        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', OwnerId = sdrGroup.Id, LeadSource = 'Inbound');
        insert l;

        Lead modifiedLead = [SELECT OwnerId FROM Lead WHERE LastName = 'Kuiper' LIMIT 1];

		// Can't test to make sure it is equal to the above because it seems that Salesforce
		// doesn't give you a clean slate of users, groups or roles before your tests run...
        System.assertNotEquals(sdrGroup.Id, modifiedLead.OwnerId);
    }

    @isTest
    public static void shouldAssignSalesforceDomainsToKevin() {
        Group sdrGroup = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];

        Lead l = new Lead(LastName = 'Test', Company = 'Salesforce', OwnerId = sdrGroup.Id, Email = 'iwork@salesforce.com', LeadSource = 'Inbound');
        insert l;
        
        Lead modifiedLead = [SELECT OwnerId FROM Lead WHERE LastName = 'Test' LIMIT 1];
        User kevin = [SELECT Id FROM User WHERE Email = 'kevin@gearset.com'];
        System.assertEquals(kevin.Id, modifiedLead.OwnerId);
    }
}