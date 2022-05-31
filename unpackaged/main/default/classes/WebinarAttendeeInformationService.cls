public without sharing class WebinarAttendeeInformationService {
    // We need to do all our fetching once per trigger to avoid hitting governor limits
    public static List<WebinarAttendeeInformation> getWebinarAttendeeInformation(List<zoom_app__Zoom_Webinar_Attendee__c> attendees) {
        Set<ID> webinarIds = new Set<ID>(); // In case the inserted attendees may relate to more than one webinar
        Set<ID> registrantIds = new Set<ID>();
        Set<String> attendeeEmails = new Set<String>(); // We have to go through all the attendees anyway, so we might as well get the email
                                                          //    and use it to restrict lists we have to search through
        
        for(zoom_app__Zoom_Webinar_Attendee__c attendee : attendees) {
            webinarIds.add(attendee.zoom_app__Zoom_Webinar__c);
            if(attendee.zoom_app__Zoom_Webinar_Registrant__c != null) {
                registrantIds.add(attendee.zoom_app__Zoom_Webinar_Registrant__c);
            }
            
            if (String.isBlank(attendee.zoom_app__User_Email__c)) {
               continue; // We need an email to look for them in our system
            }
            attendeeEmails.add(attendee.zoom_app__User_Email__c);
        }

        // TLDR; Get the related records for the attendees
        // In unit tests accessing via attendee.zoom_app__Zoom_Webinar_Registrant__r didn't work.  It's also unlikely to in the trigger as :
        // > In a trigger, all fields on the triggering object are available, but no fields on related objects are available, so one of the most common  
        // > Trigger patterns involves collecting related record Ids and querying for them separately from the triggering records. 
        // (https://salesforce.stackexchange.com/a/1889 consulted 19th Feb 2021)
        Map<ID, zoom_app__Zoom_Webinar_Registrant__c> registrants = new Map<ID, zoom_app__Zoom_Webinar_Registrant__c>([ SELECT zoom_app__First_Name__c, zoom_app__Last_Name__c  FROM zoom_app__Zoom_Webinar_Registrant__c WHERE Id IN :registrantIds]);
        Map<ID, zoom_app__Zoom_Webinar__c> webinars = new Map<ID, zoom_app__Zoom_Webinar__c>([ SELECT zoom_app__Actual_End_Time__c FROM zoom_app__Zoom_Webinar__c WHERE Id IN :webinarIds]);

        Map<String, User> attendingUsersByEmail = getExistingUsers(attendeeEmails);
        Map<String, Contact> attendingContactsByPrimaryEmail = getExistingContactsByPrimaryEmail(attendeeEmails);
        Map<String, Contact> attendingContactsByOtherEmail = getExistingContactsByOtherEmail(attendeeEmails);
        Map<String, Lead> attendingLeadsByEmail = getExistingLeads(attendeeEmails);

        Map<Id, List<Campaign>> campaignsByWebinar = getCampaignsByWebinar(webinarIds);
        Map<Id, List<Event>> eventsByContact = getEventsByContactId(webinarIds);
        
        List<WebinarAttendeeInformation> attendeeInformation = new List<WebinarAttendeeInformation>();
        for(zoom_app__Zoom_Webinar_Attendee__c attendee : attendees) {
            User attendingUser = attendingUsersByEmail.get(attendee.zoom_app__User_Email__c);
            Contact attendingContactByPrimaryEmail = attendingContactsByPrimaryEmail.get(attendee.zoom_app__User_Email__c);
            Contact attendingContactByOtherEmail = attendingContactsByOtherEmail.get(attendee.zoom_app__User_Email__c);
            Lead attendingLead = attendingLeadsByEmail.get(attendee.zoom_app__User_Email__c);
            zoom_app__Zoom_Webinar_Registrant__c registrant = registrants.get(attendee.zoom_app__Zoom_Webinar_Registrant__c);
            zoom_app__Zoom_Webinar__c webinar = webinars.get(attendee.zoom_app__Zoom_Webinar__c);
            List<Campaign> webinarCampaigns = campaignsByWebinar.get(attendee.zoom_app__Zoom_Webinar__c);
            List<Event> webinarEvents = getWebinarEventsForAttendee(eventsByContact, webinarCampaigns, attendingContactByPrimaryEmail, attendingContactByOtherEmail);
            WebinarAttendeeInformation info = new WebinarAttendeeInformation(attendingUser,
                                                                            attendingContactByPrimaryEmail,
                                                                            attendingContactByOtherEmail,
                                                                            attendingLead,
                                                                            attendee,
                                                                            registrant,
                                                                            webinar,
                                                                            webinarCampaigns,
                                                                            webinarEvents);
            attendeeInformation.add(info);
        }
        return attendeeInformation;
    }

    private static Map<Id, List<Campaign>> getCampaignsByWebinar(Set<ID> webinarIds) {
        Map<Id, List<Campaign>> campaignsByWebinar = new Map<Id, List<Campaign>>();
        List<Campaign> campaigns = [ SELECT Id, zoom_app__Zoom_Webinar__c FROM Campaign WHERE zoom_app__Zoom_Webinar__c IN :webinarIds];
        for(Campaign c : campaigns) {
            if(campaignsByWebinar.containsKey(c.zoom_app__Zoom_Webinar__c)){
                campaignsByWebinar.get(c.zoom_app__Zoom_Webinar__c).add(c);
            }
            else {
                campaignsByWebinar.put(c.zoom_app__Zoom_Webinar__c, new List<Campaign> { c });
            }
        }
        return campaignsByWebinar;
    }

    private static Map<ID, List<Event>> getEventsByContactId(Set<ID> webinarIds) {
        Map<ID, List<Event>> eventsByContactId = new Map<ID, List<Event>>();

        Map<ID, Campaign> campaigns = new Map<ID, Campaign>([ SELECT Id FROM Campaign WHERE zoom_app__Zoom_Webinar__c IN :webinarIds]);
        Set<ID> campaignIds = campaigns.keySet();

        List<Event> events = [ SELECT Id, WhoId, WhatId FROM Event WHERE Subject = 'Webinar' AND WhatId IN :campaignIds ];
        for(Event e : events) {
            if(eventsByContactId.containsKey(e.WhoId)){
                eventsByContactId.get(e.WhoId).add(e);
            }
            else {
                eventsByContactId.put(e.WhoId, new List<Event> { e });
            }
        }
        return eventsByContactId;
    }

    private static List<Event> getWebinarEventsForAttendee(Map<ID, List<Event>> eventsByContact, List<Campaign> campaigns, Contact attendingContactByPrimaryEmail, Contact attendingContactByOtherEmail) {
        List<Event> result = new List<Event>();
        if(campaigns == null) {
            return result;
        }

        Set<ID> campaignIds = new Set<ID>();
        for (Campaign c : campaigns) {
            campaignIds.add(c.Id);
        }
        
        List<Event> contactEvents = new List<Event>();
        if (attendingContactByPrimaryEmail != null) {
            List<Event> eventsToAdd = eventsByContact.get(attendingContactByPrimaryEmail.Id);
            if(eventsToAdd != null) {
                contactEvents.addAll(eventsToAdd);
            }            
        }
        if (attendingContactByOtherEmail != null) {
            List<Event> eventsToAdd = eventsByContact.get(attendingContactByOtherEmail.Id);
            if(eventsToAdd != null) {
                contactEvents.addAll(eventsToAdd);
            }
        }
        for(Event e : contactEvents) {
            if (campaignIds.contains(e.WhatId)) {
                result.add(e);
            }
        }

        return result;
    }

    private static Map<String, User> getExistingUsers(Set<String> emails) {
        Map<String, User> userMap = new Map<String, User>();
        List<User> users = [SELECT Id, Email FROM User WHERE Email IN :emails];
        for(User u : users) {
            userMap.put(u.Email, u);
        }
        return userMap;
    }

    private static Map<String, Contact> getExistingContactsByPrimaryEmail(Set<String> emails) {
        Map<String, Contact> contactMap = new Map<String, Contact>();
        List<Contact> contacts = [SELECT Id, OwnerId, Email FROM Contact WHERE Email IN :emails];
        for(Contact c : contacts) {
            contactMap.put(c.Email, c);
        }
        return contactMap;
    } 

    private static Map<String, Contact> getExistingContactsByOtherEmail(Set<String> emails) {
        Map<String, Contact> contactMap = new Map<String, Contact>();
        List<Contact> contacts = [ SELECT Id, Email_2__c, Email_3__c FROM Contact WHERE Email_2__c IN :emails OR Email_3__c IN :emails ];
        for(Contact c : contacts) {
            if (c.Email_2__c != null && emails.contains(c.Email_2__c) && !contactMap.containsKey(c.Email_2__c)) {
                contactMap.put(c.Email_2__c, c);
            }
            else if (c.Email_3__c != null && emails.contains(c.Email_3__c) && !contactMap.containsKey(c.Email_3__c)) {
                contactMap.put(c.Email_3__c, c);
            }
        }
        return contactMap;
    } 

    public static Map<String, Lead> getExistingLeads(Set<String> emails) {
        Map<String, Lead> leadMap = new Map<String, Lead>();
        List<Lead> leads = [SELECT Id, OwnerId, Email FROM Lead WHERE Email IN :emails];
        for(Lead l : leads) {
            leadMap.put(l.Email, l);
        }
        return leadMap;
    }
}