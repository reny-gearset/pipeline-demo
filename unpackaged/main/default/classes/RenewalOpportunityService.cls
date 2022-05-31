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
            if (renewalOpportunity == null) {
                continue;
            }

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
        
        Opportunity[] existingOpps = [SELECT Id FROM Opportunity WHERE AccountId = :renewalAccount.Id AND StageName = 'Approaching Renewal'];
        if (existingOpps.size() > 0) {
            LOGGER.info('There is already a renewal opportunity open ({0}) for an Account ({1})', existingOpps.get(0).Id, renewalAccount.Id);
            return null;
        }

        Id owner = CsmAssignment.assigneeForNewRenewalOpp(renewalAccount);
        LOGGER.info('Assigning new renewal opportunity to {0}', owner);
        
        // The admin site creates rewnewals for licenses expiring 120 days from now
        //TODO: This needs to be based on the date of the expiring sub, not assuming everything is exactly 120 days away from now
        DateTime closeDateTime = System.now().addDays(120);
        Date closeDate = closeDateTime.date();
        
        String opportunityName = String.format('{0} [RENEWAL] - {1}', new String[] { renewalAccount.Name, closeDateTime.format('dd MMMM yyyy') });
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
        
        importContactRolesFromPrevOppIfAny(renewalAccount.Id, newOpportunity.Id);

        addNotesToOpportunity(newOpportunity, licenseRenewalData);
        
        addTasksForRenewalOpp(newOpportunity);
        
        return newOpportunity;
    }
    
    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    private static void importContactRolesFromPrevOppIfAny(Id accountId, Id newOppId) {
        List<Opportunity> recentOpps = [SELECT Id FROM Opportunity WHERE AccountId = :accountId AND Id != :newOppId ORDER BY CreatedDate DESC];
        if (recentOpps.size() == 0) {
            // skip as there are no contact roles to import
            return;
        }
        
        List<OpportunityContactRole> importedContactRoles = new List<OpportunityContactRole>();
        
        for (Opportunity recentOpp : recentOpps) {
            List<OpportunityContactRole> contactRoles = [SELECT ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :recentOpp.Id];
            if (contactRoles.size() > 0) {
                for (OpportunityContactRole contactRole : contactRoles) {
                    OpportunityContactRole newContactRole = contactRole.clone(
                        false,  // do not preserve id
                        false,  // do not deep clone
                        false,  // do not preserve readonly timestamps
                        false   // do not preserve autonumber
                    );
                    newContactRole.OpportunityId = newOppId;
                    importedContactRoles.add(newContactRole);
                }

                break;
            }
        }

        insert importedContactRoles;
    }

    private static void upsertTaskForFixingAccount(String teamId) {
        String taskSubject = String.format('Assign team {0} to an account', new List<String> { teamId });
        
        List<Task> existingFixTasks = [SELECT Id FROM Task WHERE Subject = :taskSubject ];
        
        if (existingFixTasks.size() == 0) {
            List<User> potentialTaskOwners = getValidAccountFixTaskOwners();
            String taskSubjectPattern = 'Assign team %';
            List<Task> allFixTasks = [SELECT Id FROM Task WHERE Subject LIKE :taskSubjectPattern ];
            String ownerId = potentialTaskOwners[Math.mod(allFixTasks.size(), potentialTaskOwners.size())].Id;
            
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
    
    private static List<User> getValidAccountFixTaskOwners() {
        List<String> assignedUsernames = new List<String> {
            'katharine@gearset.com%',   // Katharine Darbishire
            'joey.fereday@gearset.com%' // Joey Fereday 
        };
        List<User> potentialTaskOwners = [SELECT Id FROM User WHERE Username LIKE :assignedUsernames ORDER BY Email];

        if (potentialTaskOwners.size() > 0) {
            return potentialTaskOwners;
        }
        
        // Fallback to original users if we fail to retrieve anyone
        LOGGER.info('Found 0 valid account fix task owners, falling back to csms instead');
        return [SELECT Id FROM User WHERE UserRole.DeveloperName = 'Customer_Success_Manager' ORDER BY Email];
    }
    
    private static void addTasksForRenewalOpp(Opportunity newOpportunity) {

        List<Task> tasks = new List<Task> {
            TaskFactory.createRenewalOpportunityTask(newOpportunity, TaskFactory.RenewalOpportunityTaskType.CONTACT_ABOUT_UPCOMING_RENEWAL),
            TaskFactory.createRenewalOpportunityTask(newOpportunity, TaskFactory.RenewalOpportunityTaskType.UPDATE_RENEWAL_INFO)
        };

        insert tasks;
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