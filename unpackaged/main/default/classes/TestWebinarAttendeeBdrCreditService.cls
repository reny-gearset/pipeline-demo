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

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event ];

        System.assertEquals(event.Id, actualEvent.Id);
        System.assertEquals(true, actualEvent.Attended__c);
    }

    @isTest
    public static void shouldNotRecordAttendanceIfEventSubjectIsNotWebinar() {
        WebinarAttendee attendee = createWebinarAttendee();

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Demo',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert event;

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event ];

        System.assertEquals(event.Id, actualEvent.Id);
        System.assertEquals(false, actualEvent.Attended__c);
    }

    @isTest
    public static void shouldNotRecordAttendanceIfContactEmailDoesNotMatch() {
        WebinarAttendee attendee = createWebinarAttendee();

        // change the email address of the contact so it doesn't match the attendee
        attendee.contact.Email = 'not.' + attendee.attendee.zoom_app__User_Email__c;
        update attendee.contact;

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert event;

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event ];

        System.assertEquals(event.Id, actualEvent.Id);
        System.assertEquals(false, actualEvent.Attended__c);
    }

    @isTest
    public static void shouldNotRecordAttendanceIfCampaignIsNotLinkedToAnyWebinar() {
        WebinarAttendee attendee = createWebinarAttendee();

        // break the association between the Campaign and the webinar
        attendee.campaign.zoom_app__Zoom_Webinar__c = null;
        update attendee.campaign;

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert event;

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event ];

        System.assertEquals(event.Id, actualEvent.Id);
        System.assertEquals(false, actualEvent.Attended__c);
    }

    @isTest
    public static void shouldNotRecordAttendanceIfCampaignIsLinkedToAnotherWebinar() {
        WebinarAttendee attendee = createWebinarAttendee();

        zoom_app__Zoom_Webinar__c otherWebinar = new zoom_app__Zoom_Webinar__c();
        otherWebinar.zoom_app__Start_Time__c = DateTime.now() - 10;
        otherWebinar.zoom_app__Duration__c = 10;
        otherWebinar.zoom_app__Topic__c = 'Test 2';
        insert otherWebinar;

        // associate campaign with the other webinar
        attendee.campaign.zoom_app__Zoom_Webinar__c = otherWebinar.Id;
        update attendee.campaign;

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert event;

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

        Event actualEvent = [ SELECT Id,Attended__c FROM Event ];

        System.assertEquals(event.Id, actualEvent.Id);
        System.assertEquals(false, actualEvent.Attended__c);
    }

    @isTest
    public static void shouldRecordAttendanceIfBdrEventReferencesOneOfTheTwoCampaignsForTheWebinar() {
        WebinarAttendee attendee = createWebinarAttendee();

        Campaign otherCampaign = new Campaign();
        otherCampaign.Name = 'Campaign 2';
        otherCampaign.zoom_app__Zoom_Webinar__c = attendee.webinar.Id;
        insert otherCampaign;

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert event;

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

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

        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(attendee.attendee);

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