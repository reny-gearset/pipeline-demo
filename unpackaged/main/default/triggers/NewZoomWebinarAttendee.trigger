trigger NewZoomWebinarAttendee on zoom_app__Zoom_Webinar_Attendee__c (after insert) {
    for (zoom_app__Zoom_Webinar_Attendee__c a : Trigger.new) {
        WebinarLeadService.createLeadFromWebinarAttendee(a);
        WebinarAttendeeBdrCreditService.recordAttendanceInBdrEvent(a);
    }
}