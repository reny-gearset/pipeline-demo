@isTest
private class TestWebinarProspectService {
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

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        
        Lead l = [SELECT LastName, Company, Email, LeadSource FROM Lead];
        
        System.assertEquals('Test', l.LastName);
        System.assertEquals('DON\'T KNOW', l.Company);
        System.assertEquals('testwebinarlead@gearset.com', l.Email);
        System.assertEquals('Event', l.LeadSource);
    }
    
    @isTest
    public static void shouldSetLeadOwnerToSdr() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@example.com';
        a.zoom_app__Name__c = 'Test';

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });

        Lead l = [SELECT LastName, Company, Email, OwnerId, LeadSource FROM Lead];

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

        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a.zoom_app__Name__c = 'Test';
        a.zoom_app__Zoom_Webinar__c = w.Id;

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, w, null, null) });

        Lead l = [SELECT LastName, Company, Email, LeadSource FROM Lead];

        Task t = [SELECT Subject, ActivityDate FROM Task WHERE WhoId = :l.Id];

        System.assertEquals('registered-webinar-attended', t.Subject);
        System.assertEquals(System.today() + 1, t.ActivityDate);
    }

	@isTest
    public static void shouldCreateNextDayTaskAssignedToProspectOwnerForExistingProspects() {
        User u = [SELECT Id FROM User LIMIT 1];

        Contact existingContact = new Contact(
            LastName = 'Contact',
            Email = 'testwebinarcontact@gearset.com',
            OwnerId = u.Id
        );
        insert existingContact;

        Lead existingLead = new Lead(
            LastName = 'Lead',
            Company = 'DON\'T KNOW',
            Email = 'testwebinarlead@gearset.com',
            OwnerId = u.Id
        );
        insert existingLead;

        zoom_app__Zoom_Webinar__c w = new zoom_app__Zoom_Webinar__c();
        w.zoom_app__Start_Time__c = DateTime.now() - 10;
        w.zoom_app__Actual_End_Time__c = DateTime.now();
        w.zoom_app__Duration__c = 10;
        w.zoom_app__Topic__c = 'Test';

        zoom_app__Zoom_Webinar_Attendee__c a1 = new zoom_app__Zoom_Webinar_Attendee__c();
        a1.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a1.zoom_app__Name__c = 'Test';
        a1.zoom_app__Zoom_Webinar__c = w.Id;

        zoom_app__Zoom_Webinar_Attendee__c a2 = new zoom_app__Zoom_Webinar_Attendee__c();
        a2.zoom_app__User_Email__c = 'testwebinarcontact@gearset.com';
        a2.zoom_app__Name__c = 'Test';
        a2.zoom_app__Zoom_Webinar__c = w.Id;

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, existingLead, a1, null, w, null, null) });
        Lead unmodifiedLead = [SELECT LastName, Company, Email, OwnerId FROM Lead];
        System.assertEquals(unmodifiedLead, existingLead);

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, existingContact, null, null, a2, null, w, null, null) });
        Lead stillUnmodifiedLead = [SELECT LastName, Company, Email, OwnerId FROM Lead];
        System.assertEquals(stillUnmodifiedLead, existingLead);

        Task t1 = [SELECT Subject, ActivityDate, OwnerId FROM Task WHERE WhoId = :existingLead.Id];
        System.assertEquals('registered-webinar-attended', t1.Subject);
        System.assertEquals(System.today() + 1, t1.ActivityDate);
        System.assertEquals(u.Id, t1.OwnerId);

        Task t2 = [SELECT Subject, ActivityDate, OwnerId FROM Task WHERE WhoId = :existingContact.Id];
        System.assertEquals('registered-webinar-attended', t2.Subject);
        System.assertEquals(System.today() + 1, t2.ActivityDate);
        System.assertEquals(u.Id, t2.OwnerId);
    }

    @isTest
    public static void shouldAssignTaskToSdrManagerIfOwnerIsGearbotBobbins() {
        UserRole headOfSdrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Head_of_SDR'];
    	User headOfSdr = [SELECT Id FROM User WHERE UserRoleId = :headOfSdrRole.Id][0];
        User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];

        Contact existingContact = new Contact(
            LastName = 'Contact',
            Email = 'testwebinarcontact@gearset.com',
            OwnerId = gearbot.Id
        );
        insert existingContact;

        zoom_app__Zoom_Webinar__c w = new zoom_app__Zoom_Webinar__c();
        w.zoom_app__Start_Time__c = DateTime.now() - 10;
        w.zoom_app__Actual_End_Time__c = DateTime.now();
        w.zoom_app__Duration__c = 10;
        w.zoom_app__Topic__c = 'Test';

        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarcontact@gearset.com';
        a.zoom_app__Name__c = 'Test';
        a.zoom_app__Zoom_Webinar__c = w.Id;

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, existingContact, null, null, a, null, w, null, null) });

        Task ordinaryTask = [SELECT OwnerId FROM Task WHERE WhoId = :existingContact.Id AND OwnerId = :gearbot.Id];
        System.assertNotEquals(null, ordinaryTask);
        Task assignmentTask = [SELECT OwnerId FROM Task WHERE WhoId = :existingContact.Id AND OwnerId = :headOfSdr.Id];
        System.assertNotEquals(null, assignmentTask);
    }

    @isTest
    public static void shouldCreateCampaignMemberForProspectsForEachCampaignAssociatedWithWebinar() {
        // Arrange
        User u = [SELECT Id FROM User LIMIT 1];

        Contact existingContact = new Contact(
            LastName = 'Contact',
            Email = 'testwebinarcontact@gearset.com',
            OwnerId = u.Id
        );
        insert existingContact;

        Lead existingLead = new Lead(
            LastName = 'Lead',
            Company = 'DON\'T KNOW',
            Email = 'testwebinarlead@gearset.com',
            OwnerId = u.Id
        );
        insert existingLead;

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
        a2.zoom_app__User_Email__c = 'testwebinarcontact@gearset.com';
        a2.zoom_app__Name__c = 'Test';
        a2.zoom_app__Zoom_Webinar_Registrant__c = r.Id;
        a2.zoom_app__Zoom_Webinar_Panelist__c = p.Id;
        a2.zoom_app__Join_Time__c = joinTime;
        a2.zoom_app__Leave_Time__c = leaveTime;
        a2.zoom_app__Zoom_Webinar__c = w.Id;

        // Act
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, existingLead, a1, null, w, new List<Campaign> { c1, c2 }, null) });
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, existingContact, null, null, a2, r, w, new List<Campaign> { c1, c2 }, null) });

        // Assert
        List<CampaignMember> members = [SELECT
                                            LeadId,
                                            ContactId,
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
            if (cm.LeadId == existingLead.Id) {
                System.assertEquals(false, cm.zoom_app__Is_Registrant__c);
                System.assertEquals(null, cm.zoom_app__Registrant_Id__c);
                System.assertEquals(null, cm.zoom_app__Registrant_Id__c);
                System.assertEquals(false, cm.zoom_app__isPanelist__c);
                System.assertEquals(null, cm.zoom_app__panelist_Id__c);
                System.assertEquals(joinTime, cm.zoom_app__join_time__c);
                System.assertEquals(leaveTime, cm.zoom_app__leave_time__c);
            }
            else if (cm.ContactId == existingContact.Id) {
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
    public static void shouldCreateCampaignMemberForCorrectCampaign() {
        // Arrange
        User u = [SELECT Id FROM User LIMIT 1];
        
        Contact existingContact = new Contact(
            LastName = 'Contact',
            Email = 'testwebinarcontact@gearset.com',
            OwnerId = u.Id
        );
        insert existingContact;

        Lead existingLead = new Lead(
            LastName = 'Lead',
            Company = 'DON\'T KNOW',
            Email = 'testwebinarlead@gearset.com',
            OwnerId = u.Id
        );
        insert existingLead;

        zoom_app__Zoom_Webinar__c w1 = new zoom_app__Zoom_Webinar__c();
        w1.zoom_app__Start_Time__c = DateTime.now() - 10;
        w1.zoom_app__Actual_End_Time__c = DateTime.now();
        w1.zoom_app__Duration__c = 10;
        w1.zoom_app__Topic__c = 'Test';
        insert w1;

        zoom_app__Zoom_Webinar__c w2 = new zoom_app__Zoom_Webinar__c();
        w2.zoom_app__Start_Time__c = DateTime.now() - 10;
        w2.zoom_app__Actual_End_Time__c = DateTime.now();
        w2.zoom_app__Duration__c = 10;
        w2.zoom_app__Topic__c = 'Test';
        insert w2;

        Campaign c1 = new Campaign();
        c1.Name = 'Campaign 1';
        c1.zoom_app__Zoom_Webinar__c = w1.Id;
        insert c1;

        Campaign c2 = new Campaign();
        c2.Name = 'Campaign 2';
        c2.zoom_app__Zoom_Webinar__c = w2.Id;
        insert c2;

        zoom_app__Zoom_Webinar_Attendee__c a1 = new zoom_app__Zoom_Webinar_Attendee__c();
        a1.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a1.zoom_app__Name__c = 'Test';
        DateTime joinTime = DateTime.now() - 5;
        DateTime leaveTime = DateTime.now();
        a1.zoom_app__Join_Time__c = joinTime;
        a1.zoom_app__Leave_Time__c = leaveTime;
        a1.zoom_app__Zoom_Webinar__c = w1.Id;

        zoom_app__Zoom_Webinar_Attendee__c a2 = new zoom_app__Zoom_Webinar_Attendee__c();
        a2.zoom_app__User_Email__c = 'testwebinarcontact@gearset.com';
        a2.zoom_app__Name__c = 'Test';
        a2.zoom_app__Join_Time__c = joinTime;
        a2.zoom_app__Leave_Time__c = leaveTime;
        a2.zoom_app__Zoom_Webinar__c = w2.Id;

        // Act
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, existingLead, a1, null, w1, new List<Campaign>{ c1 }, null), 
                                                                                              new WebinarAttendeeInformation(null, existingContact, null, null, a2, null, w2, new List<Campaign>{ c2 }, null) });

        // Assert
        List<CampaignMember> members = [SELECT
                                            CampaignId,
                                            LeadId,
                                            ContactId
                                        FROM CampaignMember];
        System.assertEquals(2, members.size());
        for (CampaignMember cm : members) {
            if (cm.LeadId == existingLead.Id) {
                System.assertEquals(c1.Id, cm.CampaignId);
            }
            else if (cm.ContactId == existingContact.Id) {
				System.assertEquals(c2.Id, cm.CampaignId);
            }  
        }
    }

    @isTest
    public static void shouldUseRegistrantNameForPreference() {
        zoom_app__Zoom_Webinar_Registrant__c r = new zoom_app__Zoom_Webinar_Registrant__c();
        r.zoom_app__First_Name__c = 'Test';
        r.zoom_app__Last_Name__c = 'Attendee';
        
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Zoom_Webinar_Registrant__c = r.Id;
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        a.zoom_app__Name__c = 'Test';
        
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, r, null, null, null) });

        Lead l = [SELECT LastName, FirstName, Company, Email, LeadSource FROM Lead];

        System.assertEquals('Test', l.FirstName);
        System.assertEquals('Attendee', l.LastName);
    }
    
    @isTest
    public static void shouldSplitAttendeeNameIfContainsOneSpace() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();

        a.zoom_app__User_Email__c = 'testwebinarlead1@gearset.com';
        a.zoom_app__Name__c = 'Test Attendee';

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });

        Lead l = [SELECT LastName, FirstName, Company, Email, LeadSource FROM Lead];

        System.assertEquals('Test', l.FirstName);
        System.assertEquals('Attendee', l.LastName);
    }

    @isTest
    public static void shouldSplitAttendeeNameIfContainsMultipleSpaces() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();

        a.zoom_app__User_Email__c = 'testwebinarlead1@gearset.com';
        a.zoom_app__Name__c = 'Test Webinar Attendee';

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });

        Lead l = [SELECT LastName, FirstName, Company, Email, LeadSource FROM Lead];

        System.assertEquals('Test', l.FirstName);
        System.assertEquals('Attendee', l.LastName);
    }

    @isTest
    public static void shouldNotCreateLeadIfEmailAlreadyInSystem() {
        User existingUser = [SELECT Id, Email FROM User LIMIT 1];
        
        Contact existingContact = new Contact(
            LastName = 'Contact',
            Email = 'testwebinarcontact@gearset.com',
            OwnerId = existingUser.Id
        );

        Lead existingLead = new Lead(
            LastName = 'Lead',
            Company = 'DON\'T KNOW',
            Email = 'testwebinarlead@gearset.com',
            OwnerId = existingUser.Id
        );

        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Name__c = 'Test';

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(existingUser, null, null, null, a, null, null, null, null) });

        Integer numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, existingContact, null, null, a, null, null, null, null) });

        numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, existingLead, a, null, null, null, null) });
        numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);
    }

    @isTest
    public static void shouldNotCreateLeadIfNoEmail() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__Name__c = 'Test';

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        Integer numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);

        a.zoom_app__User_Email__c = '';
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);

        a.zoom_app__User_Email__c = '  ';
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);
    }

    @isTest
    public static void shouldNotCreateLeadIfNoName() {
        zoom_app__Zoom_Webinar_Attendee__c a = new zoom_app__Zoom_Webinar_Attendee__c();
        a.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        Integer numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);

        a.zoom_app__User_Email__c = 'testwebinarlead1@gearset.com'; // Using different email as otherwise we won't create a lead
        a.zoom_app__Name__c = '';
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);

        a.zoom_app__User_Email__c = 'testwebinarlead2@gearset.com';
        a.zoom_app__Name__c = '  ';
        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a, null, null, null, null) });
        numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(0, numberOfLeads);
    }

    @isTest
    public static void shouldOnlyCreateOneLeadIfAttendedWithSameEmailMoreThanOnce() {
        zoom_app__Zoom_Webinar_Attendee__c a1 = new zoom_app__Zoom_Webinar_Attendee__c();
        a1.zoom_app__Name__c = 'Test';
        a1.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';

        zoom_app__Zoom_Webinar_Attendee__c a2 = new zoom_app__Zoom_Webinar_Attendee__c();
        a2.zoom_app__Name__c = 'Test';
        a2.zoom_app__User_Email__c = 'testwebinarlead@gearset.com';

        WebinarProspectService.processWebinarAttendees(new List<WebinarAttendeeInformation> { new WebinarAttendeeInformation(null, null, null, null, a1, null, null, null, null), 
                                                                                              new WebinarAttendeeInformation(null, null, null, null, a2, null, null, null, null) });

        Integer numberOfLeads = [SELECT COUNT() FROM Lead];
        System.assertEquals(1, numberOfLeads);
    }
}