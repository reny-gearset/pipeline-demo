public with sharing class MarketingLeadService {
    private static final Logger LOGGER = LogFactory.create(MarketingLeadService.class);

    private static final User GEARBOT = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
    
    Map<String, String> marketingSourceTaskSubjectMap = new Map<String, String>{'devops-assessment' => 'Completed devops assesssment'};
    
    private static Set<String> sdrAssignedSources = new Set<String>{'devops-assessment'};

    public String upsertLead(SalesforceMarketingLead marketingLead) {
        if (
            String.isBlank(marketingLead.source) ||
            String.isBlank(marketingLead.company) ||
            String.isBlank(marketingLead.surname)
        ) {
            throw new IllegalArgumentException(
                'Marketing leads must have a source, company, and lastname parameter for tracking'
            );
        }

        Contact contact = tryGetExistingContact(marketingLead.email);
        if (contact != null) {
            createTask(contact.Id, contact.OwnerId, marketingLead.source);
        }

        // Get an existing lead, or create one if we don't have a contact
        Lead lead = getOrCreateLeadIfRequired(contact, marketingLead);
        if (lead != null) {
            createTask(lead.Id, lead.OwnerId, marketingLead.source);
        }

        Campaign campaign = tryGetCampaign(marketingLead.source);
        if (campaign == null) {
            LOGGER.info('Unable to find campaign for {0}', marketingLead.source);
            return lead == null ? contact.Id : lead.Id;
        }

        return upsertCampaignMember(campaign, marketingLead, contact, lead);
    }

    private Id upsertCampaignMember(
        Campaign campaign,
        SalesforceMarketingLead marketingLead,
        Contact contact,
        Lead lead
    ) {
        CampaignMember member = new CampaignMember(
            CampaignId = campaign.Id,
            LeadId = lead == null ? null : lead.Id,
            ContactId = contact == null ? null : contact.Id
        );

        upsert member;

        return member.Id;
    }

    private void createTask(Id whoId, Id ownerId, String source) {
        String subject = 'Content Interaction: ';
        if (marketingSourceTaskSubjectMap.containsKey(source)) {
            subject += marketingSourceTaskSubjectMap.get(source);
        } else {
            subject += source;
        }
        
        Task task = new Task(
            Subject = subject,
            Status = 'Completed',
            Priority = 'Normal',
            WhoId = whoId,
            OwnerId = ownerId,
            ActivityDate = date.today(),
            Description = subject
        );

        insert task;
    }

    private Contact tryGetExistingContact(String email) {
        List<Contact> existingContacts = [SELECT Id, OwnerId, Name FROM Contact WHERE Email = :email LIMIT 1];

        if (existingContacts.size() == 1) {
            return existingContacts.get(0);
        }

        return null;
    }

    private Lead getOrCreateLeadIfRequired(Contact contact, SalesforceMarketingLead marketingLead) {
        Boolean sdrAssignedSource = sdrAssignedSources.contains(marketingLead.source);
        
        List<Lead> existingLeads = [
            SELECT Id, Email, Phone, OwnerId
            FROM Lead
            WHERE Email = :marketingLead.email
            LIMIT 1
        ];

        if (existingLeads.size() == 1) {
            Lead existingLead = existingLeads.get(0);
            if (sdrAssignedSource && existingLead.OwnerId == GEARBOT.Id) {
                existingLead.OwnerId = getNextOwnerFromRoundRobin();
                existingLead.Status = 'Ready for SDR';
                update existingLead;
                existingLead = 
                    [SELECT Id, OwnerId
                     FROM Lead
                     WHERE Id = :existingLead.Id];
            }
            
            return existingLead;
        }

        if (contact != null) {
            return null;
        }

        Lead newLead = new Lead(
            FirstName = marketingLead.firstName,
            LastName = marketingLead.surname,
            Email = marketingLead.email,
            Company = marketingLead.company,
            Phone = marketingLead.phoneNumber,
            Industry = marketingLead.industry,
            LeadSource = 'Content',
            NumberOfEmployees = marketingLead.companySize,
            Discovery_notes__c = marketingLead.discoveryNotes
        );
        
        if (LeadUtilities.isGearsetTestlead(newLead)) {
            newLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
        }
        else {
            if (sdrAssignedSource) {
                newLead.Status = 'Ready for SDR';
                newLead.OwnerId = getNextOwnerFromRoundRobin();
            } else {
                newLead.Lost_reason__c = 'Not ready yet';
                newLead.Status = 'Lost';
                newLead.OwnerId = GEARBOT.Id;
            }
        }

        insert newLead;
        
        Lead insertedLead = 
            [SELECT Id, OwnerId
             FROM Lead
             WHERE Id = :newLead.Id];
        
        return insertedLead;
    }

    private Campaign tryGetCampaign(String source) {
        List<Campaign> campaigns = [SELECT Id, Source__c FROM Campaign WHERE Source__c = :source];

        if (campaigns.size() == 0) {
            LOGGER.info('No campaigns found for {0}', source);
            return null;
        }

        if (campaigns.size() > 1) {
            // TODO: Can I write a trigger on Campign to prevent this? Maybe it shouldn't be a picklist
            LOGGER.info('Too many campaigns for {0}', source);
            return null;
        }

        return campaigns.get(0);
    }
    
    private static Id getNextOwnerFromRoundRobin() {          
        List<Group> sdrLeadTrackers = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'];
        if (!sdrLeadTrackers.isEmpty()) {
            return sdrLeadTrackers.get(0).Id;
        }
        return null;
    } 
}