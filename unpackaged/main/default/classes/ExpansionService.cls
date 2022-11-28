public without sharing class ExpansionService {
    private static final Logger LOGGER = LogFactory.create(ExpansionService.class);
    
    public static Id createDataBackupTrialLead(String teamId, String email) {
        Account account = getAccount(teamId, email);
        Contact expansionContact = getContact(account.Contacts);
        String contactName = getContactName(expansionContact, email);
                
        Lead backupLead = createExpansionLead('Data backup trial', contactName, account, email);
        
        createTaskForLead(backupLead, String.format('Work with {0} to get going with backup', new List<Object> { contactName }));
                
        return backupLead.Id;
    }
    
    public static Id createDataDeploymentTrialLead(String teamId, String email) {
        Account account = getAccount(teamId, email);
        Contact expansionContact = getContact(account.Contacts);
        String contactName = getContactName(expansionContact, email);
                
        Lead dataDeploymentLead = createExpansionLead('Data deployment trial', contactName, account, email);
        
        createTaskForLead(dataDeploymentLead, String.format('Work with {0} to get going with data deployment', new List<Object> { contactName }));
                
        return dataDeploymentLead.Id;
    }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Lead createExpansionLead(string leadType, string contactName, Account account, String email) {
       Group sdrLeadDistribution = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue' LIMIT 1];
       Lead expansionLead = new Lead(
            FirstName = leadType,
            MiddleName = 'for',
            LastName = contactName,
            Email = email,
            Company = account.Name,
            OwnerId = sdrLeadDistribution.Id,
            Status = 'Ready for SDR',
            LeadSource = 'Trialist'
        );
        
        if (LeadUtilities.isGearsetTestlead(expansionLead)) {
            expansionLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
        }

        insert expansionLead;
        
        // Need to refetch the lead because the owner will be changed by a trigger
        return [SELECT Id, OwnerId FROM Lead WHERE Id = :expansionLead.Id];
    }
    
    private static Account getAccount(String teamId, String email) {
        LOGGER.info('Getting account for expansion');

        Account account = [SELECT Id, Name, (SELECT Name, Email From Contacts WHERE Email = :email) FROM Account WHERE Gearset_team__r.Gearset_team_id__c = :teamId];

        LOGGER.info('Found an account for expansion {0}', account);
        
        if (account == null) {
            throw new IllegalArgumentException('Could not find account for expansion: ' + teamId);
        }
        
        return account;
    }
    
    private static Contact getContact(List<Contact> contacts) {
        Contact expansionContact = null;
        if (contacts.size() > 0) {
            expansionContact = contacts.get(0);
        }
        
        return expansionContact;
    }
    
    private static String getContactName(Contact contact, String email) {
        return contact != null ? contact.Name : email;
    }
    
    private static void createTaskForLead(Lead trialLead, String subject) {
        Task task = new Task(
            Subject = subject,
            Status = 'Open',
            Priority = 'Normal',
            WhoId = trialLead.Id,
            OwnerId = trialLead.OwnerId,
            ActivityDate = Date.today()
        );
        
        insert task;
    }
}