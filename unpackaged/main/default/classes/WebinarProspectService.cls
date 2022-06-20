@SuppressWarnings('PMD.EmptyCatchBlock')
public without sharing class WebinarProspectService {
    private static Group sdrLeadDistribution = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue' LIMIT 1];
    private static UserRole headOfSdrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Head_of_SDR'];
    private static User headOfSdr = [SELECT Id FROM User WHERE UserRoleId = :headOfSdrRole.Id][0];
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];

    public static final Logger LOGGER = LogFactory.create(WebinarProspectService.class);

    // The purpose of this class is to provide an abstraction missing from SF for situations
    // in which we want to treat a Lead and a Contact as the same sort of thing.
    // The name for them collectively was suggested by the Head of SDR.
    private class Prospect {
        Id id;
	    Id leadId;
        Id contactId;
        Id ownerId;
        WebinarAttendeeInformation webinarAttendee;

        public Prospect(Contact contact, WebinarAttendeeInformation webinarAttendee) {
            this.id = contact.Id;
            this.contactId = contact.Id;
            this.ownerId = contact.OwnerId;
            this.webinarAttendee = webinarAttendee;
        }

        public Prospect(Lead lead, WebinarAttendeeInformation webinarAttendee) {
            this.id = lead.Id;
            this.leadId = lead.Id;
            this.ownerId = lead.OwnerId;
            this.webinarAttendee = webinarAttendee;
        }
   	}

    public static void processWebinarAttendees(List<WebinarAttendeeInformation> attendees) {
        List<Prospect> prospects = getProspects(attendees);
        List<Task> tasks = new List<Task>();
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for(Prospect p : prospects) {
            tasks.addAll(createTaskForProspect(p.id, p.ownerId, 'registered-webinar-attended', p.webinarAttendee));
            campaignMembers.addAll(createCampaignMemberForProspect(p.webinarAttendee, p.leadId, p.contactId));
        }
        insert tasks;
        insert campaignMembers;
    }

    private static List<Prospect> getProspects(List<WebinarAttendeeInformation> attendees) {
        List<WebinarAttendeeInformation> unknownAttendeeInformation = new List<WebinarAttendeeInformation>();
        List<Prospect> prospects = new List<Prospect>();
        List<Prospect> prospectsWithDefaultOwner = new List<Prospect>();
        List<ID> defaultOwnerProspectLeadIds = new List<ID>();

        for(WebinarAttendeeInformation attendee : attendees) {
            if (!proceedWithProcessingAttendee(attendee)) {
                continue;
            }

            Prospect p = tryGetProspect(attendee);
            if (p == null) {
                // Attendee isn't in our system as a Lead or Contact, so we want to create a Lead for them
                unknownAttendeeInformation.add(attendee);
            }
            else {
            	prospects.add(p);
            }
        }

        List<WebinarAttendeeInformation> newToUsAttendeeInformation = getNewToUsAttendeeInformation(unknownAttendeeInformation);
        // Repeat the process for the attendees who weren't in our system on the first sweep.
        for (WebinarAttendeeInformation a : newToUsAttendeeInformation) {
            Prospect p = tryGetProspect(a);
            if (p != null) {
            	prospects.add(p);
            }
        }

        for (Prospect p : prospects) {
            if (p.ownerId == sdrLeadDistribution.Id) {
                prospectsWithDefaultOwner.add(p);
                defaultOwnerProspectLeadIds.add(p.leadId); // I hate having to have the extra list, but Apex doesn't have a LINQ equivalent
            }
        }
        setOwnerIds(prospectsWithDefaultOwner, defaultOwnerProspectLeadIds);
        return prospects;
    }

    private static void setOwnerIds(List<Prospect> prospects, List<ID> leadIds) {
        Map<Id, Lead> leadOwnerInfo = new Map<Id, Lead>([SELECT Id, OwnerId FROM Lead WHERE Id IN :leadIds]);
        for(Prospect p : prospects ) {
            Lead l = leadOwnerInfo.get(p.leadId);
            if (l != null) {
                p.ownerId = l.OwnerId;
            }
        }
    }

    private static Prospect tryGetProspect(WebinarAttendeeInformation attendee) {
        if (attendee.contactRecordByPrimaryEmail != null) {
            return new Prospect(attendee.contactRecordByPrimaryEmail, attendee);
        }

        Lead l = attendee.leadRecord;
        if (attendee.leadRecord != null) {
            return new Prospect(l, attendee);
        }

        return null;
    }

    private static List<WebinarAttendeeInformation> getNewToUsAttendeeInformation(List<WebinarAttendeeInformation> unknownAttendees){
        // We need to create all new Leads in one go otherwise a trigger on lead creation hits the governor limits.
        List<Lead> leadsToAdd = new List<Lead>();
        Set<String> emails = new Set<String>();
        for (WebinarAttendeeInformation a : unknownAttendees) {
            Lead l = createLead(a);
            if (leadCanBeSaved(l, emails)) { // As we're saving in a batch we can't catch individual failures
                leadsToAdd.add(l);
                emails.add(a.webinarAttendeeRecord.zoom_app__User_Email__c);                
            }
        }
        insert leadsToAdd;

        // Once we've created the Leads we need to get up-to-date attendee information.
        // We can't just rerun getWebinarAttendeeInformation because we'll hit governor limits
        Map<String, Lead> newLeads = WebinarAttendeeInformationService.getExistingLeads(emails);
        for (WebinarAttendeeInformation a : unknownAttendees) {
            a.leadRecord = newLeads.get(a.webinarAttendeeRecord.zoom_app__User_Email__c);
        }
        return unknownAttendees;
    }

    private static boolean proceedWithProcessingAttendee (WebinarAttendeeInformation attendee) {
        String email = attendee.webinarAttendeeRecord.zoom_app__User_Email__c;

        // We identify users by email, and need a means of contacting them
        if (String.isBlank(email)) {
            return false;
        }

        if (attendee.userRecord != null) {
            return false;
        }

        return true;
    }

    private static Lead createLead(WebinarAttendeeInformation attendee) {
        Lead newLead = new Lead(
            Email = attendee.webinarAttendeeRecord.zoom_app__User_Email__c,
            Company = 'DON\'T KNOW', // Zoom attendee object doesn't have company - required so uses same default as for lead import
            OwnerId = sdrLeadDistribution.Id, // There is a trigger which will assign the new Lead to an appropriate SDR if the currently assigned owner is the SDR group.
            Status = 'New',
            LeadSource = 'Event'
        );
        setName(newLead, attendee);

        if (LeadUtilities.isGearsetTestlead(newLead)) {
            newLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
        }

        return newLead;
     }
    
    private static boolean leadCanBeSaved(Lead l, Set<String> existingLeadEmails) {
        if (existingLeadEmails.contains(l.Email)) {
            return false; // Duplicate
        }
        if (l.LastName == null) {
            return false; // LastName is required
        }
        return true;
    }

    // By 'Prospect' I really mean contact with a small 'c', but that would get confused with Contact
    private static List<Task> createTaskForProspect(ID prospectId, ID ownerId, String subject, WebinarAttendeeInformation attendee) {
        List<Task> tasks = new List<Task>();

        // We'll use the actual end time not the scheduled end time as the attendees are created after the former not the latter. 
        Date taskDate = null;
        zoom_app__Zoom_Webinar__c webinar = attendee.webinarRecord;
        if (webinar != null && webinar.zoom_app__Actual_End_Time__c != null) {
            Date webinarEndDate = webinar.zoom_app__Actual_End_Time__c.date();
            taskDate = webinarEndDate + 1; // Activity date is the day after the webinar. 
        }
        if (taskDate == null) {
            return tasks;
        }

        Task task = new Task(
            Subject = subject,
            Status = 'Open',
            Priority = 'Normal',
            WhoId = prospectId,
            OwnerId = ownerId,
            ActivityDate = taskDate
        );
        tasks.add(task);

        if (ownerId == gearbot.Id) {
            Task assignmentTask = new Task(
                Subject = 'Assign webinar attendee SDR or BDR owner',
                Status = 'Open',
                Priority = 'Normal',
                WhoId = prospectId,
                OwnerId = headOfSdr.Id,
                ActivityDate = taskDate
            );
            tasks.add(assignmentTask);
        }
        
        return tasks;    
    }

    private static void setName(Lead lead, WebinarAttendeeInformation attendee) {
        zoom_app__Zoom_Webinar_Registrant__c registrant = attendee.webinarRegistrantRecord;
        // For preference Get the name from the registrant if available as that's in the format we need
        if (registrant != null) { // Not all webinars require registration
            if (registrant.zoom_app__Last_Name__c != null) {
                lead.LastName = registrant.zoom_app__Last_Name__c;
                lead.FirstName = registrant.zoom_app__First_Name__c;
                return;
            }
            if (registrant.zoom_app__First_Name__c != null) {
                lead.LastName = registrant.zoom_app__First_Name__c; // LastName is a required field so if we haven't got one use the first name instead
                return;
            }
            return;
        }

        // But if we can't get it from there, try the name info from the attendee instead.
        String name = attendee.webinarAttendeeRecord.zoom_app__Name__c;
        if (String.isBlank(name)) {
            return;
        }

        String[] names = name.split(' ');
        if (names.size() < 2) {
            lead.LastName = name; // Salesforce requires a LastName, so use what we've been given
            return;
        }

        lead.LastName = names[names.size() - 1];
        lead.FirstName = names[0];
    }

    // CampaignMember must have a LeadId OR a ContactId, but cannot have both at the point of creation.
    // - If neither are specified, it will throw REQUIRED_FIELD_MISSING
    // - If both are specified, it will populate the ContactId only
    // See https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_campaignmember.htm
    // WSDL gives relationship as zoom_app__Campaigns__r, so we need to allow for more than one Campaign per webinar
    private static List<CampaignMember> createCampaignMemberForProspect(WebinarAttendeeInformation attendee, ID leadId, ID contactId) {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        if (attendee.campaignRecords == null) {
            return campaignMembers;
        }
        for(Campaign c : attendee.campaignRecords)
        {
            CampaignMember cm = new CampaignMember(
                CampaignId = c.Id,
                LeadId = leadId,
                ContactId = contactId,
                zoom_app__Is_Registrant__c = attendee.webinarAttendeeRecord.zoom_app__Zoom_Webinar_Registrant__c != null,
                zoom_app__Registrant_Id__c = attendee.webinarAttendeeRecord.zoom_app__Zoom_Webinar_Registrant__c,
                zoom_app__Zoom_Webinar_Registrant__c = attendee.webinarAttendeeRecord.zoom_app__Zoom_Webinar_Registrant__c,
                zoom_app__isPanelist__c = attendee.webinarAttendeeRecord.zoom_app__Zoom_Webinar_Panelist__c != null,
                zoom_app__panelist_Id__c = attendee.webinarAttendeeRecord.zoom_app__Zoom_Webinar_Panelist__c,
                zoom_app__join_time__c = attendee.webinarAttendeeRecord.zoom_app__Join_Time__c,
                zoom_app__leave_time__c = attendee.webinarAttendeeRecord.zoom_app__Leave_Time__c
            );
            try {
                campaignMembers.add(cm);
            } catch(DmlException e)
            {
            }
        }
        return campaignMembers;
    }
}