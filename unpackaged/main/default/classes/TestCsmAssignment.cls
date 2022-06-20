@isTest
private class TestCsmAssignment {

    private static UserRole mmCsmRole = [SELECT Id, Name FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
    private static UserRole smbCsmRole = [SELECT Id, Name FROM UserRole WHERE DeveloperName = 'Small_and_Medium_Customer_Success_Manager'];
    private static UserRole leadCsmRole = [SELECT Id, Name FROM UserRole WHERE DeveloperName = 'Lead_Customer_Success_Manager'];

    private static User getSmbCsmUser() {
        User u = TestUtils.createStandardUser('CSM', 'csm@gearset.com');
        u.UserRoleId = smbCsmRole.Id;
        return u;
    }

    private static User getMmCsmUser() {
        User u = TestUtils.createStandardUser('CSM', 'csm@gearset.com');
        u.UserRoleId = mmCsmRole.Id;
        return u;
    }

    private static User getLeadCsmUser() {
        User u = TestUtils.createStandardUser('CSM', 'csm@gearset.com');
        u.UserRoleId = leadCsmRole.Id;
        return u;
    }

    @isTest
    public static void shouldNotAssignInactiveCsmUser() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser) {
            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            
            User leadCsmUser1 = getLeadCsmUser();
            User leadCsmUser2 = getLeadCsmUser();
            User inactiveLeadCsmUser = getLeadCsmUser();
            inactiveLeadCsmUser.IsActive = False;

            Gearset_team__c t1 = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t1;

            Gearset_team__c t2 = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c1'
            );
            upsert t2;

            insert u;
            insert leadCsmUser1;
            insert leadCsmUser2;
            insert inactiveLeadCsmUser;

            Account a1 = new Account(
                Name = 'My account',
                Type = 'Implementation Partner',
                OwnerId = u.Id,
                Churn_risk__c = 'Churn Risk - Attempting Contact',
                Gearset_Team__c = t1.Id
            );
            insert a1;

            Opportunity o1 = new Opportunity(
                Name = 'My account op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a1.Id,
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o1;

            Account a2 = new Account(
                Name = 'My another account',
                Type = 'Implementation Partner',
                OwnerId = u.Id,
                Churn_risk__c = 'Churn Risk - Attempting Contact',
                Gearset_Team__c = t2.Id
            );
            insert a2;

            Opportunity o2 = new Opportunity(
                Name = 'Oxygen-rich op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a2.Id,
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o2;

            CsmAssignment.handleWonOpportunity(o1);
            CsmAssignment.handleWonOpportunity(o2);

            Account updatedAccount1 = [SELECT OwnerId FROM Account WHERE Id = :a1.Id];
            Account updatedAccount2 = [SELECT OwnerId FROM Account WHERE Id = :a2.Id];
            User accountOwnerUser1 = [SELECT UserRoleId, IsActive FROM User WHERE Id = :updatedAccount1.OwnerId];
            User accountOwnerUser2 = [SELECT UserRoleId, IsActive FROM User WHERE Id = :updatedAccount2.OwnerId];
            
            System.assertNotEquals(inactiveLeadCsmUser.Id, accountOwnerUser1.Id);
            System.assertNotEquals(inactiveLeadCsmUser.Id, accountOwnerUser2.Id);
            
            System.assertEquals(leadCsmRole.Id, accountOwnerUser1.UserRoleId);
            System.assertEquals(leadCsmRole.Id, accountOwnerUser2.UserRoleId);

            System.assertEquals(True, accountOwnerUser1.IsActive);
            System.assertEquals(True, accountOwnerUser2.IsActive);
        }
    }

    @isTest
    public static void shouldAssignAccountToLeadCsmUserIfAccountCustomerSegmentIsImplementationPartner() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser) {
            User leadCsmUser = getLeadCsmUser();
            User u = TestUtils.createStandardUser('Last', 'my@email.com');

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            insert u;
            insert leadCsmUser;
            Account a = new Account(
                Name = 'My account',
                Type = 'Implementation Partner',
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
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId FROM Account WHERE Id = :a.Id];
            User accountOwnerUser = [SELECT UserRoleId FROM User WHERE Id = :updatedAccount.OwnerId];
            System.assertEquals(leadCsmRole.Id, accountOwnerUser.UserRoleId);
        }
    }

    @isTest
    public static void shouldAssignAccountToLeadCsmUserIfAccountCustomerSegmentIsEnterprise() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser) {
            User leadCsmUser = getLeadCsmUser();
            User u = TestUtils.createStandardUser('Last', 'my@email.com');

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            insert u;
            insert leadCsmUser;
            Account a = new Account(
                Name = 'My account',
                Strategic__c = true,
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
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            User accountOwnerUser = [SELECT UserRoleId FROM User WHERE Id = :updatedAccount.OwnerId];
            System.assertEquals(leadCsmRole.Id, accountOwnerUser.UserRoleId);
        }
    }

    @isTest
    public static void shouldAssignAccountToSmbCsmUserIfOpportunityAmountIsLessThan1000() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser) {
            User smbCsmUser = getSmbCsmUser();
            User u = TestUtils.createStandardUser('Last', 'my@email.com');

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            insert u;
            insert smbCsmUser;
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
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            User accountOwnerUser = [SELECT UserRoleId FROM User WHERE Id = :updatedAccount.OwnerId];
            System.assertEquals(smbCsmRole.Id, accountOwnerUser.UserRoleId);
        }
    }

    @isTest
    public static void shouldAssignAccountToMmCsmUserIfOpportunityAmountIsOver1000() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser) {
            User mmCsmUser = getMmCsmUser();
            User u = TestUtils.createStandardUser('Last', 'my@email.com');

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            insert u;
            insert mmCsmUser;
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
                Amount = 1500,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            User accountOwnerUser = [SELECT UserRoleId FROM User WHERE Id = :updatedAccount.OwnerId];
            System.assertEquals(mmCsmRole.Id, accountOwnerUser.UserRoleId);
        }
    }

    @isTest
    public static void shouldNotSetOwnerOrChurnRiskIfAlreadySetAndOpportunityAmountLessThan1000() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User u = getSmbCsmUser();

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
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = 'GEA210215-1892-66159',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertEquals(a.OwnerId, updatedAccount.OwnerId);
            System.assertEquals('Churn Risk - Attempting Contact', updatedAccount.churn_risk__c);
        }
    }

    @isTest
    public static void shouldSetOwnerToCsmIfOppAmountGreaterThan1000AndNotCurrentlyAssignedToOne() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            insert getSmbCsmUser();
            insert u;
            Account a = new Account(
                Name = 'My account',
                OwnerId = u.Id,
                Churn_risk__c = 'Ramped',
                Gearset_Team__c = t.Id
            );
            insert a;

            Opportunity o = new Opportunity(
                Name = 'My account op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a.Id,
                Amount = 3000,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = '20B3ECBC-1DA5-4A52-8848-961368E502F5',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertNotEquals(u.Id, updatedAccount.OwnerId);
            System.assertEquals('Ramped', updatedAccount.Churn_risk__c);
        }
    }

    @isTest
    public static void shouldDoNothingIfOppIsNotNewBusiness() {
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
            Amount = 10000,
            CloseDate = Date.today(),
            LeadSource = 'Direct',
            Type = 'Renewal',
            Payment__c = 'GEA210215-1892-66159',
            Expected__c = 'Unknown'
        );
        insert o;

        CsmAssignment.handleWonOpportunity(o);

        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(a.OwnerId, updatedAccount.OwnerId);
        System.assertEquals('Churn Risk - Attempting Contact', updatedAccount.churn_risk__c);
    }

    @isTest
    public static void shouldNotModifyAccountIfOppAmountIsOver1000AndOwnerIsCsm() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User csmUser = getMmCsmUser();
            insert csmUser;
            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            insert u;

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            Account a = new Account(
                Name = 'My account',
                OwnerId = csmUser.Id,
                Churn_risk__c = 'Ramped',
                Gearset_Team__c = t.Id
            );
            insert a;

            Opportunity o = new Opportunity(
                Name = 'My account op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a.Id,
                Amount = 1001,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = '20B3ECBC-1DA5-4A52-8848-961368E502F5',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertEquals(csmUser.Id, updatedAccount.OwnerId);
            System.assertEquals('Ramped', updatedAccount.Churn_risk__c);
        }
    }

    @isTest
    public static void shouldReturnAccountOwnerIfCurrentOwnerIsNotGearbot() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User standardUser = TestUtils.createStandardUser('Last', 'my@email.com');
            insert standardUser;

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            Account a = new Account(
                Name = 'Some Account',
                OwnerId = standardUser.Id,
                Gearset_Team__c = t.Id
            );

            insert a;

            Id assigneeId = CsmAssignment.assigneeForNewRenewalOpp(a);

            System.assertEquals(standardUser.Id, assigneeId);
        }
    }

    @isTest
    public static void shouldPickACsmUserIfAccountOwnerIsGearbot() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            Account a = new Account(
                Name = 'My account',
                OwnerId = gearbot.Id,
                Gearset_Team__c = t.Id
            );
            insert a;

            Id assigneeId = CsmAssignment.assigneeForNewRenewalOpp(a);
            System.assertNotEquals(gearbot.Id, assigneeId);
        }
    }

    @isTest
    public static void shouldNotUpdateOppIfPaymentFormatIsIncorrect() {
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
            Amount = 300,
            CloseDate = Date.today(),
            LeadSource = 'Direct',
            Type = 'New',
            Payment__c = 'GEA210215-1892-66159S',
            Expected__c = 'Unknown'
        );

        try{
            insert o;
        }
        catch(Exception e){
            System.Assert(e.getMessage().contains('Check that your Payment field is a valid Docusign envelope ID or a Fastspring ID. Note: Fastspring IDs do not have S at the end.'));
        }
    }

    @isTest
    public static void shouldAllowLowerCaseDocusignIds() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception

            User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
            User u = getSmbCsmUser();
            insert u;

            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            Account a = new Account(
                Name = 'My account',
                Gearset_Team__c = t.Id,
                Churn_Risk__c = 'Onboarding',
                OwnerId = gearbot.Id
            );
            insert a;

            Opportunity o = new Opportunity(
                Name = 'My account op',
                StageName = 'Closed Won',
                OwnerId = u.Id,
                AccountId = a.Id,
                Amount = 300,
                CloseDate = Date.today(),
                LeadSource = 'Direct',
                Type = 'New',
                Payment__c = '10211464-d638-4e57-845e-ef1991de52d1',
                Expected__c = 'Unknown'
            );
            insert o;

            CsmAssignment.handleWonOpportunity(o);

            Account updatedAccount = [SELECT OwnerId, Churn_risk__c, Name FROM Account WHERE Id = :a.Id];
            System.assertEquals(u.Id, o.OwnerId);
            System.assertEquals('Onboarding', updatedAccount.Churn_risk__c);
        }
    }

    @isTest
    public static void shouldNotCloseWonIfChurnRiskIsNotSet() {
        User u = TestUtils.createStandardUser('Last', 'my@email.com');

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        insert u;
        Account a = new Account(
            Name = 'My account',
            OwnerId = u.Id,
            Churn_risk__c = null,
            Gearset_Team__c = t.Id
        );
        insert a;

        Opportunity o = new Opportunity(
            Name = 'My account op',
            StageName = 'Closed Won',
            OwnerId = u.Id,
            AccountId = a.Id,
            Amount = 300,
            CloseDate = Date.today(),
            LeadSource = 'Direct',
            Type = 'New',
            Payment__c = '10211464-d638-4e57-845e-ef1991de52d1',
            Expected__c = 'Unknown'
        );

        try{
            insert o;
        }
        catch(Exception e){
            System.Assert(e.getMessage().contains('You cannot set an Opportunity to close without setting the Stage on the account'));
        }
    }
}