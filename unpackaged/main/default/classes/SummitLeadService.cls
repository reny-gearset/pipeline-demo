public without sharing class SummitLeadService {
    private class SummitDataException extends Exception {
    }

    public static final Logger LOGGER = LogFactory.create(SummitLeadService.class);

    private static final string SDR_LEAD_DISTRIBUTION_QUEUE = 'SDR Lead Distribution Queue';
    private static final string SDR_ROLE = 'Sales Development Representative';

    public void upsertLeads(SummitLead[] summitData, Id campaignId) {
        Campaign campaign = tryGetCampaign(campaignId);

        if (campaign == null) {
            throw new SummitDataException('Cannot find campaign with ID ' + campaignId);
        }

        if (summitData.size() > 10) {
            throw new SummitDataException('Cannot upsert more than 10 leads at a time');
        }

        Task[] newTasks = new List<Task>();
        Lead[] updatedLeads = new List<Lead>();
        CampaignMember[] newCampaignMembers = new List<CampaignMember>();

        for (SummitLead summitLead : summitData) {
            LOGGER.info(
                'Ingesting {0}. Will check if new lead needs to be created, or if there is an existing lead/contact',
                summitLead.email
            );

            Contact existingContact = tryGetExistingContact(summitLead.email);
            if (existingContact != null) {
                LOGGER.info('Found an existing contact {0} for lead {1}', existingContact.Id, summitLead.email);

                newTasks.Add(createSummitTask(existingContact.Id, existingContact.OwnerId, campaign.Name, summitLead));

                CampaignMember newCampaignMember = createCampaignMember(campaign, existingContact, null);
                if (newCampaignMember != null) {
                    newCampaignMembers.add(newCampaignMember);
                }
            } else {
                Lead lead = tryGetExistingLead(summitLead.email);

                if (lead == null) {
                    LOGGER.info('Creating new lead {0}', summitLead.email);
                    lead = createNewLead(summitLead);
                } else {
                    LOGGER.info('Updating existing lead {0}', summitLead.email);
                    if (updateLead(lead, summitLead)) {
                        updatedLeads.add(lead);
                    }
                }

                newTasks.Add(createSummitTask(lead.Id, lead.OwnerId, campaign.Name, summitLead));

                CampaignMember newCampaignMember = createCampaignMember(campaign, null, lead);
                if (newCampaignMember != null) {
                    newCampaignMembers.add(newCampaignMember);
                }
            }
        }

        if (updatedLeads.size() > 0) {
            update updatedLeads;
        }

        if (newCampaignMembers.size() > 0) {
            insert newCampaignMembers;
        }

        if (newTasks.size() > 0) {
            insert newTasks;
        }
    }

    private Task createSummitTask(Id personId, Id ownerId, string campaignName, SummitLead summitLead) {
        TaskFactory.SummitTaskInfo taskInfo = new TaskFactory.SummitTaskInfo();
        taskInfo.personId = personId;
        taskInfo.ownerId = ownerId;
        taskInfo.campaignName = campaignName;
        taskInfo.email = summitLead.email;
        taskInfo.notes = SummitLead.notes;

        if (summitLead.attended) {
            return TaskFactory.createSummitTask(taskInfo, TaskFactory.SummitTaskType.ATTENDED_SUMMIT);
        } else {
            return TaskFactory.createSummitTask(taskInfo, TaskFactory.SummitTaskType.DID_NOT_ATTEND_SUMMIT);
        }
    }

    private Id getNextOwnerFromRoundRobin() {
        List<Group> sdrLeadTrackers = [SELECT Id FROM Group WHERE Name = :SDR_LEAD_DISTRIBUTION_QUEUE];
        if (!sdrLeadTrackers.isEmpty()) {
            return sdrLeadTrackers.get(0).Id;
        }
        return null;
    }

    private Contact tryGetExistingContact(String email) {
        List<Contact> existingContacts = [SELECT Id, Owner.Id FROM Contact WHERE Email = :email LIMIT 1];

        if (existingContacts.size() == 1) {
            return existingContacts.get(0);
        }

        return null;
    }

    private Campaign tryGetCampaign(Id campaignId) {
        List<Campaign> existingCampaigns = [SELECT Id, Name FROM Campaign WHERE Id = :campaignId LIMIT 1];

        if (existingCampaigns.size() == 1) {
            return existingCampaigns.get(0);
        }

        return null;
    }

    private CampaignMember createCampaignMember(Campaign campaign, Contact contact, Lead lead) {
        if (lead == null && contact == null) {
            return null;
        }

        if (lead != null) {
            CampaignMember[] campaignMembers = [
                SELECT Id
                FROM CampaignMember
                WHERE CampaignId = :campaign.Id AND LeadId = :lead.Id
            ];
            if (campaignMembers.size() > 0) {
                return null;
            }
        } else if (contact != null) {
            CampaignMember[] campaignMembers = [
                SELECT Id
                FROM CampaignMember
                WHERE CampaignId = :campaign.Id AND ContactId = :contact.Id
            ];
            if (campaignMembers.size() > 0) {
                return null;
            }
        }

        CampaignMember member = new CampaignMember(
            CampaignId = campaign.Id,
            LeadId = lead == null ? null : lead.Id,
            ContactId = contact == null ? null : contact.Id
        );

        return member;
    }

    private Lead tryGetExistingLead(String email) {
        List<Lead> existingLeads = [
            SELECT
                Id,
                FirstName,
                LastName,
                Email,
                Phone,
                OwnerId,
                Company,
                Title,
                LeadSource,
                Industry,
                NumberOfEmployees,
                Website
            FROM Lead
            WHERE Email = :email
            LIMIT 1
        ];

        if (existingLeads.size() != 0) {
            return existingLeads.get(0);
        }

        return null;
    }

    private boolean updateLead(Lead existingLead, SummitLead newLead) {
        Boolean haveUpdated = false;
        SignupObjectImpactStatus impact = SignupObjectImpactStatus.NO_IMPACT;

        String firstName = resolveUpdatedStringField(existingLead.FirstName, newLead.FirstName, null);
        if (firstName != existingLead.FirstName) {
            existingLead.FirstName = firstName;
            haveUpdated = true;
        }

        String lastName = resolveUpdatedStringField(
            existingLead.LastName,
            newLead.LastName,
            LeadConstants.DEFAULT_LAST_NAME
        );
        if (lastName != existingLead.LastName) {
            existingLead.LastName = lastName;
            haveUpdated = true;
        }

        String phone = resolveUpdatedStringField(existingLead.Phone, newLead.Phone, null);
        if (phone != existingLead.Phone) {
            existingLead.Phone = phone;
            haveUpdated = true;
        }

        String title = resolveUpdatedStringField(existingLead.Title, newLead.Title, null);
        if (title != existingLead.Title) {
            existingLead.Title = title;
            haveUpdated = true;
        }

        String company = resolveUpdatedStringField(
            existingLead.Company,
            newLead.Company,
            LeadConstants.DEFAULT_COMPANY_NAME
        );
        if (company != existingLead.Company) {
            existingLead.Company = company;
            haveUpdated = true;
        }

        String leadSource = resolveUpdatedStringField(existingLead.LeadSource, null, LeadConstants.EVENT_SOURCE);
        if (leadSource != existingLead.LeadSource) {
            existingLead.LeadSource = leadSource;
            haveUpdated = true;
        }

        String industry = resolveUpdatedStringField(existingLead.Industry, null, LeadConstants.DEFAULT_INDUSTRY);
        if (industry != existingLead.Industry) {
            existingLead.Industry = industry;
            haveUpdated = true;
        }

        String website = resolveUpdatedStringField(existingLead.Website, null, LeadConstants.DEFAULT_WEBSITE);
        if (website != existingLead.Website) {
            existingLead.Website = website;
            haveUpdated = true;
        }

        Integer numberOfEmployees = resolveUpdatedIntegerField(
            existingLead.NumberOfEmployees,
            null,
            LeadConstants.DEFAULT_NUMBER_OF_EMPLOYEES
        );
        if (numberOfEmployees != existingLead.NumberOfEmployees) {
            existingLead.NumberOfEmployees = numberOfEmployees;
            haveUpdated = true;
        }

        return haveUpdated;
    }

    private Lead createNewLead(SummitLead summitLead) {
        string leadSource = LeadConstants.EVENT_SOURCE;
        string lastName = resolveUpdatedStringField(null, summitLead.lastName, LeadConstants.DEFAULT_LAST_NAME);
        string companyName = resolveUpdatedStringField(null, summitLead.company, LeadConstants.DEFAULT_COMPANY_NAME);
        string industry = LeadConstants.DEFAULT_INDUSTRY;
        Integer employees = LeadConstants.DEFAULT_NUMBER_OF_EMPLOYEES;
        string website = LeadConstants.DEFAULT_WEBSITE;

        Lead newLead = new Lead(
            FirstName = summitLead.firstName,
            LastName = lastName,
            Email = summitLead.email,
            Phone = summitLead.phone,
            Company = companyName,
            Industry = industry,
            NumberOfEmployees = employees,
            Website = website,
            OwnerId = getNextOwnerFromRoundRobin(),
            Title = summitLead.title,
            LeadSource = leadSource,
            Status = LeadConstants.READY_FOR_SDR_STATUS
        );

        if (LeadUtilities.isGearsetTestlead(newLead)) {
            newLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
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
        return [SELECT Id, OwnerId, Email FROM Lead WHERE Id = :newLead.Id LIMIT 1];
    }

    private string resolveUpdatedStringField(string existingValue, string newValue, string defaultValue) {
        string newOrDefaultValue = String.isBlank(newValue) ? defaultValue : newValue;
        if (String.isBlank(existingValue) || existingValue == defaultValue) {
            return newOrDefaultValue;
        } else {
            return existingValue;
        }
    }

    private Integer resolveUpdatedIntegerField(Integer existingValue, Integer newValue, Integer defaultValue) {
        Integer newOrDefaultValue = newValue == null || newValue == 0 ? defaultValue : newValue;
        if (existingValue == null || existingValue == 0 || existingValue == defaultValue) {
            return newOrDefaultValue;
        } else {
            return existingValue;
        }
    }
}
