@isTest
private class TestContactReopenHandler {
	@isTest
    public static void shouldNotInsertTasksIfNoOpportunitiesExistForContact() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id);
        insert c;
        
        ContactReopenHandler.handleExistingContactLogin(c, false);
        
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size());
    }
    
    @isTest
    public static void shouldInsertTaskIfOpportunityWithNotifyExistsForContact() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id);
        insert c;
        
        User u = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert u;
        
        Opportunity o = new Opportunity(
            Name = 'Gearset buys stuff',
            Notify_if_logs_in__c = true,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost', 
            AccountId = a.Id, 
            OwnerId = u.Id,
            CloseDate = System.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        ContactReopenHandler.handleExistingContactLogin(c, false);

        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId FROM Task];
        System.assertEquals(1, tasks.size());
        
        Task t = tasks.get(0);
        System.assertEquals(u.Id, t.OwnerId);
        System.assertEquals(c.Id, t.WhoId);
        System.assertEquals(o.Id, t.WhatId);
    }
    
    @isTest
    public static void shouldCreateATaskForEveryOpportunityWatchingThisContact() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id);
        insert c;
        
        User u = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert u;
        
        Opportunity o = new Opportunity(
            Name = 'Gearset buys stuff',
            Notify_if_logs_in__c = true,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost', 
            AccountId = a.Id, 
            OwnerId = u.Id,
            CloseDate = System.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        Opportunity o2 = new Opportunity(
            Name = 'Gearset buys more stuff',
            Notify_if_logs_in__c = true,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost', 
            AccountId = a.Id, 
            OwnerId = u.Id,
            CloseDate = System.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        insert o2;
        
        ContactReopenHandler.handleExistingContactLogin(c, false);

        List<Task> tasks = [SELECT Id, OwnerId, WhoId FROM Task];
        System.assertEquals(2, tasks.size());
        System.assertEquals(u.Id, tasks.get(0).OwnerId);
        System.assertEquals(c.Id, tasks.get(0).WhoId);
        System.assertEquals(u.Id, tasks.get(1).OwnerId);
        System.assertEquals(c.Id, tasks.get(1).WhoId);
    }
    
    @isTest
    public static void shouldNotCreateTaskIfNotAskedToNotify() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id);
        insert c;
        
        User u = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert u;
        
        Opportunity o = new Opportunity(
            Name = 'Gearset buys stuff',
            Notify_if_logs_in__c = false,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost', 
            AccountId = a.Id, 
            OwnerId = u.Id,
            LeadSource = 'Inbound',
            CloseDate = System.today(),
            Type = 'New'
        );
        insert o;
        
        ContactReopenHandler.handleExistingContactLogin(c, false);

        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId FROM Task];
        System.assertEquals(0, tasks.size());
    }
    
    @isTest
    public static void shouldStillCreateTaskIfItIsANewLogin() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id);
        insert c;
        
        User u = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert u;
        
        Opportunity o = new Opportunity(
            Name = 'Gearset buys stuff',
            Notify_if_logs_in__c = false,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost', 
            AccountId = a.Id, 
            OwnerId = u.Id,
            CloseDate = System.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        ContactReopenHandler.handleExistingContactLogin(c, true);

        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId FROM Task];
        System.assertEquals(1, tasks.size());
    }
}