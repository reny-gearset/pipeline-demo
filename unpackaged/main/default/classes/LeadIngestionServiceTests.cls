@isTest
public class LeadIngestionServiceTests {
    @isTest
    public static void shouldCreateLeadIfNoSimilarContactOrLeadExists() {
        LeadInfo newLead = new LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = 'gwilym@gearset.com';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [SELECT LastName, Company, LeadSource FROM Lead WHERE Email = 'gwilym@gearset.com'];

        System.assertEquals('Kuiper', storedLead.LastName);
        System.assertEquals('DON\'T KNOW', storedLead.Company);
        System.assertEquals('Trialist', storedLead.LeadSource);
        System.assertEquals(storedLead.Id, impactedObject.objectId);
        System.assertEquals(impactedObject.objectImpact, SignupObjectImpactStatus.NEWLY_CREATED);
    }

    @isTest
    public static void shouldCreateLeadWithoutConvertingIfNoAccountExists() {
        LeadInfo newLead = new LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = 'gwilym@gearset.com';
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [
            SELECT LastName, Company, LeadSource, Status, IsConverted, Website
            FROM Lead
            WHERE Email = 'gwilym@gearset.com'
        ];

        System.assertEquals('Kuiper', storedLead.LastName);
        System.assertEquals('DON\'T KNOW', storedLead.Company);
        System.assertEquals('Joining team', storedLead.LeadSource);
        System.assertEquals('Ready for SDR', storedLead.Status);
        System.assertEquals(null, storedLead.Website);
        System.assertEquals(false, storedLead.IsConverted);
        System.assertEquals(storedLead.Id, impactedObject.objectId);
        System.assertEquals(impactedObject.objectImpact, SignupObjectImpactStatus.NEWLY_CREATED);
    }

    @isTest
    public static void shouldCreateLeadAndConvertIfAccountExists() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Account1');
        upsert team;

        Account acct = new Account(Name = 'Test account', Gearset_team__c = team.Id);
        upsert acct;

        LeadInfo newLead = new LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = 'gwilym@gearset.com';
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [
            SELECT LastName, Company, LeadSource, Status, IsConverted
            FROM Lead
            WHERE Email = 'gwilym@gearset.com'
        ];

        System.assertEquals('Kuiper', storedLead.LastName);
        System.assertEquals('Test account', storedLead.Company);
        System.assertEquals('Joining team', storedLead.LeadSource);
        System.assertEquals('Existing Account', storedLead.Status);
        System.assertEquals(true, storedLead.IsConverted);
        System.assertEquals(storedLead.Id, impactedObject.objectId);
        System.assertEquals(impactedObject.objectImpact, SignupObjectImpactStatus.NEWLY_CREATED);
    }

    @isTest
    public static void shouldNotAssignNewLeadToGearbotIfBusinessEmail() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Account1');
        upsert team;

        Account acct = new Account(Name = 'Test account', Gearset_team__c = team.Id);
        upsert acct;

        String email = 'awesome.customer@veryrealcompany.com';

        LeadInfo newLead = new LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = email;
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [SELECT OwnerId FROM Lead WHERE Email = :email];
        User owner = [SELECT Name FROM User WHERE Id = :storedLead.OwnerId];

        System.assertNotEquals('Gearbot Bobbins', owner.Name);
    }

    @isTest
    public static void shouldNotAssignNewLeadToGearbotIfItHasAPhoneNumber() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Account1');
        upsert team;

        Account acct = new Account(Name = 'Test account', Gearset_team__c = team.Id);
        upsert acct;

        String email = 'spammer@gmail.com';

        LeadInfo newLead = new LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = email;
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';
        newLead.telephone = '15551234';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [SELECT OwnerId FROM Lead WHERE Email = :email];
        User owner = [SELECT Name FROM User WHERE Id = :storedLead.OwnerId];

        System.assertNotEquals('Gearbot Bobbins', owner.Name);
    }

    @isTest
    public static void shouldAssignNewLeadToGearbotIfNotBusinessEmail() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Account1');
        upsert team;

        Account acct = new Account(Name = 'Test account', Gearset_team__c = team.Id);
        upsert acct;

        String email = 'spammer@gmail.com';

        LeadInfo newLead = new LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = email;
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [SELECT OwnerId FROM Lead WHERE Email = :email];
        User owner = [SELECT Name FROM User WHERE Id = :storedLead.OwnerId];

        System.assertEquals('Gearbot Bobbins', owner.Name);
    }

    @isTest
    public static void shouldHandleAMissingLastNameOnAnImportedLead() {
        LeadInfo newLead = new LeadInfo();
        newLead.lastName = '';
        newLead.email = 'gwilym@gearset.com';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead storedLead = [SELECT LastName, Company, LeadSource FROM Lead WHERE Email = 'gwilym@gearset.com'];

        System.assertEquals('Unknown', storedLead.LastName);
    }

    @isTest
    public static void shouldUpdateLeadIfSimilarLeadExistsButNoContact() {
        Lead existingLead = new Lead(
            LastName = 'Kuiper',
            Email = 'gwilym@gearset.com',
            Company = 'Gearset',
            LeadSource = 'Direct'
        );

        insert existingLead;

        LeadInfo newLead = new LeadInfo();
        newLead.firstName = 'Gwilym';
        newLead.lastName = 'Kuiper';
        newLead.email = 'gwilym@gearset.com';
        newLead.telephone = '01223 333333';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impact = impactedObjects.get(0);

        Lead storedLead = [SELECT FirstName, Phone FROM Lead WHERE Email = 'gwilym@gearset.com'];

        System.assertEquals('Gwilym', storedLead.FirstName);
        System.assertEquals('01223 333333', storedLead.Phone);
        System.assertEquals(storedLead.Id, impact.objectId);
        System.assertEquals(SignupObjectImpactStatus.NO_IMPACT, impact.objectImpact);
    }

    @isTest
    public static void shouldNotInsertALeadIfAContactAlreadyExists() {
        Account account = new Account(Name = 'Gearset');
        insert account;
        Contact existingContact = new Contact(FirstName = 'Gwilym', LastName = 'Kuiper', Email = 'gwilym@gearset.com', AccountId = account.Id);
        insert existingContact;

        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = 'gwilym@gearset.com';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(0, impactedObjects.size());

        List<Lead> leads = [SELECT Id FROM Lead];

        System.assertEquals(0, leads.size());
    }

    @isTest
    public static void shouldReopenLeadIfLostButMarkedAsReopenIfLogsIn() {
        Lead lead = getLostLead();
        insert lead;

        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = 'gwilym@gearset.com';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        Lead upsertedLead = [SELECT Id, Email, Status, OwnerId FROM Lead WHERE Email = 'gwilym@gearset.com' LIMIT 1];
        Task reopenedTask = [SELECT WhoId, Subject, OwnerId, Description FROM Task LIMIT 1];

        System.assertEquals('Ready for SDR', upsertedLead.Status);
        System.assertEquals(upsertedLead.OwnerId, reopenedTask.OwnerId);
        System.assertEquals(upsertedLead.Id, reopenedTask.WhoId);
        System.assert(reopenedTask.Description.contains('Competitor'));

        SignupObjectImpact impact = impactedObjects.get(0);

        System.assertEquals(upsertedLead.Id, impact.objectId);
        System.assertEquals(SignupObjectImpactStatus.REOPENED_OBJECT, impact.objectImpact);
    }

    @isTest
    public static void shouldAssignReopenedLeadsToAnSdr() {
        Id initialOwnerId = [SELECT Id FROM User WHERE Username LIKE 'jennifer.hicks@gearset.com%'].Id;
        String leadEmail = 'gwilym@notatestlead.gearset.co.uk';
        Lead lead = getLostLead();
        lead.OwnerId = initialOwnerId;
        lead.email = leadEmail;
        insert lead;

        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = leadEmail;

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        Lead upsertedLead = [SELECT Id, Email, Status, OwnerId FROM Lead WHERE Email = :leadEmail LIMIT 1];
        Task reopenedTask = [SELECT WhoId, Subject, OwnerId, Description FROM Task LIMIT 1];
        
        Id ownerRoleId = [SELECT UserRoleId FROM User WHERE Id = :upsertedLead.OwnerId].UserRoleId;
        Id sdrRoleId = [SELECT Id FROM UserRole WHERE Name = 'Sales Development Representative' LIMIT 1].Id;

        System.assertEquals(sdrRoleId, ownerRoleId);
        System.assertEquals(upsertedLead.OwnerId, reopenedTask.OwnerId);
    }

    @isTest
    public static void shouldCreateANewTaskIfLeadIsNew() {
        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = 'gwilym@gearset.com';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);

        Lead upsertedLead = [SELECT Id, Email, Status, OwnerId FROM Lead WHERE Email = 'gwilym@gearset.com' LIMIT 1];
        Task createdTask = [SELECT WhoId, Subject, OwnerId FROM Task LIMIT 1];

        System.assertEquals(upsertedLead.OwnerId, createdTask.OwnerId);
        System.assertEquals(SignupObjectImpactStatus.NEWLY_CREATED, impactedObject.objectImpact);
        System.assertEquals(upsertedLead.Id, impactedObject.objectId);
    }

    @isTest
    public static void shouldNotCreateANewTaskIfLeadIsNotNew() {
        Lead existingLead = new Lead(
            LastName = 'Kuiper',
            Email = 'gwilym@gearset.com',
            Company = 'Gearset',
            LeadSource = 'Direct'
        );
        insert existingLead;

        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = 'gwilym@gearset.com';

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        List<Task> createdTasks = [SELECT Id FROM Task];

        System.assert(createdTasks.isEmpty());

        SignupObjectImpact impact = impactedObjects.get(0);
        System.assertEquals(existingLead.Id, impact.objectId);
        System.assertEquals(SignupObjectImpactStatus.NO_IMPACT, impact.objectImpact);
    }

    @isTest
    public static void shouldNotCreateATaskIfOriginallyLostLeadHasNotBeenMarkedAsNotify() {
        Lead existingLead = getLostLead();
        existingLead.Reopen_if_logs_in__c = false;
        insert existingLead;

        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = existingLead.LastName;
        newInfo.email = existingLead.Email;

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        List<Task> createdTasks = [SELECT Id FROM Task];

        System.assert(createdTasks.isEmpty());

        SignupObjectImpact impact = impactedObjects.get(0);
        System.assertEquals(existingLead.Id, impact.objectId);
        System.assertEquals(SignupObjectImpactStatus.NO_IMPACT, impact.objectImpact);
    }

    @isTest
    public static void shouldStillCreateATaskIfOriginallyLostLeadHasNotBeenMarkedAsNotifyButNewUser() {
        Lead existingLead = getLostLead();
        existingLead.Reopen_if_logs_in__c = false;
        insert existingLead;

        LeadInfo newInfo = new LeadInfo();
        newInfo.lastName = existingLead.LastName;
        newInfo.email = existingLead.Email;
        newInfo.isNewUser = true;

        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        List<Task> createdTasks = [SELECT Id FROM Task];

        System.assertEquals(1, createdTasks.size());

        SignupObjectImpact impact = impactedObjects.get(0);
        System.assertEquals(existingLead.Id, impact.objectId);
        System.assertEquals(SignupObjectImpactStatus.REOPENED_OBJECT, impact.objectImpact);
    }

    private static Lead getLostLead() {
        return new Lead(
            LastName = 'Kuiper',
            Company = 'Gearset',
            Email = 'gwilym@gearset.com',
            Status = 'Lost',
            Lost_Reason__c = 'Competitor',
            Reopen_if_logs_in__c = true,
            LeadSource = 'Direct',
            NumberOfEmployees = 70,
            Industry = 'Hi Tech',
            Website = 'gearset.com'
        );
    }
}
