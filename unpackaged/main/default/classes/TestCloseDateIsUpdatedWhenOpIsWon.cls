@isTest
private class TestCloseDateIsUpdatedWhenOpIsWon {
    @isTest
    public static void shouldSetOpportunityCloseDateToTodayIfWon() {
        Gearset_Team__c t = new Gearset_Team__c(
            Gearset_Team_Id__c = '1234'
        );
        upsert t;

        Account a = new Account(
            Name = 'Test Account'
        );
        a.Gearset_Team__c = t.Id;
        insert a;

        Opportunity o = new Opportunity(
            Name = 'Test opportunity',
            CloseDate = Date.today().addDays(3),
            StageName = 'Invoice Issued',
            Type = 'New',
            LeadSource = 'Inbound',
            AccountId = a.Id
        );
        insert o;

        o.Payment__c = '20B3ECBC-1DA5-4A52-8848-961368E502F5';      
        o.StageName = 'Closed Won';
        update o;
        
        Opportunity updatedOp = [SELECT CloseDate FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(Date.today(), updatedOp.CloseDate);
    }
    
    @isTest
    public static void shouldSetOpportunityCloseDateToTodayIfLost() {
        Opportunity o = new Opportunity(
            Name = 'Test opportunity',
            CloseDate = Date.today().addDays(3),
            StageName = 'Invoice Issued',
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        o.Loss_Reason__c = 'Competitor';
        o.StageName = 'Closed Lost';
        update o;
        
        Opportunity updatedOp = [SELECT CloseDate FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(Date.today(), updatedOp.CloseDate);
    }
    
    @isTest
    public static void shouldNotSetOpportunityCloseDateIfNotMarkedAsWonOrLost() {
        Date closeDate = Date.today().addDays(3);
        Opportunity o = new Opportunity(
            Name = 'Test opportunity',
            CloseDate = closeDate,
            StageName = 'Approaching Renewal',
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        o.StageName = 'Invoice Issued';
        update o;
        
        Opportunity updatedOp = [SELECT CloseDate FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(closeDate, updatedOp.CloseDate);
    }
}