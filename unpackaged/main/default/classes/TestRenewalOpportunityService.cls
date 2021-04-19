@isTest
public class TestRenewalOpportunityService {

    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];

    @isTest
    public static void createRenewalOpportunityShouldCreateOpportunityAndTask() {
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
        
        LicenseRenewalData[] renewals = new LicenseRenewalData[] {
            new LicenseRenewalData('license123', 'Pro', 123, 'fastspring123')
        };

        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal> { new TeamLicenseRenewal(testTeamId, renewals) };
        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        
        Id newOpportunityId = createdRenewalOpportunities.get(0).opportunityId;
        
        // Check the opportunity was created correctly

        Opportunity opp = [SELECT Name, AccountId, ContactId, CloseDate, OwnerId, RecordTypeId, StageName, Renewal_Date__c FROM Opportunity WHERE Id = :newOpportunityId];

        DateTime closeDate = DateTime.newInstance(opp.CloseDate.year(), opp.CloseDate.month(), opp.CloseDate.day());
        String formattedCloseDate = closeDate.format('dd MMMM yyyy');
        
        System.assertEquals('Gearset Renewal (' + formattedCloseDate + ')', opp.Name);
        System.assertEquals(account.Id, opp.AccountId);
        System.assertEquals(opp.CloseDate, opp.Renewal_Date__c);
        System.assertEquals(account.OwnerId, opp.OwnerId);
        // 'Gearset Renewals Process'
        System.assertEquals('0124K000000pyVaQAI', opp.RecordTypeId); // NOPMD - hard coded id
        System.assertEquals('Approaching Renewal', opp.StageName);
        
        // Check an associated task has been created correctly
        
        Task t = [SELECT Subject, Status, Priority, WhatId, WhoId, OwnerId FROM Task];
        
        System.assertEquals('Contact about upcoming renewal', t.Subject);
        System.assertEquals('Open', t.Status);
        System.assertEquals('Normal', t.Priority);
        System.assertEquals(opp.Id, t.WhatId);
        System.assertEquals(opp.OwnerId, t.OwnerId);
        
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
}