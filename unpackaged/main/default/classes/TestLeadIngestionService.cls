@isTest
public class TestLeadIngestionService {
	@isTest
    public static void shouldCreateLeadIfNoSimilarContactOrLeadExists() {
        LeadImporter.LeadInfo newLead = new LeadImporter.LeadInfo();
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
        LeadImporter.LeadInfo newLead = new LeadImporter.LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = 'gwilym@gearset.com';
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';
        
        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);
        
        Lead storedLead = [SELECT LastName, Company, LeadSource, Status, IsConverted, Website FROM Lead WHERE Email = 'gwilym@gearset.com'];
        
        System.assertEquals('Kuiper', storedLead.LastName);
        System.assertEquals('DON\'T KNOW', storedLead.Company);
        System.assertEquals('Joining team', storedLead.LeadSource);
        System.assertEquals('New', storedLead.Status);
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

        LeadImporter.LeadInfo newLead = new LeadImporter.LeadInfo();
        newLead.lastName = 'Kuiper';
        newLead.email = 'gwilym@gearset.com';
        newLead.isAcceptingTeamInvite = true;
        newLead.teamInviteTargetTeamId = 'Account1';
        
        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newLead);
        System.assertEquals(1, impactedObjects.size());

        SignupObjectImpact impactedObject = impactedObjects.get(0);
        
        Lead storedLead = [SELECT LastName, Company, LeadSource, Status, IsConverted FROM Lead WHERE Email = 'gwilym@gearset.com'];
        
        System.assertEquals('Kuiper', storedLead.LastName);
        System.assertEquals('Test account', storedLead.Company);
        System.assertEquals('Joining team', storedLead.LeadSource);
        System.assertEquals('Existing Account', storedLead.Status);
        System.assertEquals(true, storedLead.IsConverted);
        System.assertEquals(storedLead.Id, impactedObject.objectId);
        System.assertEquals(impactedObject.objectImpact, SignupObjectImpactStatus.NEWLY_CREATED);
    }
    
    @isTest
    public static void shouldHandleAMissingLastNameOnAnImportedLead() {
        LeadImporter.LeadInfo newLead = new LeadImporter.LeadInfo();
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
            LeadSource = 'Inbound'
        );
        
        insert existingLead;
        
        LeadImporter.LeadInfo newLead = new LeadImporter.LeadInfo();
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
        Contact existingContact = new Contact(
        	FirstName = 'Gwilym',
            LastName = 'Kuiper',
            Email = 'gwilym@gearset.com'
        );
        
        insert existingContact;
        
        LeadImporter.LeadInfo newInfo = new LeadImporter.LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = 'gwilym@gearset.com';
        
        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(0, impactedObjects.size());

        List<Lead> leads = [SELECT Id FROM Lead];
        
        System.assertEquals(0, leads.size());
    }
    
    @isTest
    public static void shouldReopenLeadIfLostButMarkedAsReopenIfLogsIn() {
        Lead l = getLostLead();
        
        insert l;
        
        LeadImporter.LeadInfo newInfo = new LeadImporter.LeadInfo();
        newInfo.lastName = 'Kuiper';
        newInfo.email = 'gwilym@gearset.com';
        
        List<SignupObjectImpact> impactedObjects = LeadIngestionService.upsertLead(newInfo);
        System.assertEquals(1, impactedObjects.size());

        Lead upsertedLead = [SELECT Id, Email, Status, OwnerId FROM Lead WHERE Email = 'gwilym@gearset.com' LIMIT 1];
        Task reopenedTask = [SELECT WhoId, Subject, OwnerId, Description FROM Task LIMIT 1];
        
        System.assertEquals(upsertedLead.Status, 'New');
        System.assertEquals(reopenedTask.OwnerId, upsertedLead.OwnerId);
        System.assertEquals(reopenedTask.WhoId, upsertedLead.Id);
        System.assert(reopenedTask.Description.contains('Competitor'));
        
        SignupObjectImpact impact = impactedObjects.get(0);

        System.assertEquals(upsertedLead.Id, impact.objectId);
        System.assertEquals(SignupObjectImpactStatus.REOPENED_OBJECT, impact.objectImpact);
    }
    
    @isTest
    public static void shouldCreateANewTaskIfLeadIsNew() {
        LeadImporter.LeadInfo newInfo = new LeadImporter.LeadInfo();
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
		Lead existingLead = new Lead(LastName = 'Kuiper', Email = 'gwilym@gearset.com', Company = 'Gearset', LeadSource = 'Inbound');
        insert existingLead;

        LeadImporter.LeadInfo newInfo = new LeadImporter.LeadInfo();
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

        LeadImporter.LeadInfo newInfo = new LeadImporter.LeadInfo();
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

        LeadImporter.LeadInfo newInfo = new LeadImporter.LeadInfo();
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
            LeadSource = 'Inbound',
            NumberOfEmployees = 70,
            Industry = 'Hi Tech',
            Website = 'gearset.com'
        );
    }
}