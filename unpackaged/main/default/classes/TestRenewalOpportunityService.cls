@isTest
public class TestRenewalOpportunityService {

    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];

    @isTest
    public static void createRenewalOpportunityShouldCreateOpportunityAndTasks() {
        Id initialOwnerId = [SELECT Id FROM User WHERE Username LIKE 'jennifer.hicks@gearset.com%'].Id;
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';

        Gearset_Team__c gt = new Gearset_Team__c(
            Gearset_Team_Id__c = testTeamId
        );
        upsert gt;
        
        Account account = new Account();
        account.Name = 'Gearset';
        account.Gearset_team__c = gt.Id;
        account.OwnerId = initialOwnerId;
        insert account;
        
        account = [SELECT Id, OwnerId FROM Account WHERE Id = :account.Id]; // refetch to get the new owner id
        
        LicenseRenewalData[] renewals = new LicenseRenewalData[] {
            new LicenseRenewalData('license123', 'Pro', 123, 'fastspring123')
        };

        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal> { new TeamLicenseRenewal(testTeamId, renewals) };
        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        
        Id newOpportunityId = createdRenewalOpportunities.get(0).opportunityId;
        
        // Check the opportunity was created correctly

        Opportunity opp = [SELECT Name, AccountId, ContactId, CloseDate, OwnerId, RecordTypeId, StageName, Renewal_Date__c FROM Opportunity WHERE Id = :newOpportunityId];

        DateTime closeDate = DateTime.newInstance(opp.CloseDate.year(), opp.CloseDate.month(), opp.CloseDate.day());
        
        System.assertEquals(String.format('Gearset [RENEWAL] - {0}', new String[] { closeDate.format('dd MMMM yyyy') }), opp.Name);
        System.assertEquals(account.Id, opp.AccountId);
        System.assertEquals(opp.CloseDate, opp.Renewal_Date__c);
        System.assertEquals(account.OwnerId, opp.OwnerId);
        // 'Gearset Renewals Process'
        System.assertEquals('0124K000000pyVaQAI', opp.RecordTypeId); // NOPMD - hard coded id
        System.assertEquals('Approaching Renewal', opp.StageName);
        
        // Check that associated tasks were created correctly
        
        List<Task> renewalOppTasks = [SELECT Subject, Status, Priority, ActivityDate, WhatId, WhoId, OwnerId FROM Task];
        System.assertEquals(2, renewalOppTasks.size());

        Task t1 = renewalOppTasks.get(0);
        System.assertEquals('Contact about upcoming renewal', t1.Subject);
        System.assertEquals('Open', t1.Status);
        System.assertEquals('Normal', t1.Priority);
        System.assertEquals(opp.Id, t1.WhatId);
        System.assertEquals(opp.OwnerId, t1.OwnerId);
        System.assertEquals(Date.today().addDays(30), t1.ActivityDate);
        
        Task t2 = renewalOppTasks.get(1);
        System.assertEquals('Update renewal information', t2.Subject);
        System.assertEquals('Open', t2.Status);
        System.assertEquals('Normal', t2.Priority);
        System.assertEquals(opp.Id, t2.WhatId);

        // Check an associated content note has been created correctly
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id];
        
        System.assertEquals(links.size(), 1);
        System.assertEquals(links.get(0).ContentDocument.Title, 'Details for Pro renewal');
    }

    @isTest
    public static void createRenewalOpportunityShouldCreateNoteForEachLicense() {
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';

        Gearset_Team__c gt = new Gearset_Team__c(
            Gearset_Team_Id__c = testTeamId
        );
        upsert gt;
        
        Account account = new Account();
        account.Name = 'Gearset';
        account.Gearset_team__c = gt.Id;
        insert account;
        
        LicenseRenewalData[] renewals = new LicenseRenewalData[] {
            new LicenseRenewalData('license123', 'Data', 123, 'fastspring123'),
            new LicenseRenewalData('license456', 'Pro', 456, 'fastspring456')
        };
        
        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal> { new TeamLicenseRenewal(testTeamId, renewals) };
        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        
        Id newOpportunityId = createdRenewalOpportunities.get(0).opportunityId;
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :newOpportunityId];
        
        Set<String> linkNames = new Set<String>();
        for (ContentDocumentLink link : links) {
            linkNames.add(link.ContentDocument.Title);
        }
        
        System.assertEquals(links.size(), 2);
        System.assert(linkNames.contains('Details for Pro renewal'));
        System.assert(linkNames.contains('Details for Data renewal'));
    }

    @isTest
    public static void shouldIdempotentlyCreateTaskForTeamIdThatDidNotMatchAccount() {
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';

        LicenseRenewalData[] renewals = new LicenseRenewalData[] {
            new LicenseRenewalData('license123', 'Pro', 123, 'fastspring123')
        };

        String expectedTaskSubject = String.format('Assign team {0} to an account', new List<String> { testTeamId });

        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal> { new TeamLicenseRenewal(testTeamId, renewals) };
        RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);

        List<Task> fixTasks = [SELECT Id FROM Task WHERE Subject = :expectedTaskSubject ];
        
        System.assertEquals(fixTasks.size(), 1);
    }

    @isTest
    public static void shouldCreateOnlyOneRenewalOpportunityPerAccount() {
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';

        Gearset_Team__c gt = new Gearset_Team__c(
            Gearset_Team_Id__c = testTeamId
        );
        upsert gt;
        
        Account account = new Account();
        account.Name = 'Gearset';
        account.Gearset_team__c = gt.Id;
        insert account;
        
        account = [SELECT Id, OwnerId FROM Account WHERE Id = :account.Id]; // refetch to get the new owner id
        
        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal> { 
            new TeamLicenseRenewal(testTeamId, new LicenseRenewalData[] { new LicenseRenewalData('license123', 'Pro', 123, 'fastspring123') }),
            new TeamLicenseRenewal(testTeamId, new LicenseRenewalData[] { new LicenseRenewalData('license456', 'DataCompliance', 456, 'fastspring456') })
        };

        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);

        System.assertEquals(createdRenewalOpportunities.size(), 1, 'More than 1 opportunity was created');        

        Id newOpportunityId = createdRenewalOpportunities.get(0).opportunityId;
        
        // Check the opportunity was created correctly

        Opportunity opp = [SELECT Name, AccountId, ContactId, CloseDate, OwnerId, RecordTypeId, StageName, Renewal_Date__c FROM Opportunity WHERE Id = :newOpportunityId];

        DateTime closeDate = DateTime.newInstance(opp.CloseDate.year(), opp.CloseDate.month(), opp.CloseDate.day());

        System.assertEquals(String.format('Gearset [RENEWAL] - {0}', new String[] { closeDate.format('dd MMMM yyyy') }), opp.Name);
        System.assertEquals(account.Id, opp.AccountId);
        System.assertEquals(opp.CloseDate, opp.Renewal_Date__c);
        System.assertEquals(account.OwnerId, opp.OwnerId);
        // 'Gearset Renewals Process'
        System.assertEquals('0124K000000pyVaQAI', opp.RecordTypeId); // NOPMD - hard coded id
        System.assertEquals('Approaching Renewal', opp.StageName);
        
        // Check that associated tasks were created correctly
        
        List<Task> renewalOppTasks = [SELECT Subject, Status, Priority, ActivityDate, WhatId, WhoId, OwnerId FROM Task];
        System.assertEquals(2, renewalOppTasks.size());

        Task t1 = renewalOppTasks.get(0);
        System.assertEquals('Contact about upcoming renewal', t1.Subject);
        System.assertEquals('Open', t1.Status);
        System.assertEquals('Normal', t1.Priority);
        System.assertEquals(opp.Id, t1.WhatId);
        System.assertEquals(opp.OwnerId, t1.OwnerId);
        System.assertEquals(Date.today().addDays(30), t1.ActivityDate);
        
        Task t2 = renewalOppTasks.get(1);
        System.assertEquals('Update renewal information', t2.Subject);
        System.assertEquals('Open', t2.Status);
        System.assertEquals('Normal', t2.Priority);
        System.assertEquals(opp.Id, t2.WhatId);
        
        // Check an associated content note has been created correctly
        
        List<ContentDocumentLink> links = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id];
        
        System.assertEquals(links.size(), 1);
        System.assertEquals(links.get(0).ContentDocument.Title, 'Details for Pro renewal');
    }

    @isTest
    public static void shouldCopyContractRolesFromPreviousOpportunity() {

        // todo:
        // create renewal opp 1
        // add contact role for renewal opp 1
        // close it (I guess)
        // create renewal opp 2
        // verify that renewal opp 2 has same contacts as renewal opp 1
        
        // create team
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';
        
        Gearset_Team__c gt = new Gearset_Team__c(
            Gearset_Team_Id__c = testTeamId
            );
        upsert gt;
        
        // create account
        Account account = new Account();
        account.Name = 'Gearset';
        account.Gearset_team__c = gt.Id;
        insert account;
        
        account = [SELECT Id, OwnerId FROM Account WHERE Id = :account.Id]; // refetch to get the new owner id
        
        // create contact
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;

        // create first renewal opp
        LicenseRenewalData[] renewals = new LicenseRenewalData[] {
            new LicenseRenewalData('license123', 'Pro', 123, 'fastspring123')
        };

        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal> { new TeamLicenseRenewal(testTeamId, renewals) };
        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        
        Id newOppId1 = createdRenewalOpportunities.get(0).opportunityId;
        Opportunity opp1 = [SELECT Id, StageName, Renewal_Date__c FROM Opportunity WHERE Id = :newOppId1];
        
        // create contact role for this opp
        OpportunityContactRole opp1ContactRole = new OpportunityContactRole(
            OpportunityId = opp1.Id,
            ContactId = contact.Id,
            Role = 'Evaluator'
        );
        insert opp1ContactRole;

        // also close the opp
        opp1.Invoice_Number__c = '12345';
        opp1.AP_Contact__c = contact.Id;
        opp1.LicensesAssigned__c = true;
        opp1.Renewal_Date__c = Date.today().addYears(1);
        opp1.Amount = 10;
        opp1.Payment__c = '36df87f9-c44f-4b6f-86b1-c76e4735906c';
        opp1.MRR_at_renewal__c = 100;
        opp1.Seats_at_renewal__c = 1;
        opp1.Loss_Reason__c = 'I sneezed during the demo call';
        opp1.StageName = 'Closed Lost';
        
        update opp1;

        // create another renewal opp
        createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        
        Id newOppId2 = createdRenewalOpportunities.get(0).opportunityId;
        List<OpportunityContactRole> opp2ContactRoles = [SELECT ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :newOppId2];
        
        System.assertEquals(1, opp2ContactRoles.size(), 'No contact roles were created');
        OpportunityContactRole opp2ContactRole = opp2ContactRoles.get(0);
        System.assertEquals(contact.Id, opp2ContactRole.ContactId);
        System.assertEquals('Evaluator', opp2ContactRole.Role);
    }
}