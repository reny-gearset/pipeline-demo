@RestResource(urlMapping='/PartnerLead')
global with sharing class PartnerLeadController {
    private static final Logger LOGGER = LogFactory.create(PartnerLeadController.class);
    
    @HttpPost
    global static Boolean createPartnerReferralLead(PartnerLeadInfo info) {
        Account partnerAccount = getClosestMatchingPartnerAccount(info);
        Contact partnerContact = getClosestMatchingPartnerContact(info, partnerAccount);
        
        handlePartnerReferralLead(info, partnerAccount, partnerContact);
        
        return true;
    }
    
    global class PartnerLeadInfo {
        global String contactCompanyName;
        global String contactEmail;
        global String contactFirstName;
        global String contactLastName;
        global String referrerCompanyName;
        global String referrerEmail;
        global String referrerFirstName;
        global String referrerLastName;
        global String extraDetails;
        global String teamId;
    }
    
    private static void handlePartnerReferralLead(PartnerLeadInfo info, Account partnerAccount, Contact partnerContact) {
        Lead partnerReferralLead = createPartnerReferralLead(info, partnerAccount, partnerContact);
        
        createTaskForPartnerReferralLead(partnerReferralLead);
    }
    
    private static void createTaskForPartnerReferralLead(Lead partnerReferralLead) {
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
    
    private static Lead createPartnerReferralLead(PartnerLeadInfo info, Account partnerAccount, Contact partnerContact) {
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
    
    private static Account getClosestMatchingPartnerAccount(PartnerLeadInfo info) {
        List<Account> partnerAccounts = 
            [SELECT Id, Name 
             FROM Account 
             WHERE Type = 'Implementation Partner' AND Gearset_Team__r.Gearset_Team_Id__c = :info.teamId ];
        
        if (partnerAccounts.isEmpty()) {
            LOGGER.info('Unable to get matching SI Account from TeamId {0} to create partner lead.', info.teamId);
            throw new IllegalArgumentException('Could not get matching SI Account from TeamId ' + info.teamId);
        }
        
        for (Account account : partnerAccounts) {
            if (account.Name == info.referrerCompanyName) {
                return account;
            }
        }

        return partnerAccounts[0];
    }
    
    private static Contact getClosestMatchingPartnerContact(PartnerLeadInfo info, Account partnerAccount) {
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