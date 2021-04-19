@isTest
private class TestCsmAssignment {  
    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
    
    private static User getCsmUser() {
        User u = TestUtils.createStandardUser('CSM', 'csm@gearset.com');

        u.UserRoleId = csmRoleId.Id;
        return u;
    }
    
    @isTest
    public static void shouldNotSetOwnerOrChurnRiskIfAlreadySetAndMrrLessThan500() {
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
            LeadSource = 'Inbound',
            Type = 'New',
            Payment__c = 'GEA210215-1892-66159'
        );
        insert o;
        
        CsmAssignment.handleWonOpportunity(o);
        
        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(a.OwnerId, updatedAccount.OwnerId);
        System.assertEquals('Churn Risk - Attempting Contact', updatedAccount.churn_risk__c);
    }
    
    @isTest
    public static void shouldSetOwnerToACsmIfMrrGreaterThan500AndNotCurrentAssignedToOne() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            Gearset_team__c t = new Gearset_team__c(
                Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
            );
            upsert t;

            User u = TestUtils.createStandardUser('Last', 'my@email.com');
            insert getCsmUser();
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
                LeadSource = 'Inbound',
                Type = 'New',
                Payment__c = '20B3ECBC-1DA5-4A52-8848-961368E502F5'
            );
            insert o;
            
            CsmAssignment.handleWonOpportunity(o);
            
            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertNotEquals(u.Id, updatedAccount.OwnerId);
            System.assertEquals('Ramped', updatedAccount.Churn_risk__c);
        }
    }
     
    @isTest
    public static void shouldDoNothingIfOpIsNotNewBusiness() {
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
            LeadSource = 'Inbound',
            Type = 'Renewal',
            Payment__c = 'GEA210215-1892-66159'
        );
        insert o;
        
        CsmAssignment.handleWonOpportunity(o);
        
        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(a.OwnerId, updatedAccount.OwnerId);
        System.assertEquals('Churn Risk - Attempting Contact', updatedAccount.churn_risk__c);
    }
    
    @isTest
    public static void shouldNotModifyAccountOver500MrrIfOwnerIsAlreadyACsm() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) { // this is needed in order to avoid the MIXED_DML_OPERATION exception
            User csmUser = getCsmUser();
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
                Amount = 501,
                CloseDate = Date.today(),
                LeadSource = 'Inbound',
                Type = 'New',
                Payment__c = '20B3ECBC-1DA5-4A52-8848-961368E502F5'
            );
            insert o;
            
            CsmAssignment.handleWonOpportunity(o);
            
            Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
            System.assertEquals(csmUser.Id, updatedAccount.OwnerId);
            System.assertEquals('Ramped', updatedAccount.Churn_risk__c);
        }
    }
    
    @isTest
    public static void shouldSetAccountOwnerToOpportunityOwnerIfCurrentOwnerIsGearbot() {
        User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
        User u = TestUtils.createStandardUser('Last', 'my@email.com');
        insert u;

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        Account a = new Account(
            Name = 'My account',
            Gearset_Team__c = t.Id,
            Churn_Risk__c = null,
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
            LeadSource = 'Inbound',
            Type = 'New',
            Payment__c = 'GEA210215-1892-66159'
        );
        insert o;
        
        CsmAssignment.handleWonOpportunity(o);
        
        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(u.Id, updatedAccount.OwnerId);
        System.assertEquals(null, updatedAccount.Churn_risk__c);
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
    public static void shouldPickACsmIfAccountOwnerIsGearbot() {
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
            LeadSource = 'Inbound',
            Type = 'New',
            Payment__c = 'GEA210215-1892-66159S'
        );
        
        try{
            insert o;
        }
        catch(Exception e){
            System.Assert(e.getMessage().contains('Check that your Payment field is a valid Docusign envelope ID or a Fastspring ID. Note: Fastspring IDs do not have S at the end.'));
        }
    }    
    
    @isTest
    public static void allowLowerCaseDocusignIds() {
        User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
        User u = TestUtils.createStandardUser('Last', 'my@email.com');
        insert u;

        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = '03d25780-ecec-49bd-ab2d-cbe66095e3c0'
        );
        upsert t;

        Account a = new Account(
            Name = 'My account',
            Gearset_Team__c = t.Id,
            Churn_Risk__c = null,
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
            LeadSource = 'Inbound',
            Type = 'New',
            Payment__c = '10211464-d638-4e57-845e-ef1991de52d1'
        );
        insert o;
        
        CsmAssignment.handleWonOpportunity(o);
        
        Account updatedAccount = [SELECT OwnerId, Churn_risk__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(u.Id, updatedAccount.OwnerId);
        System.assertEquals(null, updatedAccount.Churn_risk__c);
    }  
}
