@isTest
private class TestPartnerLeadController {
    @isTest
    public static void shouldNotCreateLeadIfTeamIdDoesNotExist() {
        PartnerLeadController.PartnerLeadInfo info = new PartnerLeadController.PartnerLeadInfo();
        info.contactCompanyName = 'Random Company';
        info.contactEmail = 'Random@hotmail.com';
        info.contactFirstName = 'RandomFirstName';
        info.contactLastName = 'RandomLastName';
        info.referrerCompanyName = 'Referrer Company';
        info.referrerEmail = 'referrer@hotmail.com';
        info.referrerFirstName = 'ReferrerFirstName';
        info.referrerLastName = 'ReferrerLastName';
        info.extraDetails = 'Referrer Notes';
        info.teamId = '';
        
        try {
            PartnerLeadController.createPartnerReferralLead(info);
            System.assert(false);
        } catch (IllegalArgumentException e) {
            System.assertEquals('Could not get matching SI Account from TeamId ', e.getMessage());
        }
    }
    
    @isTest
    public static void shouldNotCreateLeadIfTeamIdDoesNotCorrespondToSIAccount() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id
        );
        insert acct;
        
        PartnerLeadController.PartnerLeadInfo info = new PartnerLeadController.PartnerLeadInfo();
        info.contactCompanyName = 'Random Company';
        info.contactEmail = 'Random@hotmail.com';
        info.contactFirstName = 'RandomFirstName';
        info.contactLastName = 'RandomLastName';
        info.referrerCompanyName = 'Referrer Company';
        info.referrerEmail = 'referrer@hotmail.com';
        info.referrerFirstName = 'ReferrerFirstName';
        info.referrerLastName = 'ReferrerLastName';
        info.extraDetails = 'Referrer Notes';
        info.teamId = 'Team 1';
        
        try {
            PartnerLeadController.createPartnerReferralLead(info);
            System.assert(false);
        } catch (IllegalArgumentException e) {
            System.assertEquals('Could not get matching SI Account from TeamId Team 1', e.getMessage());
        }
    }
    
    @isTest
    public static void shouldCreateLeadAndTaskIfTeamIdAssociatesWithSIAccount() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            Type = 'Implementation Partner - Free',
            Show_Partner_Portal__c = true
        );
        insert acct;
        
        PartnerLeadController.PartnerLeadInfo info = new PartnerLeadController.PartnerLeadInfo();
        info.contactCompanyName = 'Random Company';
        info.contactEmail = 'Random@hotmail.com';
        info.contactFirstName = 'RandomFirstName';
        info.contactLastName = 'RandomLastName';
        info.referrerCompanyName = 'Referrer Company';
        info.referrerEmail = 'referrer@hotmail.com';
        info.referrerFirstName = 'ReferrerFirstName';
        info.referrerLastName = 'ReferrerLastName';
        info.extraDetails = 'Referrer Notes';
        info.teamId = 'Team 1';
        
        Boolean success = PartnerLeadController.createPartnerReferralLead(info);
        
        System.assert(success);
        
        List<Lead> leads = 
            [SELECT Id, Status, LeadSource, FirstName, LastName, Company, Email, 
                    Referrer_First_Name__c, Referrer_Last_Name__c, Referrer_Email__c,
                    Referrer_Company_Name__c, SI_Partner__c, Referrer_Contact__c, Referral_Extra_Details__c, OwnerId
             FROM Lead ];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('New', leads[0].Status);
        System.assertEquals('Partner', leads[0].LeadSource);
        System.assertEquals(info.contactFirstName, leads[0].FirstName);
        System.assertEquals(info.contactLastName, leads[0].LastName);
        System.assertEquals(info.contactCompanyName, leads[0].Company);
        System.assertEquals(info.contactEmail.toLowerCase(), leads[0].Email);
        System.assertEquals(info.referrerFirstName, leads[0].Referrer_First_Name__c);
        System.assertEquals(info.referrerLastName, leads[0].Referrer_Last_Name__c);
        System.assertEquals(info.referrerEmail.toLowerCase(), leads[0].Referrer_Email__c);
        System.assertEquals(info.referrerCompanyName, leads[0].Referrer_Company_Name__c);
        System.assertEquals(acct.Id, leads[0].SI_Partner__c);
        System.assertEquals(null, leads[0].Referrer_Contact__c);
        System.assertEquals(info.extraDetails, leads[0].Referral_Extra_Details__c);
        System.assertNotEquals(null, leads[0].OwnerId);
        
        List<Task> tasks = 
            [SELECT Subject, Status, Priority, WhoId, OwnerId, Description
             FROM Task];
        
        System.assertEquals('Can we get this referral lead to be an opp?', tasks[0].Subject);
        System.assertEquals('Open', tasks[0].Status);
        System.assertEquals('Normal', tasks[0].Priority);
        System.assertEquals(leads[0].Id, tasks[0].WhoId);
        System.assertEquals(leads[0].OwnerId, tasks[0].OwnerId);
        System.assertEquals('Referral Lead ' + leads[0].Email + ' needs triaging', tasks[0].Description);
    }
    
    @isTest
    public static void shouldCreateLeadAndTaskIfTeamIdAssociatesWithSIAccountAndReferrerEmailAssociatesWithSIAccountContact() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            Type = 'Implementation Partner - Free',
            Show_Partner_Portal__c = true
        );
        insert acct;
        
        Contact contact = new Contact(
            FirstName = 'FirstName',
            LastName = 'LastName',
            Email = 'email1@hotmail.com',
            Email_2__c = 'referrer@hotmail.com',
            AccountId = acct.Id
        );
        
        insert contact;
        
        PartnerLeadController.PartnerLeadInfo info = new PartnerLeadController.PartnerLeadInfo();
        info.contactCompanyName = 'Random Company';
        info.contactEmail = 'Random@hotmail.com';
        info.contactFirstName = 'RandomFirstName';
        info.contactLastName = 'RandomLastName';
        info.referrerCompanyName = 'Referrer Company';
        info.referrerEmail = 'referrer@hotmail.com';
        info.referrerFirstName = 'ReferrerFirstName';
        info.referrerLastName = 'ReferrerLastName';
        info.extraDetails = 'Referrer Notes';
        info.teamId = 'Team 1';
        
        Boolean success = PartnerLeadController.createPartnerReferralLead(info);
        
        System.assert(success);
        
        List<Lead> leads = 
            [SELECT Id, Status, LeadSource, FirstName, LastName, Company, Email, 
                    Referrer_First_Name__c, Referrer_Last_Name__c, Referrer_Email__c,
                    Referrer_Company_Name__c, SI_Partner__c, Referrer_Contact__c, Referral_Extra_Details__c, OwnerId
             FROM Lead ];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('New', leads[0].Status);
        System.assertEquals('Partner', leads[0].LeadSource);
        System.assertEquals(info.contactFirstName, leads[0].FirstName);
        System.assertEquals(info.contactLastName, leads[0].LastName);
        System.assertEquals(info.contactCompanyName, leads[0].Company);
        System.assertEquals(info.contactEmail.toLowerCase(), leads[0].Email);
        System.assertEquals(info.referrerFirstName, leads[0].Referrer_First_Name__c);
        System.assertEquals(info.referrerLastName, leads[0].Referrer_Last_Name__c);
        System.assertEquals(info.referrerEmail.toLowerCase(), leads[0].Referrer_Email__c);
        System.assertEquals(info.referrerCompanyName, leads[0].Referrer_Company_Name__c);
        System.assertEquals(acct.Id, leads[0].SI_Partner__c);
        System.assertEquals(contact.Id, leads[0].Referrer_Contact__c);
        System.assertEquals(info.extraDetails, leads[0].Referral_Extra_Details__c);
        System.assertNotEquals(null, leads[0].OwnerId);
        
        List<Task> tasks = 
            [SELECT Subject, Status, Priority, WhoId, OwnerId, Description
             FROM Task];
        
        System.assertEquals('Can we get this referral lead to be an opp?', tasks[0].Subject);
        System.assertEquals('Open', tasks[0].Status);
        System.assertEquals('Normal', tasks[0].Priority);
        System.assertEquals(leads[0].Id, tasks[0].WhoId);
        System.assertEquals(leads[0].OwnerId, tasks[0].OwnerId);
        System.assertEquals('Referral Lead ' + leads[0].Email + ' needs triaging', tasks[0].Description);
    }
    
    @isTest
    public static void shouldCreateLeadWithClosestAssociatedReferrerContactIfTeamIdAssociatesWithSIAccountAndReferrerDetailsMatchesWithSIAccountContact() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            Type = 'Implementation Partner - Free',
            Show_Partner_Portal__c = true
        );
        insert acct;
        
        Contact contact = new Contact(
            FirstName = 'ReferrerFirstName',
            LastName = 'ReferrerLastName',
            Email = 'email1@hotmail.com',
            Email_2__c = 'referrer@hotmail.com',
            AccountId = acct.Id
        );
        insert contact;
        
        Contact contact2 = new Contact(
            FirstName = 'Referrer2FirstName',
            LastName = 'Referrer2LastName',
            Email = 'email1@hotmail.com',
            AccountId = acct.Id
        );
        
        // Want to insert ignoring duplicates, so need to do a little dance
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.Insert(contact2, dml);
        
        PartnerLeadController.PartnerLeadInfo info = new PartnerLeadController.PartnerLeadInfo();
        info.contactCompanyName = 'Random Company';
        info.contactEmail = 'Random@hotmail.com';
        info.contactFirstName = 'RandomFirstName';
        info.contactLastName = 'RandomLastName';
        info.referrerCompanyName = 'Referrer Company';
        info.referrerEmail = 'referrer@hotmail.com';
        info.referrerFirstName = 'ReferrerFirstName';
        info.referrerLastName = 'ReferrerLastName';
        info.extraDetails = 'Referrer Notes';
        info.teamId = 'Team 1';
        
        Boolean success = PartnerLeadController.createPartnerReferralLead(info);
        
        System.assert(success);
        
        List<Lead> leads = 
            [SELECT Id, Status, LeadSource, FirstName, LastName, Company, Email, 
                    Referrer_First_Name__c, Referrer_Last_Name__c, Referrer_Email__c,
                    Referrer_Company_Name__c, SI_Partner__c, Referrer_Contact__c, Referral_Extra_Details__c, OwnerId
             FROM Lead ];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('New', leads[0].Status);
        System.assertEquals('Partner', leads[0].LeadSource);
        System.assertEquals(info.contactFirstName, leads[0].FirstName);
        System.assertEquals(info.contactLastName, leads[0].LastName);
        System.assertEquals(info.contactCompanyName, leads[0].Company);
        System.assertEquals(info.contactEmail.toLowerCase(), leads[0].Email);
        System.assertEquals(info.referrerFirstName, leads[0].Referrer_First_Name__c);
        System.assertEquals(info.referrerLastName, leads[0].Referrer_Last_Name__c);
        System.assertEquals(info.referrerEmail.toLowerCase(), leads[0].Referrer_Email__c);
        System.assertEquals(info.referrerCompanyName, leads[0].Referrer_Company_Name__c);
        System.assertEquals(acct.Id, leads[0].SI_Partner__c);
        System.assertEquals(contact.Id, leads[0].Referrer_Contact__c);
        System.assertEquals(info.extraDetails, leads[0].Referral_Extra_Details__c);
        System.assertNotEquals(null, leads[0].OwnerId);
        
        List<Task> tasks = 
            [SELECT Subject, Status, Priority, WhoId, OwnerId, Description
             FROM Task];
        
        System.assertEquals('Can we get this referral lead to be an opp?', tasks[0].Subject);
        System.assertEquals('Open', tasks[0].Status);
        System.assertEquals('Normal', tasks[0].Priority);
        System.assertEquals(leads[0].Id, tasks[0].WhoId);
        System.assertEquals(leads[0].OwnerId, tasks[0].OwnerId);
        System.assertEquals('Referral Lead ' + leads[0].Email + ' needs triaging', tasks[0].Description);
    }
    
    @isTest
    public static void shouldCreatePartnerAccountOwnerTask() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        User bobbins = [SELECT Id FROM User WHERE Name = 'Gearbot Bobbins' ];
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            Type = 'Implementation Partner - Free',
            OwnerId = bobbins.Id,
            Show_Partner_Portal__c = true
        );
        insert acct;
        
        PartnerLeadController.PartnerLeadInfo info = new PartnerLeadController.PartnerLeadInfo();
        info.contactCompanyName = 'Random Company';
        info.contactEmail = 'Random@hotmail.com';
        info.contactFirstName = 'RandomFirstName';
        info.contactLastName = 'RandomLastName';
        info.referrerCompanyName = 'Referrer Company';
        info.referrerEmail = 'referrer@hotmail.com';
        info.referrerFirstName = 'ReferrerFirstName';
        info.referrerLastName = 'ReferrerLastName';
        info.extraDetails = 'Referrer Notes';
        info.teamId = 'Team 1';
        
        Boolean success = PartnerLeadController.createPartnerReferralLead(info);
        
        System.assert(success);
        
        List<Lead> leads = 
            [SELECT Id, Status, LeadSource, FirstName, LastName, Company, Email, 
                    Referrer_First_Name__c, Referrer_Last_Name__c, Referrer_Email__c,
                    Referrer_Company_Name__c, SI_Partner__c, Referrer_Contact__c, Referral_Extra_Details__c, OwnerId
             FROM Lead ];
        
        List<Task> tasks = 
            [SELECT Subject, Status, Priority, WhoId, OwnerId, Description
             FROM Task];
        
        System.assertEquals('Your partner has referred a Lead to us. Is this a good Lead and who do you need to work with to get it closed?', tasks[1].Subject);
        System.assertEquals('Open', tasks[1].Status);
        System.assertEquals('Normal', tasks[1].Priority);
        System.assertEquals(leads[0].Id, tasks[1].WhoId);
        System.assertEquals(bobbins.Id, tasks[1].OwnerId);
        System.assertEquals('Referral Lead ' + leads[0].Email + ' needs reviewing', tasks[1].Description);
    }
}