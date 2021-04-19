public without sharing class RenewalOpportunityService {
    private static final Logger LOGGER = LogFactory.create(RenewalOpportunityService.class);
    
    public static List<CreatedRenewalOpportunity> createRenewalOpportunities(List<TeamLicenseRenewal> teamLicenseRenewals) {
        List<CreatedRenewalOpportunity> createdRenewalOpportunities = new List<CreatedRenewalOpportunity>();
        
        for (TeamLicenseRenewal teamLicenseRenewal : teamLicenseRenewals) {
            String teamId = teamLicenseRenewal.teamId;
            Account renewalAccount = getRenewalAccount(teamId);
            
            if (renewalAccount == null) {
                upsertTaskForFixingAccount(teamId);
                continue;
            }
            
            List <LicenseRenewalData> licenseRenewalData = teamLicenseRenewal.licenseRenewalData;
            Opportunity renewalOpportunity = addRenewalOpportunity(renewalAccount, licenseRenewalData);
            
            createdRenewalOpportunities.add(new CreatedRenewalOpportunity(renewalOpportunity, licenseRenewalData));
        }
        
        return createdRenewalOpportunities;
    }
    
    private static Account getRenewalAccount(String teamId) {
        List<Account> renewalAccounts = [SELECT Id, Name, OwnerId FROM Account WHERE Gearset_team__r.Gearset_team_id__c = :teamId];
        return renewalAccounts.size() > 0 ? renewalAccounts.get(0) : null;
    }
    
    private static Opportunity addRenewalOpportunity(Account renewalAccount, LicenseRenewalData[] licenseRenewalData) {
        // TODO: Log active opportunities for contact
        
        // The admin site creates rewnewals for licenses expiring 70 days from now
        DateTime closeDateTime = System.now().addDays(70);
        Date closeDate = closeDateTime.date();

        String opportunityName = String.format('{0} Renewal ({1})', new String[] { renewalAccount.Name, closeDateTime.format('dd MMMM yyyy') });
        
        Id owner = CsmAssignment.assigneeForNewRenewalOpp(renewalAccount);
        LOGGER.info('Assigning new renewal opportunity to {0}', owner);
        
        String recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Gearset Renewals Process').getRecordTypeId();
        
        
        Opportunity newOpportunity = new Opportunity(
            Name = opportunityName,
            AccountId = renewalAccount.Id,
            CloseDate = closeDate,
            OwnerId = owner,
            RecordTypeId = recordTypeId,
            StageName = 'Approaching Renewal',
            Renewal_Date__c = closeDate,
            Type = 'Renewal'
        );
        
        insert newOpportunity;
        
        addNotesToOpportunity(newOpportunity, licenseRenewalData);
        
        addTaskForRenewal(newOpportunity);
        
        return newOpportunity;
    }
    
    private static void upsertTaskForFixingAccount(String teamId) {
        String taskSubject = String.format('Assign team {0} to an account', new List<String> { teamId });
        
        List<Task> existingFixTasks = [SELECT Id FROM Task WHERE Subject = :taskSubject ];
        
        if (existingFixTasks.size() == 0) {
            UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
            List<User> csms = [SELECT Id FROM User WHERE UserRoleId = :csmRoleId.Id ORDER BY Email];

            String taskSubjectPattern = 'Assign team %';
            List<Task> allFixTasks = [SELECT Id FROM Task WHERE Subject LIKE :taskSubjectPattern ];
            String ownerId = csms[Math.mod(allFixTasks.size(), csms.size())].Id;
            
            Task fixTask = new Task(
                Subject = taskSubject,
                Status = 'Open',
                Priority = 'Normal',
                OwnerId = ownerId,
                ActivityDate = Date.today()
            );
            
            insert fixTask;
        }
    }
    
    private static void addTaskForRenewal(Opportunity newOpportunity) {
        Task t = new Task(
            Subject = 'Contact about upcoming renewal',
            Status = 'Open',
            Priority = 'Normal',
            WhatId = newOpportunity.Id,
            OwnerId = newOpportunity.OwnerId,
            ActivityDate = Date.today()
        );
        
        insert t;
    }
    
    private static void addNotesToOpportunity(Opportunity newOpportunity, LicenseRenewalData[] renewals) {
        List<ContentNote> notes = new List<ContentNote>();
        
        for (LicenseRenewalData data : renewals) {        
            ContentNote note = new ContentNote();
            note.Title = String.format('Details for {0} renewal', new String[] { data.licensePlanName });
            
            String content = '';
            content += '<p>License id: ' + data.licenseId + '</p>';
            content += '<p>License name: ' + data.licensePlanName + '</p>';
            content += '<p>License quantity: ' + data.licenseQuantity + '</p>';
            content += '<p>Fastspring reference: ' + data.fastspringReference + '</p>';
            note.Content = Blob.valueOf(content);
            
            notes.add(note);
        }
        
        insert notes;
        
        List<ContentDocumentLink> links = GenerateLinksForNotes(newOpportunity, notes);
        
        insert links;
    }
    
    private static List<ContentDocumentLink> generateLinksForNotes(Opportunity newOpportunity, List<ContentNote> notes) {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        
        for (ContentNote note : notes) {
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = newOpportunity.Id;
            link.ContentDocumentId = note.Id;
            link.shareType = 'V';
            
            links.add(link);
        }
        
        return links;
    }
}