public class WebinarAttendeeInformation {
    public User userRecord;
    public Contact contactRecordByPrimaryEmail;
    public Contact contactRecordByOtherEmail;
    public Lead leadRecord;
    public zoom_app__Zoom_Webinar_Attendee__c webinarAttendeeRecord;
    public zoom_app__Zoom_Webinar_Registrant__c webinarRegistrantRecord;
    public zoom_app__Zoom_Webinar__c webinarRecord;
    public List<Campaign> campaignRecords;
    public List<Event> eventRecords;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public WebinarAttendeeInformation(User user, Contact contactByPrimaryEmail, Contact contactByOtherEmail, Lead lead, zoom_app__Zoom_Webinar_Attendee__c webinarAttendee, zoom_app__Zoom_Webinar_Registrant__c webinarRegistrant, zoom_app__Zoom_Webinar__c webinar, List<Campaign> campaigns, List<Event> events) {
        this.userRecord = user;
        this.contactRecordByPrimaryEmail = contactByPrimaryEmail;
        this.contactRecordByOtherEmail = contactByOtherEmail;
        this.leadRecord = lead;
        this.webinarAttendeeRecord = webinarAttendee;
        this.webinarRegistrantRecord = webinarRegistrant;
        this.webinarRecord = webinar;
        this.campaignRecords = campaigns;
        this.eventRecords = events;
    }
}