public without sharing class LeadIngestionService {
    public static final Logger LOGGER = LogFactory.create(LeadIngestionService.class);

    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
    private static Set<String> gearbotAssignedDomains = new Set<String>{ 'gmail', 'yahoo', 'hotmail', 'protonmail' };

    private static final string SDR_LEAD_DISTRIBUTION_QUEUE = 'SDR Lead Distribution Queue';
    private static final string SDR_ROLE = 'Sales Development Representative';

    public static List<SignupObjectImpact> upsertLead(LeadInfo leadInfo) {
        LOGGER.info('Ingesting {0}. Will check if new lead needs created, or if opps need reopened', leadInfo.email);
        sanitiseLeadInfo(leadInfo);

        Contact existingContact = tryGetExistingContact(leadInfo.email);

        if (existingContact != null) {
            LOGGER.info('Found an existing contact {0} for lead {1}', existingContact.Id, leadInfo.email);

            return ContactReopenHandler.handleExistingContactLogin(existingContact, leadInfo.isNewUser);
        }

        LOGGER.info('No contact for {0} so let\'s look for a lead', leadInfo.email);

        Lead existingLead = tryGetExistingLead(leadInfo.email);

        if (existingLead == null) {
            return handleNewLead(leadInfo);
        } else {
            return handleExistingLead(leadInfo, existingLead);
        }
    }

    private static List<SignupObjectImpact> handleExistingLead(LeadInfo leadInfo, Lead existingLead) {
        SignupObjectImpactStatus impact = updateLead(existingLead, leadInfo);

        if (impact == SignupObjectImpactStatus.REOPENED_OBJECT) {
            Lead updatedLead = tryGetExistingLead(existingLead.Email);
            if (leadInfo.isNewUser) {
                Task lostLeadTask = TaskFactory.createLeadTask(
                    updatedLead,
                    TaskFactory.LeadTaskType.LOST_LEAD_CREATED_ACCOUNT
                );
                insert lostLeadTask;
            } else if (existingLead.Reopen_if_logs_in__c) {
                Task lostLeadTask = TaskFactory.createLeadTask(
                    updatedLead,
                    TaskFactory.LeadTaskType.LOST_LEAD_SIGNED_IN
                );
                insert lostLeadTask;
            }
        }

        return SignupObjectImpact.asList(existingLead.Id, existingLead.OwnerId, impact);
    }

    private static List<SignupObjectImpact> handleNewLead(LeadInfo leadInfo) {
        if (leadInfo.isAcceptingTeamInvite == true && !String.isBlank(leadInfo.teamInviteTargetTeamId)) {
            Account acct = tryGetAccount(leadInfo.teamInviteTargetTeamId);

            if (acct != null) {
                return handleNewLeadWithMatchingAccount(leadInfo, acct);
            }

            LOGGER.info(
                'New user is joining team, but couldn\'t find a matching account for {0}',
                leadInfo.teamInviteTargetTeamId
            );
        }

        return handleNewLeadWithoutMatchingAccount(leadInfo);
    }

    private static List<SignupObjectImpact> handleNewLeadWithMatchingAccount(LeadInfo leadInfo, Account acct) {
        Lead newLead = createNewLead(leadInfo, acct);

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

    private static List<SignupObjectImpact> handleNewLeadWithoutMatchingAccount(LeadInfo leadInfo) {
        Lead newLead = createNewLead(leadInfo, null);

        Task newLeadTask = null;

        // check if the created lead is owned by Gearbot
        if (newLead.OwnerId == gearbot.Id) {
            newLeadTask = TaskFactory.createLeadTask(newLead, TaskFactory.LeadTaskType.NEW_LEAD_FOR_GEARBOT);
        } else {
            newLeadTask = TaskFactory.createLeadTask(newLead, TaskFactory.LeadTaskType.NEW_LEAD_FOR_SDR);
        }

        insert newLeadTask;

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

    private static Id getNewLeadOwner(LeadInfo leadInfo) {
        String domain = leadInfo.Email.split('@')[1];
        if (String.isEmpty(leadInfo.telephone) && gearbotAssignedDomains.Contains(domain.split('\\.')[0])) {
            return gearbot.Id;
        }

        return getNextOwnerFromRoundRobin(leadInfo);
    }

    private static Id getNextOwnerFromRoundRobin(LeadInfo leadInfo) {
        List<Group> sdrLeadTrackers = [SELECT Id FROM Group WHERE Name = :SDR_LEAD_DISTRIBUTION_QUEUE];
        if (!sdrLeadTrackers.isEmpty()) {
            return sdrLeadTrackers.get(0).Id;
        }
        return null;
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

        if (existingContacts.size() == 1) {
            return existingContacts.get(0);
        }

        return null;
    }

    private static SignupObjectImpactStatus updateLead(Lead existingLead, LeadInfo newLead) {
        Boolean haveUpdated = false;
        SignupObjectImpactStatus impact = SignupObjectImpactStatus.NO_IMPACT;

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

        if (
            existingLead.Status == LeadConstants.LOST_STATUS && (existingLead.Reopen_if_logs_in__c || newLead.isNewUser)
        ) {
            existingLead.Status = LeadConstants.READY_FOR_SDR_STATUS;
            if (!ownerIsAnSdr(existingLead.OwnerId) && !LeadUtilities.isGearsetTestlead(existingLead)) {
                existingLead.OwnerId = getNextOwnerFromRoundRobin(newLead);
            }
            haveUpdated = true;
            impact = SignupObjectImpactStatus.REOPENED_OBJECT;
        }

        if (haveUpdated) {
            update existingLead;
        }

        return impact;
    }

    private static Boolean ownerIsAnSdr(Id ownerId) {
        if (ownerId == null) {
            return false;
        }

        Id ownerRoleId = [SELECT UserRoleId FROM User WHERE Id = :ownerId].UserRoleId;
        Id sdrRoleId = [SELECT Id FROM UserRole WHERE Name = :SDR_ROLE LIMIT 1].Id;
        return ownerRoleId == sdrRoleId;
    }

    private static Lead createNewLead(LeadInfo leadInfo, Account acct) {
        string leadSource = leadInfo.isAcceptingTeamInvite == true
            ? LeadConstants.JOINING_TEAM_SOURCE
            : LeadConstants.TRIALIST_SOURCE;
        string lastName = String.isBlank(leadInfo.lastName) ? LeadConstants.DEFAULT_LAST_NAME : leadInfo.lastName;
        string companyName = acct == null ? LeadConstants.DEFAULT_COMPANY_NAME : acct.Name;
        string industry = acct == null
            ? null
            : (acct.Industry == null ? LeadConstants.DEFAULT_INDUSTRY : acct.Industry);
        Integer employees = acct == null
            ? null
            : (acct.NumberOfEmployees == null ? LeadConstants.DEFAULT_NUMBER_OF_EMPLOYEES : acct.NumberOfEmployees);
        string website = acct == null ? null : (acct.Website == null ? LeadConstants.DEFAULT_WEBSITE : acct.Website);

        Lead newLead = new Lead(
            FirstName = leadInfo.firstName,
            LastName = lastName,
            Email = leadInfo.email,
            Phone = leadInfo.telephone,
            Company = companyName,
            Industry = industry,
            NumberOfEmployees = employees,
            Website = website,
            Intercom_Url__c = leadInfo.intercomUrl,
            OwnerId = getNewLeadOwner(leadInfo),
            LeadSource = leadSource,
            PPC_Source__c = leadInfo.ppcSource
        );

        if (LeadUtilities.isGearsetTestlead(newLead)) {
            newLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
        }

        if (newLead.OwnerId != gearbot.Id) {
            newLead.Status = LeadConstants.READY_FOR_SDR_STATUS;
        }

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

    private static void sanitiseLeadInfo(LeadInfo leadInfo) {
        // The booleans in the leadinfo can be null, so make sure they are initialised to false to prevent annoying null wrangling
        if (leadInfo.isNewUser == null) {
            leadInfo.isNewUser = false;
        }

        if (leadInfo.isAcceptingTeamInvite == null) {
            leadInfo.isAcceptingTeamInvite = false;
        }
    }
}
