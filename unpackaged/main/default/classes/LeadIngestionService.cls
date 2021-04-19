public without sharing class LeadIngestionService {
    public static final Logger LOGGER = LogFactory.create(LeadIngestionService.class);

    public static List<SignupObjectImpact> upsertLead(LeadImporter.LeadInfo l) {
        LOGGER.info('Ingesting {0}. Will check if new lead needs created, or if opps need reopened', l.email);

        Contact existingContact = tryGetExistingContact(l.email);

        if (existingContact != null) {
            LOGGER.info('Found an existing contact {0} for lead {1}', existingContact.Id, l.email);

            return ContactReopenHandler.handleExistingContactLogin(existingContact, l.isNewUser == true);
        }

        LOGGER.info('No contact for {0} so let\'s look for a lead', l.email);

        Lead existingLead = tryGetExistingLead(l.email);

        if (existingLead == null) {
            return handleNewLead(l);
        } else {
            return handleExistingLead(l, existingLead);
        }
    }

    private static List<SignupObjectImpact> handleExistingLead(LeadImporter.LeadInfo l, Lead existingLead) {
        Boolean wasLost = existingLead.Status == 'Lost';
        Boolean shouldCreateTask = updateLead(existingLead, l, l.isNewUser == true);

        if (shouldCreateTask) {
            createTaskForLead(existingLead, wasLost, l.isNewUser == true);
        }

        SignupObjectImpactStatus status = shouldCreateTask
            ? SignupObjectImpactStatus.REOPENED_OBJECT
            : SignupObjectImpactStatus.NO_IMPACT;

        return SignupObjectImpact.asList(existingLead.Id, existingLead.OwnerId, status);
    }

    private static List<SignupObjectImpact> handleNewLead(LeadImporter.LeadInfo l) {
        if (l.isAcceptingTeamInvite == true && !String.isBlank(l.teamInviteTargetTeamId)) {
            Account acct = tryGetAccount(l.teamInviteTargetTeamId);

            if (acct == null) {
                LOGGER.info(
                    'New user is joining team, but couldn\'t find a matching account for {0}',
                    l.teamInviteTargetTeamId
                );
                return handNewLeadWithoutMatchingAccount(l);
            } else {
                return handleNewLeadWithMatchingAccount(l, acct);
            }
        } else {
            return handNewLeadWithoutMatchingAccount(l);
        }
    }

    private static List<SignupObjectImpact> handleNewLeadWithMatchingAccount(LeadImporter.LeadInfo l, Account acct) {
        Lead newLead = createNewLead(l, acct);

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(newLead.Id);
        lc.setAccountId(acct.Id);
        lc.setOwnerId(acct.OwnerId);
        lc.setConvertedStatus('Existing Account');
        lc.setDoNotCreateOpportunity(true);
        lc.setSendNotificationEmail(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        if (!lcr.isSuccess()) {
            LOGGER.info('Unable to auto convert a new lead to an existing account');
            throw new DmlException(lcr.getErrors()[0].getMessage());
        }

        return SignupObjectImpact.asList(newLead.Id, newLead.OwnerId, SignupObjectImpactStatus.NEWLY_CREATED);
    }

    private static List<SignupObjectImpact> handNewLeadWithoutMatchingAccount(LeadImporter.LeadInfo l) {
        Lead newLead = createNewLead(l, null);

        createTaskForLead(newLead, false, l.isNewUser == true);

        return SignupObjectImpact.asList(newLead.Id, newLead.OwnerId, SignupObjectImpactStatus.NEWLY_CREATED);
    }

    private static Account tryGetAccount(String teamId) {
        LOGGER.info('Getting account for auto converting lead {0}', teamId);

        List<Account> accounts = [
            SELECT Id, Name, OwnerId, Industry, NumberOfEmployees, Website
            FROM Account
            WHERE Gearset_team__r.Gearset_team_id__c = :teamId
        ];

        LOGGER.info('Queried for an Account for {0} and received {1}', teamId, accounts.size());

        if (accounts.size() == 1) {
            return accounts.get(0);
        } else {
            return null;
        }
    }

    private static Id getNextOwnerFromRoundRobin() {
        Id ownerId = null;
        List<Group> sdrLeadTrackers = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];
        if (!sdrLeadTrackers.isEmpty()) {
            ownerId = sdrLeadTrackers.get(0).Id;
        }
        return ownerId;
    }

    private static Lead tryGetExistingLead(String email) {
        List<Lead> existingLeads = [
            SELECT
                Id,
                FirstName,
                LastName,
                Email,
                Phone,
                OwnerId,
                Intercom_Url__c,
                Lost_Reason__c,
                Lost_Reason_Notes__c,
                Reopen_if_logs_in__c,
                Status
            FROM Lead
            WHERE Email = :email
            LIMIT 1
        ];

        if (existingLeads.size() != 0) {
            return existingLeads.get(0);
        }

        return null;
    }

    private static Contact tryGetExistingContact(String email) {
        List<Contact> existingContacts = [SELECT Id, Account.Id, Name FROM Contact WHERE Email = :email LIMIT 1];

        // TODO: This can be changed to strictly == 1 as the limit above will enforce that...
        if (existingContacts.size() >= 1) {
            return existingContacts.get(0);
        }

        return null;
    }

    private static Boolean updateLead(Lead existingLead, LeadImporter.LeadInfo newLead, Boolean isNewUser) {
        Boolean haveUpdated = false;
        Boolean shouldCreateTask = false;

        if (existingLead.FirstName == null) {
            existingLead.FirstName = newLead.firstName;
            haveUpdated = true;
        }

        if (existingLead.Phone == null) {
            existingLead.Phone = newLead.telephone;
            haveUpdated = true;
        }

        if (existingLead.Intercom_Url__c == null) {
            existingLead.Intercom_Url__c = newLead.intercomUrl;
            haveUpdated = true;
        }

        if (existingLead.Status == 'Lost') {
            shouldCreateTask = handleLostLead(existingLead, newLead, isNewUser);
            haveUpdated = haveUpdated || shouldCreateTask;
        }

        if (haveUpdated) {
            update existingLead;
        }

        return shouldCreateTask;
    }

    private static boolean handleLostLead(Lead existingLead, LeadImporter.LeadInfo newLead, Boolean isNewUser) {
        if (existingLead.Reopen_if_logs_in__c || isNewUser) {
            existingLead.Status = 'New';

            return true;
        }

        return false;
    }

    private static void createTaskForLead(Lead l, Boolean wasLost, Boolean isNewUser) {
        if (l.OwnerId.getsObjectType() != User.getsObjectType()) {
            // can't assign a task to a queue
            return;
        }

        if (wasLost) {
            Task handleLostLead = new Task(
                Subject = isNewUser
                    ? 'A previous user has signed up for a new account. Sales opportunity? Kill trial?'
                    : 'Was lost, but has since logged in',
                Status = 'Open',
                Priority = 'Normal',
                WhoId = l.Id,
                OwnerId = l.OwnerId,
                ActivityDate = date.today(),
                Description = 'Original lost reason was: ' +
                    l.Lost_Reason__c +
                    '\nAdditional notes were: ' +
                    l.Lost_Reason_Notes__c
            );

            insert handleLostLead;
        } else {
            Task newLeadTask = new Task(
                Subject = 'Can we get this lead to be an opp?',
                Status = 'Open',
                Priority = 'Normal',
                WhoId = l.Id,
                OwnerId = l.OwnerId,
                Description = 'Lead ' + l.Email + ' needs triaging',
                ActivityDate = date.today()
            );

            insert newLeadTask;
        }
    }

    private static Lead createNewLead(LeadImporter.LeadInfo l, Account acct) {
        String leadSource = l.isAcceptingTeamInvite == true ? 'Joining team' : 'Trialist';
        String lastName = String.isBlank(l.lastName) ? 'Unknown' : l.lastName;

        string companyName = acct == null ? 'DON\'T KNOW' : acct.Name;
        string industry = acct == null ? null : (acct.Industry == null ? 'Unknown' : acct.Industry);
        Integer employees = acct == null ? null : (acct.NumberOfEmployees == null ? 100 : acct.NumberOfEmployees);
        string website = acct == null ? null : (acct.Website == null ? 'https://unknown.example.com' : acct.Website);

        Lead newLead = new Lead(
            FirstName = l.firstName,
            LastName = lastName,
            Email = l.email,
            Phone = l.telephone,
            Company = companyName,
            Industry = industry,
            NumberOfEmployees = employees,
            Website = website,
            Intercom_Url__c = l.intercomUrl,
            OwnerId = getNextOwnerFromRoundRobin(),
            LeadSource = leadSource
        );

        // Want to insert ignoring duplicates, so need to do a little dance
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.Insert(newLead, dml);

        if (!sr.isSuccess()) {
            // not sure the easiest way to throw the correct exception here
            throw new DmlException(sr.getErrors()[0].getMessage());
        }

        // fetch the lead again so we know who it was assigned to
        return [
            SELECT Id, OwnerId, Email, Lost_Reason__c, Lost_Reason_Notes__c
            FROM Lead
            WHERE Id = :newLead.Id
            LIMIT 1
        ];
    }
}
