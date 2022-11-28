@isTest
private class TestWebinarAttendeeBdrCreditService {

    @isTest
    public static void shouldRecordAttendanceIfBdrEventExists() {
        WebinarAttendee attendee = createWebinarAttendee();

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert event;

        WebinarAttendeeInformation attendeeInfo = new WebinarAttendeeInformation(null, attendee.contact, null, null, attendee.attendee, null, attendee.webinar, new List<Campaign> { attendee.campaign }, new List<Event> { event });
        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendeeInfo);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event ];

        System.assertEquals(event.Id, actualEvent.Id);
        System.assertEquals(true, actualEvent.Attended__c);
    }

    @isTest
    public static void shouldRecordAttendanceInTheEarliestEventIfThereAreTwo() {
        WebinarAttendee attendee = createWebinarAttendee();

        Event eventCreatedFourDaysAgo = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert eventCreatedFourDaysAgo;
        Test.setCreatedDate(eventCreatedFourDaysAgo.Id, DateTime.now().AddDays(-4));
        eventCreatedFourDaysAgo = [ SELECT Id, CreatedDate FROM Event WHERE Id = :eventCreatedFourDaysAgo.Id]; // Note: need to query the record back as setCreatedDate works on the stored record

        Event eventCreatedOneDayAgo = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert eventCreatedOneDayAgo;
        Test.setCreatedDate(eventCreatedOneDayAgo.Id, DateTime.now().AddDays(-1));
		eventCreatedOneDayAgo = [ SELECT Id, CreatedDate FROM Event WHERE Id = :eventCreatedOneDayAgo.Id]; 

        WebinarAttendeeInformation attendeeInfo = new WebinarAttendeeInformation(null, attendee.contact, null, null, attendee.attendee, null, attendee.webinar, new List<Campaign> { attendee.campaign }, new List<Event> { eventCreatedOneDayAgo, eventCreatedFourDaysAgo });
        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendeeInfo);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event WHERE Attended__c = true ];

        System.assertEquals(eventCreatedFourDaysAgo.Id, actualEvent.Id);
    }

    private static WebinarAttendee createWebinarAttendee() {
        String email = 'email@example.com';

        zoom_app__Zoom_Webinar__c w = new zoom_app__Zoom_Webinar__c();
        w.zoom_app__Start_Time__c = DateTime.now() - 10;
        w.zoom_app__Duration__c = 10;
        w.zoom_app__Topic__c = 'Test';
        insert w;

        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = email;
        a.zoom_app__Name__c = 'Test';
        a.zoom_app__Zoom_Webinar__c = w.Id;

        Campaign campaign = new Campaign();
        campaign.Name = 'Campaign 1';
        campaign.zoom_app__Zoom_Webinar__c = w.Id;
        insert campaign;

        Contact contact = new Contact(
            FirstName = 'Firstname',
            LastName = 'Contact',
            Email = email
        );
        insert contact;

        WebinarAttendee result = new WebinarAttendee();
        result.attendee = a;
        result.webinar = w;
        result.contact = contact;
        result.campaign = campaign;

        return result;
    }

    private class WebinarAttendee {
        zoom_app__Zoom_Webinar_Attendee__c attendee;
        zoom_app__Zoom_Webinar__c webinar;
        Contact contact;
        Campaign campaign;
    }
}