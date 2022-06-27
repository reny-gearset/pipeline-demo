@isTest
private class TestBillingCycleMustBeSetWhenOpIsWon {
    @isTest
    public static void billingCycleMustBeSetWhenOpIsWon() {
        User u = TestUtils.createStandardUser('Last', 'my@email.com');

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        insert u;
        Account a = new Account(
            Name = 'My account',
            OwnerId = u.Id,
            Churn_risk__c = 'Churn Risk - Attempting Contact',
            Gearset_Team__c = t.Id
        );
        insert a;
        
        Opportunity o = new Opportunity(
            Name = 'My account op',
            StageName = 'Closed Won',
            OwnerId = u.Id,
            AccountId = a.Id,
            CloseDate = Date.today(),
            LeadSource = 'Direct',
            Type = 'New',
            Payment__c = 'GEA210215-1892-66159',
            Expected__c = 'Unknown',
            Amount = 300
        );
        insert o;
        
        Opportunity newOpp = [SELECT Expected__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Unknown', newOpp.Expected__c);
    }
    
    @isTest
    public static void throwsWhenBillingCycleIsNotSetWhenOpIsWon() {
        User u = TestUtils.createStandardUser('Last', 'my@email.com');

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        insert u;
        Account a = new Account(
            Name = 'My account',
            OwnerId = u.Id,
            Churn_risk__c = 'Churn Risk - Attempting Contact',
            Gearset_Team__c = t.Id
        );
        insert a;
        
        Opportunity o = new Opportunity(
            Name = 'My account op',
            StageName = 'Closed Won',
            OwnerId = u.Id,
            AccountId = a.Id,
            CloseDate = Date.today(),
            LeadSource = 'Direct',
            Type = 'New',
            Payment__c = 'GEA210215-1892-66159',
            Amount = 300
        );
        
        String errorMessage = '';
        try{
            insert o;
        }
        catch(Exception e){
            errorMessage = e.getMessage();
        }
        System.Assert(errorMessage.contains('The opportunity cannot enter Closed Won stage without a Billing Cycle field populated with a value'));
    }
}