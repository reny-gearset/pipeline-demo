public without sharing class WebinarLeadService {
    public static final Logger LOGGER = LogFactory.create(WebinarLeadService.class);

    public static Lead createLeadFromWebinarAttendee(zoom_app__Zoom_Webinar_Attendee__c attendee) {
        if (!proceedToCreateLead(attendee)) {
            return null;
        }

        Lead newLead = createLead(attendee);
        if (newLead != null) {
            List<zoom_app__Zoom_Webinar__c> webinars = [ SELECT zoom_app__Actual_End_Time__c FROM zoom_app__Zoom_Webinar__c WHERE Id = :attendee.zoom_app__Zoom_Webinar__c];
            if (webinars.size() > 0) {
                zoom_app__Zoom_Webinar__c webinar = webinars[0];
                // Activity date is the day after the webinar.  We'll use the actual end time not the scheduled end time as the attendees are created after the former not the latter. 
                if (webinar.zoom_app__Actual_End_Time__c != null) {
                    Date webinarEndDate = webinar.zoom_app__Actual_End_Time__c.date();
                    createTaskForLead(newLead, 'registered-webinar-attended', webinarEndDate + 1);
                }
            }

            createCampaignMemberForNewLead(attendee, newLead);
        }

        return newLead;
    }

    private static Lead createLead(zoom_app__Zoom_Webinar_Attendee__c attendee) {
        // There is a trigger which will assign the new Lead to an appropriate SDR if the currently assigned owner is the SDR group.
        Group sdrLeadDistribution = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue' LIMIT 1];
        
        Lead newLead = new Lead(
            Email = attendee.zoom_app__User_Email__c,
            Company = 'DON\'T KNOW', // Zoom attendee object doesn't have company - required so uses same default as for lead import
            OwnerId = sdrLeadDistribution.Id,
            Status = 'New',
            LeadSource = 'Event'
        );
        setName(newLead, attendee);

        try {
           insert newLead;

           // Retrieve the lead and return that as the owner should have been updated by a trigger on insert
           return [SELECT Id, OwnerId, FirstName, LastName, Email FROM Lead WHERE Id = :newLead.Id];
        } catch(Exception e) {
           LOGGER.info('Unable to create Lead for {0}.  Problem: {1}.', newLead.email, e.getMessage());
           return null;
        }
     }

     private static boolean proceedToCreateLead (zoom_app__Zoom_Webinar_Attendee__c attendee) {
        String email = attendee.zoom_app__User_Email__c;

        // We identify users by email, and need a means of contacting them
        if (String.isBlank(email)) {
            return false;
        }

        // We only want to create leads for attendees who aren't already in our system
        if (existsInSystem(email)) {
            return false;
        }

        return true;
     }

    private static boolean existsInSystem(String email) {
        User existingUser = tryGetExistingUser(email);
        if (existingUser != null) {
            return true;
        }

        Contact existingContact = tryGetExistingContact(email);
        if (existingContact != null) {
            return true;
        }

        Lead existingLead = tryGetExistingLead(email);
        if (existingLead != null) {
            return true;
        }

        return false;
    }

    private static User tryGetExistingUser(String email) {
        List<User> existingUsers = [SELECT Id FROM User WHERE Email = :email LIMIT 1];

        if (existingUsers.size() == 1) {
            return existingUsers.get(0);
        }

        return null;
    }

    private static Contact tryGetExistingContact(String email) {
        List<Contact> existingContacts = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];

        if (existingContacts.size() == 1) {
            return existingContacts.get(0);
        }

        return null;
    }

    private static Lead tryGetExistingLead(String email) {
        List<Lead> existingLeads = [ SELECT Id FROM Lead WHERE Email = :email LIMIT 1];

        if (existingLeads.size() == 1) {
            return existingLeads.get(0);
        }

        return null;
    }

    private static void createTaskForLead(Lead lead, String subject, Date taskDate) {
        Task task = new Task(
            Subject = subject,
            Status = 'Open',
            Priority = 'Normal',
            WhoId = lead.Id,
            OwnerId = lead.OwnerId,
            ActivityDate = taskDate
        );

        try {
          insert task;
        } catch(Exception e) {
           LOGGER.info('Unable to create Task for {0}.  Problem: {1}.', lead.Email, e.getMessage());
        }       
    }

    private static void setName(Lead lead, zoom_app__Zoom_Webinar_Attendee__c attendee) {
        // For preference Get the name from the registrant if available as that's in the format we need
        // In unit tests accessing via attendee.zoom_app__Zoom_Webinar_Registrant__r didn't work.  It's also unlikely to in the trigger as :
        // > In a trigger, all fields on the triggering object are available, but no fields on related objects are available, so one of the most common  
        // > Trigger patterns involves collecting related record Ids and querying for them separately from the triggering records. 
        // (https://salesforce.stackexchange.com/a/1889 consulted 19th Feb 2021)
        List<zoom_app__Zoom_Webinar_Registrant__c> registrants = [ SELECT zoom_app__First_Name__c, zoom_app__Last_Name__c  FROM zoom_app__Zoom_Webinar_Registrant__c WHERE Id = :attendee.zoom_app__Zoom_Webinar_Registrant__c];
        if (registrants.size() > 0) {
            zoom_app__Zoom_Webinar_Registrant__c registrant = registrants[0];
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
        String name = attendee.zoom_app__Name__c;
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

    private static void createCampaignMemberForNewLead(zoom_app__Zoom_Webinar_Attendee__c attendee, Lead lead) {
        // WSDL gives relationship as zoom_app__Campaigns__r, so we need to allow for more than one Campaign per webinar
        List<Campaign> campaigns = [ SELECT Id  FROM Campaign WHERE zoom_app__Zoom_Webinar__c = :attendee.zoom_app__Zoom_Webinar__c];
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for(Campaign c : campaigns)
        {
            CampaignMember cm = new CampaignMember(
                CampaignId = c.Id,
                LeadId = lead.Id,
                zoom_app__Is_Registrant__c = attendee.zoom_app__Zoom_Webinar_Registrant__c != null,
                zoom_app__Registrant_Id__c = attendee.zoom_app__Zoom_Webinar_Registrant__c,
                zoom_app__Zoom_Webinar_Registrant__c = attendee.zoom_app__Zoom_Webinar_Registrant__c,
                zoom_app__isPanelist__c = attendee.zoom_app__Zoom_Webinar_Panelist__c != null,
                zoom_app__panelist_Id__c = attendee.zoom_app__Zoom_Webinar_Panelist__c,
                zoom_app__join_time__c = attendee.zoom_app__Join_Time__c,
                zoom_app__leave_time__c = attendee.zoom_app__Leave_Time__c
            );
            campaignMembers.add(cm);
        }
        try {
            insert campaignMembers;                
        } catch(Exception e) {
            LOGGER.info('Unable to create CampaignMembers.  Problem: {0}.', e.getMessage());
        }
    }
}