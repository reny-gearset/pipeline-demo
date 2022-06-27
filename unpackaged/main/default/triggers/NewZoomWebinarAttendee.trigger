trigger NewZoomWebinarAttendee on zoom_app__Zoom_Webinar_Attendee__c (after insert) {
    List<WebinarAttendeeInformation> attendees = WebinarAttendeeInformationService.getWebinarAttendeeInformation(Trigger.new);
    WebinarProspectService.processWebinarAttendees(attendees);
    for (WebinarAttendeeInformation a : attendees) {
        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(a);
    }
}