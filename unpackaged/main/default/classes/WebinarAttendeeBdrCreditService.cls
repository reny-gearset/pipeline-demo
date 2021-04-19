public without sharing class WebinarAttendeeBdrCreditService {
    // BDRs must create an Event associated with the Contact and Campaign to get credit for their contact's attendance
    public static void recordAttendanceInBdrEvent(zoom_app__Zoom_Webinar_Attendee__c attendee) {
        String email = attendee.zoom_app__User_Email__c;

        Contact attendeeContact = findFirstContactForAttendee(attendee);

        if (attendeeContact == null) {
            // this attendee is not a Contact
            return;
        }

        // WSDL gives relationship as zoom_app__Campaigns__r, so we need to allow for more than one Campaign per webinar
        List<Campaign> webinarCampaigns = [ SELECT Id FROM Campaign WHERE zoom_app__Zoom_Webinar__c = :attendee.zoom_app__Zoom_Webinar__c ];
        List<String> campaignIds = new List<String>();
        for (Campaign campaign : webinarCampaigns) {
            campaignIds.Add(campaign.Id);
        }

        List<Event> matchingContactAttendsWebinarEvents = [ SELECT Id, Attended__c FROM Event WHERE Subject = 'Webinar' AND WhatId IN :campaignIds AND WhoId = :attendeeContact.Id ORDER BY CreatedDate ASC ];

        if (matchingContactAttendsWebinarEvents.size() == 0) {
            return;
        }

        // if more than one event has been created for this contact's attendance we only want to credit whoever got there first
        Event eventCreatedEarliest = matchingContactAttendsWebinarEvents[0];

        eventCreatedEarliest.Attended__c = true;
        update eventCreatedEarliest;
    }

    private static Contact findFirstContactForAttendee(zoom_app__Zoom_Webinar_Attendee__c attendee) {
        // favour matching by primary email
        List<Contact> contactsByPrimaryEmail = [ SELECT Id FROM Contact WHERE Email = :attendee.zoom_app__User_Email__c ];

        if (contactsByPrimaryEmail.size() > 0) {
            return contactsByPrimaryEmail[0];
        } else {
            List<Contact> contactsByOtherEmail = [ SELECT Id FROM Contact WHERE Email_2__c = :attendee.zoom_app__User_Email__c OR Email_3__c = :attendee.zoom_app__User_Email__c ];

            if (contactsByOtherEmail.size() > 0) {
                return contactsByOtherEmail[0];
            } else {
                // this attendee is not a Contact
                return null;
            }
        }
    }
}