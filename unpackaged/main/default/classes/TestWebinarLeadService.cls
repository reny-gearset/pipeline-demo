@isTest
private class TestWebinarLeadService {
    @testSetup
    public static void setup() {
        // Make sure we have at least 1 SDR
        UserRole sdrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Development_Representative' LIMIT 1];
        User sdr1 = TestUtils.createStandardUser('SDR', 'sales@example.com');
        sdr1.UserRoleId = sdrRole.Id;
        insert sdr1;
    }

    @isTest
    public static void shouldCreateLeadGivenMinimumValidInfoAndEmailNotInSystem() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a.zoom_app__Name__c = 'Test';

        WebinarLeadService.createLeadFromWebinarAttendee(a);
        
        Lead l = [SELECT LastName, Company, Email, LeadSource FROM Lead];
        
        System.assertEquals('Test', l.LastName);
        System.assertEquals('DON\'T KNOW', l.Company);
        System.assertEquals('testwebinarlead@gearset.com', l.Email);
        System.assertEquals('Event', l.LeadSource);
    }
    
    @isTest
    public static void shouldSetLeadOwnerToSdr() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a.zoom_app__Name__c = 'Test';

        Lead l = WebinarLeadService.createLeadFromWebinarAttendee(a);

        UserRole sdrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Development_Representative' LIMIT 1];
        User u = [SELECT Id, UserRoleId FROM User WHERE Id = :l.OwnerId AND UserRoleId = :sdrRole.Id LIMIT 1];

        System.assertNotEquals(null, u);
    }
     
    @isTest
    public static void shouldCreateNextDayTaskForNewLead() {
        zoom_app__Zoom_Webinar__c w = new zoom_app__Zoom_Webinar__c();
        w.zoom_app__Start_Time__c = DateTime.now() - 10;
        w.zoom_app__Actual_End_Time__c = DateTime.now();
        w.zoom_app__Duration__c = 10;
        w.zoom_app__Topic__c = 'Test';
        insert w;

        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a.zoom_app__Name__c = 'Test';
        a.zoom_app__Zoom_Webinar__c = w.Id;

        Lead l = WebinarLeadService.createLeadFromWebinarAttendee(a);

        Task t = [SELECT Subject, ActivityDate FROM Task WHERE WhoId = :l.Id];

        System.assertEquals('registered-webinar-attended', t.Subject);
        System.assertEquals(System.today() + 1, t.ActivityDate);
    }

    @isTest
    public static void shouldCreateCampaignMemberForNewLeadForEachCampaignAssociatedWithWebinar() {
        // Arrange
        zoom_app__Zoom_Webinar__c w = new zoom_app__Zoom_Webinar__c();
        w.zoom_app__Start_Time__c = DateTime.now() - 10;
        w.zoom_app__Actual_End_Time__c = DateTime.now();
        w.zoom_app__Duration__c = 10;
        w.zoom_app__Topic__c = 'Test';
        insert w;

        Campaign c1 = new Campaign();
        c1.Name = 'Campaign 1';
        c1.zoom_app__Zoom_Webinar__c = w.Id;
        insert c1;

        Campaign c2 = new Campaign();
        c2.Name = 'Campaign 2';
        c2.zoom_app__Zoom_Webinar__c = w.Id;
        insert c2;

        zoom_app__Zoom_Webinar_Attendee__c a1 = new zoom_app__Zoom_Webinar_Attendee__c();
        a1.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a1.zoom_app__Name__c = 'Test';
        DateTime joinTime = DateTime.now() - 5;
        DateTime leaveTime = DateTime.now();
        a1.zoom_app__Join_Time__c = joinTime;
        a1.zoom_app__Leave_Time__c = leaveTime;
        a1.zoom_app__Zoom_Webinar__c = w.Id;

        zoom_app__Zoom_Webinar_Registrant__c r = new zoom_app__Zoom_Webinar_Registrant__c();
        r.zoom_app__Last_Name__c = 'Test';
        insert r;
        zoom_app__Zoom_Webinar_Panelist__c p = new zoom_app__Zoom_Webinar_Panelist__c();
        insert p;

        zoom_app__Zoom_Webinar_Attendee__c a2 = new zoom_app__Zoom_Webinar_Attendee__c();
        a2.zoom_app__User_Email__c = 'testwebinarlead1@gearset.com';
        a2.zoom_app__Name__c = 'Test';
        a2.zoom_app__Zoom_Webinar_Registrant__c = r.Id;
        a2.zoom_app__Zoom_Webinar_Panelist__c = p.Id;
        a2.zoom_app__Join_Time__c = joinTime;
        a2.zoom_app__Leave_Time__c = leaveTime;
        a2.zoom_app__Zoom_Webinar__c = w.Id;

        // Act
        Lead l1 = WebinarLeadService.createLeadFromWebinarAttendee(a1);
        Lead l2 = WebinarLeadService.createLeadFromWebinarAttendee(a2);

        // Assert
        List<CampaignMember> members = [SELECT
                                            LeadId,
                                            zoom_app__Is_Registrant__c,
                                            zoom_app__Registrant_Id__c,
                                            zoom_app__Zoom_Webinar_Registrant__c,
                                            zoom_app__isPanelist__c,
                                            zoom_app__panelist_Id__c,
                                            zoom_app__join_time__c,
                                            zoom_app__leave_time__c
                                        FROM CampaignMember];
        System.assertEquals(4, members.size());
        for (CampaignMember cm : members) {
            if (cm.LeadId == l1.Id) {
                System.assertEquals(false, cm.zoom_app__Is_Registrant__c);
                System.assertEquals(null, cm.zoom_app__Registrant_Id__c);
                System.assertEquals(null, cm.zoom_app__Registrant_Id__c);
                System.assertEquals(false, cm.zoom_app__isPanelist__c);
                System.assertEquals(null, cm.zoom_app__panelist_Id__c);
                System.assertEquals(joinTime, cm.zoom_app__join_time__c);
                System.assertEquals(leaveTime, cm.zoom_app__leave_time__c);
            }
            else if (cm.LeadId == l2.Id) {
                System.assertEquals(true, cm.zoom_app__Is_Registrant__c);
                System.assertEquals(a2.zoom_app__Zoom_Webinar_Registrant__c, cm.zoom_app__Registrant_Id__c);
                System.assertEquals(a2.zoom_app__Zoom_Webinar_Registrant__c, cm.zoom_app__Zoom_Webinar_Registrant__c);
                System.assertEquals(true, cm.zoom_app__isPanelist__c);
                System.assertEquals(a2.zoom_app__Zoom_Webinar_Panelist__c, cm.zoom_app__panelist_Id__c);
                System.assertEquals(joinTime, cm.zoom_app__join_time__c);
                System.assertEquals(leaveTime, cm.zoom_app__leave_time__c);
            }  
        }
    }

    @isTest
    public static void shouldUseRegistrantNameForPreference() {
        zoom_app__Zoom_Webinar_Registrant__c r = new zoom_app__Zoom_Webinar_Registrant__c();
        r.zoom_app__First_Name__c = 'Test';
        r.zoom_app__Last_Name__c = 'Attendee';
        insert r;
        
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Zoom_Webinar_Registrant__c = r.Id;
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a.zoom_app__Name__c = 'Test';
        
        Lead l = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals('Test', l.FirstName);
        System.assertEquals('Attendee', l.LastName);
    }
    
    @isTest
    public static void shouldSplitAttendeeNameIfContainsSpaces() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();

        a.zoom_app__User_Email__c = 'testwebinarlead1@gearset.com';
        a.zoom_app__Name__c = 'Test Attendee';
        Lead leadFromNameWithSpaces = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals('Test', leadFromNameWithSpaces.FirstName);
        System.assertEquals('Attendee', leadFromNameWithSpaces.LastName);

        a.zoom_app__User_Email__c = 'testwebinarlead2@gearset.com'; // Needs to be a new email address because there's validation on that
        a.zoom_app__Name__c = 'Test Webinar Attendee';
        Lead leadFromNamesWithMultipleSpaces = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals('Test', leadFromNamesWithMultipleSpaces.FirstName);
        System.assertEquals('Attendee', leadFromNamesWithMultipleSpaces.LastName);
    }

    @isTest
    public static void shouldNotCreateLeadIfEmailAlreadyInSystem() {
        User existingUser = [SELECT Email FROM User LIMIT 1];
        
        Contact existingContact = new Contact(
            LastName = 'Contact',
            Email = 'testwebinarcontact@gearset.com'
        );
        insert existingContact;

        Lead existingLead = new Lead(
            LastName = 'Lead',
            Company = 'DON\'T KNOW',
            Email = 'testwebinarlead@gearset.com'
        );
        insert existingLead;

        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Name__c = 'Test';

        a.zoom_app__User_Email__c = existingUser.Email;
        Lead leadFromExistingUser = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromExistingUser);

        a.zoom_app__User_Email__c = existingContact.Email;
        Lead leadFromExistingContact = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromExistingContact);
        
        a.zoom_app__User_Email__c = existingLead.Email;
        Lead leadFromExistingLead = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromExistingLead);
    }

    @isTest
    public static void shouldReturnNullIfLeadInsertionFails() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Name__c = 'Test';

        a.zoom_app__User_Email__c = 'foo'; // Bit flaky, I know, relying on this being an invalid email address that's going to be rejected by the validation
        Lead leadFromInvalidEmail = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromInvalidEmail);
    }

    @isTest
    public static void shouldNotCreateLeadIfNoEmail() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Name__c = 'Test';

        Lead leadFromNullEmail = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromNullEmail);

        a.zoom_app__User_Email__c = '';
        Lead leadFromEmptyEmail = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromEmptyEmail);

        a.zoom_app__User_Email__c = '  ';
        Lead leadFromWhitespaceEmail = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromEmptyEmail);
    }

    @isTest
    public static void shouldNotCreateLeadIfNoName() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        Lead leadFromNameNotSet = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromNameNotSet);
        
        a.zoom_app__User_Email__c = 'testwebinarlead1@gearset.com'; // Using different email as otherwise we won't create a lead
        a.zoom_app__Name__c = '';
        Lead leadFromEmptyName = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromEmptyName);

        a.zoom_app__User_Email__c = 'testwebinarlead2@gearset.com';
        a.zoom_app__Name__c = '  ';
        Lead leadFromWhitespaceName = WebinarLeadService.createLeadFromWebinarAttendee(a);
        System.assertEquals(null, leadFromWhitespaceName);
    }

}