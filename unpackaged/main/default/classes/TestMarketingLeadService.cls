@isTest
public with sharing class TestMarketingLeadService {
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
    private static User jacques = [SELECT Id FROM User WHERE Username LIKE 'jacques.peacock@gearset.com%'];

    @isTest
    public static void shouldCreateLeadInLostStateIfNewEmail() {
        // Act by inserting a brand new person from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.FirstName = 'Bruce';
        marketingLead.Surname = 'Springsteen';
        marketingLead.PhoneNumber = '(833) 441-7687';
        marketingLead.Company = 'E Street Industries';
        marketingLead.Source = 'unknown-campaign';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that a new lead has been created
        List<Lead> leads = [SELECT Id, Status, FirstName, LastName, Email, Company, Phone, LeadSource FROM Lead];
        System.assertEquals(1, leads.size(), 'A new lead should have been created');
        System.assertEquals('Lost', leads.get(0).Status, 'It should be a lost lead');
        System.assertEquals('Content', leads.get(0).LeadSource, 'The new lead should be a content based one');
        System.assertEquals('Bruce', leads.get(0).FirstName, 'First name should be copied from REST input');
        System.assertEquals('Springsteen', leads.get(0).LastName, 'Last name should be copied from REST input');
        System.assertEquals('(833) 441-7687', leads.get(0).Phone, 'Phone should be copied from REST input');
        System.assertEquals('E Street Industries', leads.get(0).Company, 'Company should be copied from REST input');

        // Assert that even though the campaign doesn't exist, we still have an activity
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created for the downloaded asset');
    }

    @isTest
    public static void shouldAddTaskToLeadEvenIfCampaignDoesntExist() {
        // Arrange by making sure a Lead record already exists, but no campaign
        Lead lead = new Lead(
            LastName = 'Springsteen',
            Company = 'E Street Industries',
            Email = 'bruce.springsteen@example.com'
        );
        insert lead;

        // Act by inserting something from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.Source = 'unknown-campaign';
        marketingLead.Surname = 'Springsteen';
        marketingLead.Company = 'E Street Industries';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that even though the campaign doesn't exist, we still have an activity
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created for the downloaded asset');
    }

    @isTest
    public static void shouldAddTaskToContactEvenIfCampaignDoesntExist() {
        // Arrange by making sure a Contact record already exists, but no campaign
        Contact contact = new Contact(LastName = 'Springsteen', Email = 'bruce.springsteen@example.com');
        insert contact;

        // Act by inserting something from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.Source = 'unknown-campaign';
        marketingLead.Surname = 'Springsteen';
        marketingLead.Company = 'E Street Industries';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that even though the campaign doesn't exist, we still have an activity
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created for the downloaded asset');
    }

    @isTest
    public static void shouldAddTaskToContactAndLeadEvenIfCampaignDoesntExist() {
        // Arrange by making sure both a Contact and Lead record already exists, but no campaign
        Lead lead = new Lead(
            LastName = 'Springsteen',
            Company = 'E Street Industries',
            Email = 'bruce.springsteen@example.com',
            LeadSource = 'Direct',
            Industry = 'Media',
            NumberOfEmployees = 70,
            Website = 'brucespringsteen.net',
            NumberOfSFUsers__c = 10000,
            No_of_people_making_changes_to_SF__c = 10
        );
        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Demo Booked');
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        // Act by inserting something from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.Source = 'unknown-campaign';
        marketingLead.Surname = 'Springsteen';
        marketingLead.Company = 'E Street Industries';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that even though the campaign doesn't exist, we still have an activity
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(2, tasks.size(), 'Expected 1 task to be created for the downloaded asset');
    }

    @isTest
    public static void shouldAddContactAndLeadToCampaign() {
        // Arrange by making sure a Lead and Contact record already exists, and a Campaign exists
        Lead lead = new Lead(
            LastName = 'Springsteen',
            Company = 'E Street Industries',
            Email = 'bruce.springsteen@example.com',
            LeadSource = 'Direct',
            Industry = 'Media',
            NumberOfEmployees = 70,
            Website = 'brucespringsteen.net',
            NumberOfSFUsers__c = 10000,
            No_of_people_making_changes_to_SF__c = 10
        );
        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Demo Booked');
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        Campaign campaign = new Campaign(Name = 'Website backup campaign', Source__c = 'backup-ebook');
        insert campaign;

        // Act by inserting something from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.Source = 'backup-ebook';
        marketingLead.Surname = 'Springsteen';
        marketingLead.Company = 'E Street Industries';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that correct activities created, and correct campaign updated
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(2, tasks.size(), 'Expected 2 tasks to be created for the downloaded asset');

        List<CampaignMember> members = [SELECT Id, ContactId, LeadId FROM CampaignMember];
        System.assertEquals(1, members.size(), 'Expected 1 contact to be added to the campaign');
        System.assertEquals(
            members.get(0).ContactId,
            lcr.getContactId(),
            'The CampaignMember should be linked to the Contact'
        );
        System.assertEquals(lead.Id, members.get(0).LeadId, 'The CampaignMember should be linked to the Lead');
    }

    @isTest
    public static void shouldAddContactToCampaign() {
        // Arrange by making sure a Contact record already exists, and a Campaign exists
        Contact contact = new Contact(LastName = 'Springsteen', Email = 'bruce.springsteen@example.com');
        insert contact;

        Campaign campaign = new Campaign(Name = 'Website backup campaign', Source__c = 'backup-ebook');
        insert campaign;

        // Act by inserting something from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.Source = 'backup-ebook';
        marketingLead.Surname = 'Springsteen';
        marketingLead.Company = 'E Street Industries';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that correct activities created, and correct campaign updated
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created for the downloaded asset'); // Assert that the task has been created
        System.assertEquals(
            'Content Interaction: backup-ebook',
            tasks.get(0).Subject,
            'Expected the task subject to contain the marketing source'
        );

        List<CampaignMember> members = [SELECT Id FROM CampaignMember];
        System.assertEquals(1, members.size(), 'Expected 1 contact to be added to the campaign');
    }

    @isTest
    public static void shouldNotAssignNewLeadToGearbotIfSourceIsDevopsAssessment() {
        // Act by inserting a brand new person from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.FirstName = 'Bruce';
        marketingLead.Surname = 'Springsteen';
        marketingLead.PhoneNumber = '(833) 441-7687';
        marketingLead.Company = 'E Street Industries';
        marketingLead.Source = 'devops-assessment';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that a new lead has been created
        List<Lead> leads = [
            SELECT Id, Status, FirstName, LastName, Email, Company, Phone, LeadSource, OwnerId
            FROM Lead
        ];
        System.assertEquals(1, leads.size(), 'A new lead should have been created');
        System.assertEquals('Ready for SDR', leads.get(0).Status, 'The lead should be ready for SDR');
        System.assertEquals('Content', leads.get(0).LeadSource, 'The new lead should be a content based one');
        System.assertEquals('Bruce', leads.get(0).FirstName, 'First name should be copied from REST input');
        System.assertEquals('Springsteen', leads.get(0).LastName, 'Last name should be copied from REST input');
        System.assertEquals('(833) 441-7687', leads.get(0).Phone, 'Phone should be copied from REST input');
        System.assertEquals('E Street Industries', leads.get(0).Company, 'Company should be copied from REST input');
        System.assertNotEquals(gearbot.Id, leads.get(0).OwnerId, 'Lead should have not been assigned to gearbot');

        // Assert that the task has been created
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created ');
        System.assertEquals(
            'Content Interaction: Completed devops assesssment',
            tasks.get(0).Subject,
            'Expected the task subject to explain the marketing source'
        );
    }

    @isTest
    public static void shouldReassignExistingGearbotLeadIfSourceIsDevopsAssessment() {
        // Inserting an existing lead
        Lead lead = new Lead(
            LastName = 'Springsteen',
            Company = 'E Street Industries',
            Email = 'bruce.springsteen@example.com',
            LeadSource = 'Direct',
            Industry = 'Media',
            OwnerId = gearbot.Id
        );
        insert lead;

        // Act by inserting a brand new person from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.FirstName = 'Bruce';
        marketingLead.Surname = 'Springsteen';
        marketingLead.PhoneNumber = '(833) 441-7687';
        marketingLead.Company = 'E Street Industries';
        marketingLead.Source = 'devops-assessment';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that the existing lead has been reassigned
        List<Lead> leads = [SELECT OwnerId, Status FROM Lead];
        System.assertEquals(1, leads.size(), 'No new leads should have been created');
        System.assertNotEquals(gearbot.Id, leads.get(0).OwnerId, 'Lead should have been reassigned to someone else');
        System.assertEquals('Ready for SDR', leads.get(0).Status, 'The lead should be ready for SDR');

        // Assert that the task has been created
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created ');
        System.assertEquals(
            'Content Interaction: Completed devops assesssment',
            tasks.get(0).Subject,
            'Expected the task subject to explain the marketing source'
        );
    }

    @isTest
    public static void shouldNotReassignExistingPersonAssignedLeadIfSourceIsDevopsAssessment() {
        // Inserting an existing lead
        Lead lead = new Lead(
            LastName = 'Springsteen',
            Company = 'E Street Industries',
            Email = 'bruce.springsteen@example.com',
            LeadSource = 'Direct',
            Industry = 'Media',
            OwnerId = jacques.Id,
            Status = 'New'
        );
        insert lead;

        // Act by inserting a brand new person from the static website
        SalesforceMarketingLead marketingLead = new SalesforceMarketingLead();
        marketingLead.Email = 'bruce.springsteen@example.com';
        marketingLead.FirstName = 'Bruce';
        marketingLead.Surname = 'Springsteen';
        marketingLead.PhoneNumber = '(833) 441-7687';
        marketingLead.Company = 'E Street Industries';
        marketingLead.Source = 'devops-assessment';
        new MarketingLeadService().upsertLead(marketingLead);

        // Assert that the existing lead has not been reassigned
        List<Lead> leads = [SELECT OwnerId, Status FROM Lead];
        System.assertEquals(1, leads.size(), 'No new leads should have been created');
        System.assertEquals(jacques.Id, leads.get(0).OwnerId, 'Lead should not have been reassigned ');
        System.assertEquals('New', leads.get(0).Status, 'The lead should retain its original status');

        // Assert that the task has been created
        List<Task> tasks = [SELECT Id, Status, Subject FROM Task];
        System.assertEquals(1, tasks.size(), 'Expected 1 task to be created ');
        System.assertEquals(
            'Content Interaction: Completed devops assesssment',
            tasks.get(0).Subject,
            'Expected the task subject to explain the marketing source'
        );
    }
}
