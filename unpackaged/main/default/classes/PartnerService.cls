public without sharing class PartnerService {
    private static final Logger LOGGER = LogFactory.create(PartnerService.class);

    public static void handlePartnerReferralLead(PartnerLeadController.PartnerLeadInfo info) {
        Account partnerAccount = getClosestMatchingPartnerAccount(info.teamId, info.referrerCompanyName);
        Contact partnerContact = getClosestMatchingPartnerContact(info, partnerAccount);
        
        Lead partnerReferralLead = createPartnerReferralLead(info, partnerAccount, partnerContact);
        
        createLeadTaskForPartnerReferralLead(partnerReferralLead);
        createPartnerAccountTaskForPartnerReferralLead(partnerReferralLead, partnerAccount);
    }
    
    public static void handlePartnerActivity(PartnerActivityController.PartnerActivityInfo info) {
        Account partnerAccount = getClosestMatchingPartnerAccount(info.teamId, '');
        
        createPartnerAccountTaskForPartnerActivity(partnerAccount, info.summary);
    }
    
    public static boolean shouldShowPartnerPortal(String teamId) {
        if (String.isBlank(teamId)) {
            return false;
        }
        
        List<Account> partnerAccounts = 
            [SELECT Id 
             FROM Account 
             WHERE Show_Partner_Portal__c = true AND Gearset_Team__r.Gearset_Team_Id__c = :teamId LIMIT 1 ];
        
        return !partnerAccounts.isEmpty();
    }
    
    public static void updateAccountPartnerAgreementEndDate(Contract contract) {
        Account account = [SELECT Id, Activated_Partner_Agreement_End_Date__c FROM Account WHERE Id = :contract.AccountId];
        LOGGER.info('Updating Account ({0}) for Contract {1}...', account.Id, contract.Id);
        account.Activated_Partner_Agreement_End_Date__c = contract.EndDate;
        update account;
        LOGGER.info('Updating Account ({0}) for Contract {1}...DONE', account.Id, contract.Id);
    }

    private static void createPartnerAccountTaskForPartnerReferralLead(Lead partnerReferralLead, Account partnerAccount) {
        Task newAccountTask = new Task(
            Subject = 'Your partner has referred a Lead to us. Is this a good Lead and who do you need to work with to get it closed?',
            Status = 'Open',
            Priority = 'Normal',
            WhoId = partnerReferralLead.Id,
            OwnerId = partnerAccount.OwnerId,
            Description = 'Referral Lead ' + partnerReferralLead.Email + ' needs reviewing',
            ActivityDate = date.today()
        );
        
        insert newAccountTask;
    }
    
    private static void createLeadTaskForPartnerReferralLead(Lead partnerReferralLead) {
        Task newLeadTask = new Task(
            Subject = 'Can we get this referral lead to be an opp?',
            Status = 'Open',
            Priority = 'Normal',
            WhoId = partnerReferralLead.Id,
            OwnerId = partnerReferralLead.OwnerId,
            Description = 'Referral Lead ' + partnerReferralLead.Email + ' needs triaging',
            ActivityDate = date.today()
        );
        
        insert newLeadTask;
    }
    
    private static void createPartnerAccountTaskForPartnerActivity(Account partnerAccount, String summary) {
        Task newAccountTask = new Task(
            Subject = 'Your partner has visited the partner portal. Is this a good opportunity to interact with them?',
            Status = 'Open',
            Priority = 'Normal',
            WhatId = partnerAccount.Id,
            OwnerId = partnerAccount.OwnerId,
            Description = 'Partner activity ' + summary + ' needs reviewing',
            ActivityDate = date.today()
        );
        
        insert newAccountTask;
    }
    
    private static Lead createPartnerReferralLead(PartnerLeadController.PartnerLeadInfo info, Account partnerAccount, Contact partnerContact) {
        Lead newLead = new Lead(
            FirstName = info.contactFirstName,
            LastName = info.contactLastName,
            Email = info.contactEmail,
            Company = info.contactCompanyName,
            OwnerId = getNextOwnerFromRoundRobin(),
            Status = 'New',
            LeadSource = 'Partner',
            Referrer_First_Name__c = info.referrerFirstName,
            Referrer_Last_Name__c = info.referrerLastName,
            Referrer_Email__c = info.referrerEmail,
            Referrer_Company_Name__c = info.referrerCompanyName,
            Referral_Extra_Details__c = info.extraDetails,
            SI_Partner__c = partnerAccount.Id
        );
        
        if (LeadUtilities.isGearsetTestlead(newLead)) {
            newLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
        }

        if (partnerContact != null) {
            newLead.Referrer_Contact__c = partnerContact.Id;
        }
        
        // Want to insert ignoring duplicates, so need to do a little dance
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.Insert(newLead, dml);

        if (!sr.isSuccess()) {
            // not sure the easiest way to throw the correct exception here
            throw new DmlException(sr.getErrors()[0].getMessage());
        }
        
        Lead insertedLead = 
            [SELECT Id, OwnerId, Email
             FROM Lead
             WHERE Id = :newLead.Id];
        
        return insertedLead;
    }
    
    private static Id getNextOwnerFromRoundRobin() {
        Id ownerId = null;
        List<Group> sdrLeadTrackers = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];
        if (!sdrLeadTrackers.isEmpty()) {
            ownerId = sdrLeadTrackers.get(0).Id;
        }
        return ownerId;
    }
    
    private static Account getClosestMatchingPartnerAccount(String teamId, String companyName) {
        List<Account> partnerAccounts = 
            [SELECT Id, Name, OwnerId 
             FROM Account 
             WHERE Show_Partner_Portal__c = true AND Gearset_Team__r.Gearset_Team_Id__c = :teamId ];
        
        if (partnerAccounts.isEmpty()) {
            LOGGER.info('Unable to get matching SI Account from TeamId {0} to create partner lead.',teamId);
            throw new IllegalArgumentException('Could not get matching SI Account from TeamId ' + teamId);
        }
        
        for (Account account : partnerAccounts) {
            if (account.Name == companyName) {
                return account;
            }
        }

        return partnerAccounts[0];
    }
    
    private static Contact getClosestMatchingPartnerContact(PartnerLeadController.PartnerLeadInfo info, Account partnerAccount) {
        List<Contact> partnerContactsWithMatchingEmail =
            [SELECT Id, FirstName, LastName 
             FROM Contact 
             WHERE AccountId = :partnerAccount.Id AND (Email = :info.referrerEmail OR Email_2__c = :info.referrerEmail OR Email_3__c = :info.referrerEmail)];
        
        if (partnerContactsWithMatchingEmail.isEmpty()) {
            return null;
        }
        
        for (Contact contact : partnerContactsWithMatchingEmail) {
            if (contact.FirstName == info.referrerFirstName && contact.LastName == info.referrerLastName) {
                return contact;
            }
        }
        
        return partnerContactsWithMatchingEmail[0];
    }
}