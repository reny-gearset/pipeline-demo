@isTest
private class TestStoreCalculatedTeamRevenue {
    private static final Logger LOGGER = LogFactory.create(TestStoreCalculatedTeamRevenue.class);

	@isTest
    public static void shouldAddMrrToAccounts() {
        Gearset_Team__c t = new Gearset_Team__c(
            Gearset_Team_Id__c = '2e8f8261-128f-4e75-8f64-4fde01b47cb5'
        );
        upsert t;

        LOGGER.info('Inserted test Gearset_team__c {0}', t);

        Account a = new Account(
        	Name = 'My Account',
            Gearset_Team__c = t.Id
        );
        
        insert a;
        
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(new Revenue_Calculated__e(
            Team_Id__c = '2e8f8261-128f-4e75-8f64-4fde01b47cb5',
            Revenue_MRR__c = 300.00
        ));
        Test.stopTest();
        
        System.assert(sr.isSuccess());
        
        Account fetched = [SELECT MRR__c FROM Account WHERE Id = :a.Id];
        
        System.assertEquals(300.00, fetched.MRR__c);
    }
    
    @isTest
    public static void shouldUpdateAsManyAccountsAsItCan() {
        Gearset_Team__c t = new Gearset_Team__c(
            Gearset_Team_Id__c = '2e8f8261-128f-4e75-8f64-4fde01b47cb5'
        );
        upsert t;

        LOGGER.info('Inserted test Gearset_team__c ', t);

        Account a = new Account(
        	Name = 'My Account',
            Gearset_Team__c = t.Id
        );
        
        insert a;
        
        Test.startTest();
        List<Revenue_Calculated__e> events = new List<Revenue_Calculated__e>();
        events.add(new Revenue_Calculated__e(
            Team_Id__c = '2e8f8261-128f-4e75-8f64-4fde01b47cb5',
            Revenue_MRR__c = 300.00
        ));
        events.add(new Revenue_Calculated__e(
            Team_Id__c = '1',
            Revenue_MRR__c = 450.00
        ));
        
        List<Database.SaveResult> srs = EventBus.publish(events);
        Test.stopTest();
        
        for (Database.SaveResult sr : srs) {
            System.assert(sr.isSuccess());
        }
        
        Account fetched = [SELECT MRR__c FROM Account WHERE Id = :a.Id];
        
        System.assertEquals(300.00, fetched.MRR__c);
    }
}