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
}