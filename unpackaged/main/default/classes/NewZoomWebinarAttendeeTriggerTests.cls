@isTest
private class NewZoomWebinarAttendeeTriggerTests {
	@isTest public static void newZoomWebinarAttendeeTriggerShouldCreateLeads() {
        List<zoom_app__Zoom_Webinar_Attendee__c> newAttendees = new List<zoom_app__Zoom_Webinar_Attendee__c>{
            new zoom_app__Zoom_Webinar_Attendee__c (
        	zoom_app__User_Email__c = 'testwebinarlead@gearset.com',
        	zoom_app__Name__c = 'Test'
            ),
            new zoom_app__Zoom_Webinar_Attendee__c (
                zoom_app__User_Email__c = 'testwebinarlead1@gearset.com',
                zoom_app__Name__c = 'Another Test'
            )
        };

        insert newAttendees;

        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(2, leads.size());
    }

    @isTest
    public static void newZoomWebinarAttendeeTriggerShouldWorkWithinGovernorLimitsForRealisticNumberOfAttendees(){
        List<Lead> existingLeads = new List<Lead>();
        for (Integer i = 0; i < 500; i++) {
            Lead l = new Lead();
            l.LastName = 'Test';
            l.Company = 'Test';
            l.Email	= 'testwebinarprospect' + i + '@gearset.com';
            existingLeads.add(l);
        }
        insert existingLeads;

        List<Contact> existingContacts = new List<Contact>();
        for (Integer i = 500; i < 1000; i++) {
            Contact c = new Contact();
            c.LastName = 'Test';
            c.Email	= 'testwebinarprospect' + i + '@gearset.com';
            existingContacts.add(c);
        }
        insert existingContacts;

        List<zoom_app__Zoom_Webinar_Attendee__c> newAttendees = new List<zoom_app__Zoom_Webinar_Attendee__c>();
        for (Integer i = 0; i < 1200; i++) {
            zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c (
        		zoom_app__User_Email__c = 'testwebinarprospect' + i + '@gearset.com',
        		zoom_app__Name__c = 'Test'
            );
            newAttendees.add(a);
        }
        insert newAttendees;

        List<zoom_app__Zoom_Webinar_Attendee__c> insertedAttendees = [SELECT Id FROM zoom_app__Zoom_Webinar_Attendee__c];
        System.assertEquals(1200, insertedAttendees.size());
    }
}