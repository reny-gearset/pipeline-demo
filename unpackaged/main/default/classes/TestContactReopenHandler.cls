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
    public static void shouldCreateATaskForOnlyTheLatestOpportunityWatchingThisContact() {
        User accountOwner = TestUtils.createStandardUser('Accounts', 'account@gearset.com');
        insert accountOwner;

        User oppOwner = TestUtils.createStandardUser('Opps', 'opp@gearset.com');
        insert oppOwner;

        Account account = new Account(Name = 'Gearset', OwnerId = accountOwner.Id);
        insert account;

        Contact contact = new Contact(LastName = 'Kuiper', AccountId = account.Id);
        insert contact;

        Opportunity latestOpportunity = new Opportunity(
            Name = 'Gearset buys stuff',
            Notify_if_logs_in__c = true,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost',
            AccountId = account.Id,
            OwnerId = oppOwner.Id,
            CloseDate = System.today(),
            LeadSource = 'Direct',
            Type = 'New'
        );
        Opportunity olderOpportunity = new Opportunity(
            Name = 'Gearset buys more stuff',
            Notify_if_logs_in__c = true,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost',
            AccountId = account.Id,
            OwnerId = oppOwner.Id,
            CloseDate = System.today().addDays(-1),
            LeadSource = 'Direct',
            Type = 'New'
        );
        insert latestOpportunity;
        insert olderOpportunity;

        ContactReopenHandler.handleExistingContactLogin(contact, false);

        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId, Description FROM Task];
        System.assertEquals(1, tasks.size());
        System.assertEquals(accountOwner.Id, tasks.get(0).OwnerId);
        System.assertEquals(contact.Id, tasks.get(0).WhoId);
        System.assertEquals(account.Id, tasks.get(0).WhatId);
        System.assert(tasks.get(0).Description.contains(latestOpportunity.Name));
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
            LeadSource = 'Direct',
            CloseDate = System.today(),
            Type = 'New'
        );
        insert o;

        ContactReopenHandler.handleExistingContactLogin(c, false);

        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId FROM Task];
        System.assertEquals(0, tasks.size());
    }

    @isTest
    public static void shouldCreateTaskForAccountIfItIsANewLogin() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id);
        insert c;

        User u = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert u;

        ContactReopenHandler.handleExistingContactLogin(c, true);

        List<Account> accounts = [SELECT Id, OwnerId FROM Account];
        List<Account> contacts = [SELECT Id, OwnerId FROM Account];
        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId FROM Task];

        System.assertEquals(1, tasks.size());
        System.assertEquals(a.Id, tasks[0].WhatId);
        System.assertEquals(c.Id, tasks[0].WhoId);
        System.assertEquals(accounts[0].OwnerId, tasks[0].OwnerId);
    }

    @isTest
    public static void shouldCreateTaskForContactIfItThereIsNoAccount() {
        User contactOwner = TestUtils.createStandardUser('Accounts', 'account@gearset.com');
        insert contactOwner;

        Contact c = new Contact(LastName = 'Kuiper', OwnerId = contactOwner.Id);
        insert c;

        User u = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert u;

        ContactReopenHandler.handleExistingContactLogin(c, true);

        List<Account> contacts = [SELECT Id, OwnerId FROM Account];
        List<Task> tasks = [SELECT Id, OwnerId, WhoId, WhatId FROM Task];

        System.assertEquals(1, tasks.size());
        System.assertEquals(null, tasks[0].WhatId);
        System.assertEquals(c.Id, tasks[0].WhoId);
        System.assertEquals(c.OwnerId, tasks[0].OwnerId);
    }
}
