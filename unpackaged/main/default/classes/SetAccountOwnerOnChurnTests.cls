@isTest
private class SetAccountOwnerOnChurnTests {
	@isTest public static void triggerShouldSetChurnAccountOwner() {
		User testUser = TestUtils.createStandardUser('Testman', 'test@test.com');
        insert testUser;
        
        Account a = new Account(OwnerId = testUser.Id, Name = 'Test Account Ltd');
        insert a;
        SubscriptionChurnEvent__c churn = new SubscriptionChurnEvent__c(Account__c = a.Id, Notes__c = 'Note', Date_of_churn__c = Date.newInstance(2021, 05, 20), MRR_loss__c = 1500.00, Type__c = 'Cancelled');
        insert churn;
        
        Test.startTest();
        
        List<SubscriptionChurnEvent__c> churnEvents = [SELECT Id, Notes__c, Account_Owner__c FROM SubscriptionChurnEvent__c];

        Test.stopTest();
        
        System.assertEquals(1, churnEvents.size()); 
        System.assertEquals(churn.Id, churnEvents.get(0).Id, 'Churn Id was not set correctly');
        System.assertEquals(testUser.Id, churnEvents.get(0).Account_Owner__c, 'Account owner was not set correctly');
    }
    
    @isTest public static void triggerShouldSetChurnAccountOwnerWithMultipleInserts() {
		User testUser = TestUtils.createStandardUser('Testman', 'test@test.com');
        insert testUser;
        
        List<Account> accountsToInsert = new List<Account> {
            new Account(OwnerId = testUser.Id, Name = 'Test Account Ltd'),
            new Account(OwnerId = testUser.Id, Name = 'A test account Inc.'),
            new Account(OwnerId = testUser.Id, Name = 'Test services')
        };
        insert accountsToInsert;
        List<SubscriptionChurnEvent__c> churnEventsToInsert = new List<SubscriptionChurnEvent__c> {
            new SubscriptionChurnEvent__c(Account__c = accountsToInsert.get(0).Id, Notes__c = 'Note', Date_of_churn__c = Date.newInstance(2021, 05, 20), MRR_loss__c = 1500.00, Type__c = 'Cancelled'),
            new SubscriptionChurnEvent__c(Account__c = accountsToInsert.get(1).Id, Notes__c = 'Note 2', Date_of_churn__c = Date.newInstance(2021, 04, 20), MRR_loss__c = 1000.00, Type__c = 'Cancelled'),
            new SubscriptionChurnEvent__c(Account__c = accountsToInsert.get(2).Id, Notes__c = 'Note 3', Date_of_churn__c = Date.newInstance(2021, 03, 20), MRR_loss__c = 1200.00, Type__c = 'Cancelled')
        };
        insert churnEventsToInsert;

        Test.startTest();
        
        List<SubscriptionChurnEvent__c> churnEvents = [SELECT Id, Notes__c, Account_Owner__c FROM SubscriptionChurnEvent__c];

        Test.stopTest();
        
        System.assertEquals(3, churnEvents.size());
        for(Integer i = 0; i < churnEvents.size(); i++) {
            System.assertEquals(churnEventsToInsert.get(i).Id, churnEvents.get(i).Id, 'Churn Id was not set correctly');
        	System.assertEquals(testUser.Id, churnEvents.get(i).Account_Owner__c, 'Account owner was not set correctly');
        }
    }
}