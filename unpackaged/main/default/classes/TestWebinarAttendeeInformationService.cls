@isTest
private class TestWebinarAttendeeInformationService {
    @isTest
    public static void shouldNotIncludeEventIfEventSubjectIsNotWebinar() {
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

        List<WebinarAttendeeInformation> attendeeInfo = WebinarAttendeeInformationService.getWebinarAttendeeInformation(new List<zoom_app__Zoom_Webinar_Attendee__c> { attendee.attendee });

        System.assertEquals(1, attendeeInfo.size());
        System.assertEquals(0, attendeeInfo[0].eventRecords.size());
    }

    @isTest
    public static void shouldNotIncludeEventIfContactNotAMatch() {
        WebinarAttendee attendee = createWebinarAttendee();

        Contact anotherContact = new Contact(
            FirstName = 'Firstname',
            LastName = 'Contact',
            Email = 'not.' + attendee.attendee.zoom_app__User_Email__c
        );
        insert anotherContact;

        Event event = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = anotherContact.Id,
            Attended__c = false
        );
        insert event;

        List<WebinarAttendeeInformation> attendeeInfo = WebinarAttendeeInformationService.getWebinarAttendeeInformation(new List<zoom_app__Zoom_Webinar_Attendee__c> { attendee.attendee });

        System.assertEquals(1, attendeeInfo.size());
        System.assertEquals(0, attendeeInfo[0].eventRecords.size());
    }

    @isTest
    public static void shouldNotIncludeEventIfCampaignIsNotLinkedToAnyWebinar() {
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

        List<WebinarAttendeeInformation> attendeeInfo = WebinarAttendeeInformationService.getWebinarAttendeeInformation(new List<zoom_app__Zoom_Webinar_Attendee__c> { attendee.attendee });

        System.assertEquals(1, attendeeInfo.size());
        System.assertEquals(0, attendeeInfo[0].eventRecords.size());
    }

    @isTest
    public static void shouldNotIncludeEventIfCampaignIsLinkedToAnotherWebinar() {
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

        List<WebinarAttendeeInformation> attendeeInfo = WebinarAttendeeInformationService.getWebinarAttendeeInformation(new List<zoom_app__Zoom_Webinar_Attendee__c> { attendee.attendee });

        System.assertEquals(1, attendeeInfo.size());
        System.assertEquals(0, attendeeInfo[0].eventRecords.size());
    }

    @isTest
    public static void shouldIncludeAllEventsReferencingWebinarCampaigns() {
        WebinarAttendee attendee = createWebinarAttendee();

        Campaign otherCampaign = new Campaign();
        otherCampaign.Name = 'Campaign 2';
        otherCampaign.zoom_app__Zoom_Webinar__c = attendee.attendee.zoom_app__Zoom_Webinar__c;
        insert otherCampaign;

        Event e1 = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert e1;

        Event e2 = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = otherCampaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
		insert e2;

        List<WebinarAttendeeInformation> attendeeInfo = WebinarAttendeeInformationService.getWebinarAttendeeInformation(new List<zoom_app__Zoom_Webinar_Attendee__c> { attendee.attendee });

        System.assertEquals(1, attendeeInfo.size());
        System.assertEquals(2, attendeeInfo[0].eventRecords.size());
        System.assertEquals(attendee.campaign.Id, attendeeInfo[0].eventRecords[0].WhatId);
        System.assertEquals(otherCampaign.Id, attendeeInfo[0].eventRecords[1].WhatId);
    }

    @isTest
    public static void shouldIncludeEventsForContactsMatchedByOtherEmail() {
        WebinarAttendee attendee = createWebinarAttendee();
        Contact anotherContact = new Contact(
            FirstName = 'Firstname',
            LastName = 'Contact',
            Email = 'not.' + attendee.attendee.zoom_app__User_Email__c,
        	Email_2__c = attendee.attendee.zoom_app__User_Email__c);
        insert anotherContact;

        Event e1 = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = attendee.contact.Id,
            Attended__c = false
        );
        insert e1;

        Event e2 = new Event(
            DurationInMinutes = 0,
            ActivityDateTime = DateTime.now(),
            Subject = 'Webinar',
            WhatId = attendee.campaign.Id,
            WhoId = anotherContact.Id,
            Attended__c = false
        );
        insert e2;

        List<WebinarAttendeeInformation> attendeeInfo = WebinarAttendeeInformationService.getWebinarAttendeeInformation(new List<zoom_app__Zoom_Webinar_Attendee__c> { attendee.attendee });

        System.assertEquals(1, attendeeInfo.size());
        System.assertEquals(2, attendeeInfo[0].eventRecords.size());
        System.assertEquals(attendee.contact.Id, attendeeInfo[0].eventRecords[0].WhoId);
        System.assertEquals(anotherContact.Id, attendeeInfo[0].eventRecords[1].WhoId);
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