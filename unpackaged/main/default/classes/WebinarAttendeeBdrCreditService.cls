public without sharing class WebinarAttendeeBdrCreditService {
    // BDRs must create an Event associated with the Contact and Campaign to get credit for their contact's attendance
    public static void recordAttendanceInBdrEvent(WebinarAttendeeInformation attendee) {
        Contact attendeeContact = findFirstContactForAttendee(attendee);

        if (attendeeContact == null) {
            // this attendee is not a Contact
            return;
        }

        if (attendee.eventRecords.size() == 0) {
            return;
        }

        // if more than one event has been created for this contact's attendance we only want to credit whoever got there first
        // It's a faff to implement custom list sorting in Apex, so just do it manually.
        Event eventCreatedEarliest = attendee.eventRecords[0];
        for (Event currentEvent : attendee.eventRecords) {
            if (currentEvent.CreatedDate < eventCreatedEarliest.CreatedDate) {
                eventCreatedEarliest = currentEvent;
            }            
        }

        eventCreatedEarliest.Attended__c = true;
        update eventCreatedEarliest;
    }

    private static Contact findFirstContactForAttendee(WebinarAttendeeInformation attendee) {
        // favour matching by primary email
        if (attendee.contactRecordByPrimaryEmail != null) {
            return attendee.contactRecordByPrimaryEmail;
        } else {
            if (attendee.contactRecordByOtherEmail != null) {
                return attendee.contactRecordByOtherEmail;
            } else {
                // this attendee is not a Contact
                return null;
            }
        }
    }
}