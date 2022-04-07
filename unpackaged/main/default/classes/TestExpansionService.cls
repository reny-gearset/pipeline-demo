@isTest
public class TestExpansionService {
    private static final Logger LOGGER = LogFactory.create(TestExpansionService.class);

	@isTest
    public static void testCreateExpansionsRoundRobinsSdrs() {
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        setupAccount(testTeamId, testEmail);
        
        Id backupLeadId = ExpansionService.createDataBackupTrialLead(testTeamId, testEmail);
        Lead backupLead = [ SELECT OwnerId FROM Lead WHERE Id = :backupLeadId ];
        
        Id dataLeadId = ExpansionService.createDataDeploymentTrialLead(testTeamId, testEmail);
        Lead dataLead = [ SELECT OwnerId FROM Lead WHERE Id = :dataLeadId ];
        
		Id backupLeadOwner = backupLead.Id;
        Id dataLeadOwner = dataLead.Id;
        
        System.assertNotEquals(backupLeadOwner, null);
        System.assertNotEquals(backupLeadOwner, dataLeadOwner);
    }   

    @isTest
    public static void createDataDeploymentTrialLeadSetsEmailForContactIfContactNotFound() {        
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = testTeamId
        );
        insert t;

        LOGGER.info('Inserted test Gearset_team__c ' + t.Id);

        Account accountTest = new Account(
            Name = 'TestAccount',
        	Gearset_team__c = t.Id
        );
        
        insert accountTest;
        
        Id dataLeadId = ExpansionService.createDataDeploymentTrialLead(testTeamId, testEmail);
        Lead dataLead = [ SELECT OwnerId, Name FROM Lead WHERE Id = :dataLeadId ];
        
        System.assertEquals('Data deployment trial for test@example.com', dataLead.Name);
    }
    
    @isTest
    public static void createDataBackupTrialLeadCreatesTask() {        
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        setupAccount(testTeamId, testEmail);
        
        Id backupLeadId = ExpansionService.createDataBackupTrialLead(testTeamId, testEmail);
        
        Task dataBackupTask = [ SELECT Subject FROM Task WHERE WhoId = :backupLeadId ];
        
        System.assertEquals('Work with Firstname Contact to get going with backup', dataBackupTask.Subject);
    }
    
    @isTest
    public static void createDataDeploymentTrialLeadCreatesTask() {        
        String testEmail = 'test@example.com';
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        setupAccount(testTeamId, testEmail);
        
        Id dataLeadId = ExpansionService.createDataDeploymentTrialLead(testTeamId, testEmail);
        
        Task dataBackupTask = [ SELECT Subject FROM Task WHERE WhoId = :dataLeadId ];
        
        System.assertEquals('Work with Firstname Contact to get going with data deployment', dataBackupTask.Subject);
    }
    
    static void setupAccount(String teamId, String email) {
        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = teamId
        );
        upsert t;

        LOGGER.info('Inserted test Gearset_team__c {0}', t.Id);

        Account accountTest = new Account(
            Name = 'TestAccount',
        	Gearset_team__c = t.Id
        );
        
        insert accountTest;
        
        Contact contactTest = new Contact(
            FirstName = 'Firstname',
            LastName = 'Contact',
            Email = email,
            AccountId = accountTest.Id
        );
        
        insert contactTest;        
    }
}