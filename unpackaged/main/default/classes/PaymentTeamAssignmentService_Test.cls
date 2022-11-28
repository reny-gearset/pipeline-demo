@isTest
public class PaymentTeamAssignmentService_Test {
    @isTest
    public static void shouldCreateTaskAndAssignSalesWhenOpportunityReachesIssuingInvoiceStage() {
        Opportunity opp = createTestRenewalOpportunity(
            'Opp1',
            'license123',
            'fastspring123',
            'acc1',
            'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );
        opp.StageName = 'Invoice Issued';
        update opp;

        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        System.assertEquals(1, oppTasks.size());

        Task task = oppTasks.get(0);
    }

    @isTest
    public static void shouldCreateTaskAndAssignSalesWhenOpportunityReachesClosedWonStage() {
        Opportunity opp = createTestRenewalOpportunity(
            'Opp1',
            'license123',
            'fastspring123',
            'acc1',
            'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );

        opp.StageName = 'Closed Won';
        update opp;

        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        System.assertEquals(1, oppTasks.size());

        Task task = oppTasks.get(0);
    }

    @isTest
    public static void shouldCorrectlyRoundRobinCreatedOpportunityTask() {
        Opportunity[] testOpps = new Opportunity[] {
            createTestRenewalOpportunity(
                'Opp1',
                'license1',
                'fastspring1',
                'Acc1',
                'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
            ),
            createTestRenewalOpportunity(
                'Opp2',
                'license2',
                'fastspring2',
                'Acc2',
                'f4d1a738-e8d8-4c1f-8cb5-8904fef2f077'
            )
        };

        testOpps.get(0).StageName = 'Invoice Issued';
        testOpps.get(1).StageName = 'Invoice Issued';

        update testOpps;

        // verify that task owners are different
        List<Task> oppTasks = [
            SELECT OwnerId
            FROM Task
            WHERE
                Subject = 'Invoice ready to be sent'
                AND (WhatId = :testOpps.get(0).Id
                OR WhatId = :testOpps.get(1).Id)
        ];

        System.assertEquals(2, oppTasks.size());
        System.assertNotEquals(
            oppTasks.get(0),
            oppTasks.get(1),
            'Created tasks have same owners (should have different ones)'
        );
    }

    @isTest
    public static void shouldNotCreateTaskTwiceIfOtherRenewalOpportunityFieldChanged() {
        Opportunity opp = createTestRenewalOpportunity(
            'Opp1',
            'license123',
            'fastspring123',
            'acc1',
            'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );
        opp.StageName = 'Invoice Issued';
        update opp;

        opp.Name = 'Once in a Lifetime Opportunity';
        update opp;

        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        System.assertEquals(1, oppTasks.size(), 'More than one task was created for this opportunity');
    }

    @isTest
    public static void shouldNotCreateTaskTwiceIfRenewalOpportunityStatusChangesTwice() {
        Opportunity opp = createTestRenewalOpportunity(
            'Opp1',
            'license123',
            'fastspring123',
            'acc1',
            'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );
        opp.StageName = 'Invoice Issued';
        update opp;

        opp.StageName = 'Discovery';
        update opp;

        opp.StageName = 'Invoice Issued';
        update opp;

        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        System.assertEquals(1, oppTasks.size(), 'More than one task was created for this opportunity');
    }

    @isTest
    public static void shouldNotCreateTaskAndAssignSalesWhenOpportunityReachesIssuingInvoiceStageWithoutApContactAndInvoiceSpecified() {
        Opportunity opp = createTestRenewalOpportunity(
            'Opp1',
            'license123',
            'fastspring123',
            'acc1',
            'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );
        opp.StageName = 'Invoice Issued';
        opp.AP_Contact__c = null;
        opp.Invoice_Number__c = '';
        update opp;

        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        System.assertEquals(0, oppTasks.size());
    }

    @isTest
    private static void shouldNotCreateTaskIfOpportunityPaymentHasBeenPaid() {
        Opportunity opp = createTestRenewalOpportunity(
            'Opp1',
            'license123',
            'fastspring123',
            'acc1',
            'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076'
        );
        opp.StageName = 'Invoice Issued';
        opp.Payment_Stage__c = 'Paid';
        update opp;

        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        System.assertEquals(0, oppTasks.size());
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Opportunity createTestRenewalOpportunity(
        String oppName,
        String licenseId,
        String fastspringRef,
        String accountName,
        String teamId
    ) {
        Gearset_Team__c gt = new Gearset_Team__c(Gearset_Team_Id__c = teamId);
        upsert gt;

        Account account = new Account();
        account.churn_risk__c = 'Onboarding';
        account.Name = accountName;
        account.Gearset_team__c = gt.Id;
        insert account;

        account = [SELECT Id, OwnerId FROM Account WHERE Id = :account.Id]; // refetch to get the new owner id

        Contact contact = new Contact(AccountId = account.Id, LastName = 'TestSurname', Contact_Status__c = 'Outreach');
        insert contact;

        List<LicenseRenewalData> renewals = new List<LicenseRenewalData>{
            new LicenseRenewalData(licenseId, 'Pro', 1, fastspringRef)
        };

        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal>{
            new TeamLicenseRenewal(teamId, renewals)
        };

        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(
            teamLicenseRenewals
        );

        Id newOpportunityId = createdRenewalOpportunities.get(0).opportunityId;

        Opportunity opp = [SELECT LicensesAssigned__c FROM Opportunity WHERE Id = :newOpportunityId];
        opp.Name = oppName;
        opp.Invoice_Number__c = '12345';
        opp.AP_Contact__c = contact.Id;
        opp.LicensesAssigned__c = true;
        opp.Renewal_Date__c = Date.today().addYears(1);
        opp.Amount = 10;
        opp.Payment__c = '36df87f9-c44f-4b6f-86b1-c76e4735906c';
        opp.MRR_at_renewal__c = 100;
        opp.Seats_at_renewal__c = 1;

        return opp;
    }
}
