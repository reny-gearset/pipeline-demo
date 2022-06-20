@isTest
public class SummitLeadServiceTests {
    @isTest
    public static void shouldCreateLeadIfNoSimilarContactOrLeadExists() {
        SummitLead summitLead = createSummitLead(false);
        SummitLead[] summitLeads = new List<SummitLead>{ summitLead };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Lead storedLead = [
            SELECT FirstName, LastName, Phone, Company, NumberOfEmployees, Website, Title, Industry, LeadSource
            FROM Lead
            WHERE Email = :summitLead.email
        ];

        System.assertEquals(summitLead.firstName, storedLead.FirstName);
        System.assertEquals(summitLead.lastName, storedLead.LastName);
        System.assertEquals(summitLead.phone, storedLead.Phone);
        System.assertEquals(summitLead.company, storedLead.Company);
        System.assertEquals(summitLead.title, storedLead.Title);
        System.assertEquals(LeadConstants.DEFAULT_INDUSTRY, storedLead.Industry);
        System.assertEquals(LeadConstants.DEFAULT_NUMBER_OF_EMPLOYEES, storedLead.NumberOfEmployees);
        System.assertEquals(LeadConstants.DEFAULT_WEBSITE, storedLead.Website);
        System.assertEquals(LeadConstants.EVENT_SOURCE, storedLead.LeadSource);
    }

    @isTest
    public static void shouldUpdateLeadIfSimilarLeadExistsButNoContact() {
        User user = createUser();
        SummitLead summitLead = createSummitLeadWithExistingLead(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ summitLead };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Lead storedLead = [
            SELECT FirstName, LastName, Phone, Company, NumberOfEmployees, Website, Title, Industry, LeadSource
            FROM Lead
            WHERE Email = :summitLead.email
        ];

        System.assertEquals(summitLead.firstName, storedLead.FirstName);
        System.assertEquals(summitLead.lastName, storedLead.LastName);
        System.assertEquals(summitLead.phone, storedLead.Phone);
        System.assertEquals(summitLead.company, storedLead.Company);
        System.assertEquals(summitLead.title, storedLead.Title);
        System.assertNotEquals(LeadConstants.DEFAULT_INDUSTRY, storedLead.Industry);
        System.assertNotEquals(LeadConstants.DEFAULT_NUMBER_OF_EMPLOYEES, storedLead.NumberOfEmployees);
        System.assertNotEquals(LeadConstants.DEFAULT_WEBSITE, storedLead.Website);
        System.assertEquals(LeadConstants.DIRECT_SOURCE, storedLead.LeadSource);
    }

    @isTest
    public static void shouldNotInsertALeadIfAContactAlreadyExists() {
        User user = createUser();
        SummitLead summitLead = createSummitLeadWithExistingContact(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ summitLead };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Lead[] storedLead = [SELECT LastName, Company, LeadSource FROM Lead];

        System.assertEquals(0, storedLead.size());
    }

    @isTest
    public static void shouldCreateATaskForAllLeads() {
        User user = createUser();

        SummitLead newSummitLead = createSummitLead(false);
        SummitLead existingSummitLead = createSummitLeadWithExistingLead(true, user.Id, null);
        SummitLead existingSummitContact = createSummitLeadWithExistingContact(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ newSummitLead, existingSummitLead, existingSummitContact };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Task[] storedTasks = [SELECT Id FROM Task];

        System.assertEquals(summitLeads.size(), storedTasks.size());
    }

    @isTest
    public static void shouldCreateAttendedTasksForAttendees() {
        User user = createUser();

        SummitLead newSummitLead = createSummitLead(true);
        SummitLead existingSummitLead = createSummitLeadWithExistingLead(true, user.Id, null);
        SummitLead existingSummitContact = createSummitLeadWithExistingContact(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ newSummitLead, existingSummitLead, existingSummitContact };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Task[] storedTasks = [SELECT Id FROM Task WHERE Subject LIKE '%Attended'];

        System.assertEquals(2, storedTasks.size());
    }

    @isTest
    public static void shouldCreateNoShowTasksForAttendees() {
        User user = createUser();

        SummitLead newSummitLead = createSummitLead(true);
        SummitLead existingSummitLead = createSummitLeadWithExistingLead(false, user.Id, null);
        SummitLead existingSummitContact = createSummitLeadWithExistingContact(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ newSummitLead, existingSummitLead, existingSummitContact };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Task[] storedTasks = [SELECT Id FROM Task WHERE Subject LIKE '%No show'];

        System.assertEquals(2, storedTasks.size());
    }

    @isTest
    public static void taskSubjectShouldContainCampaignName() {
        User user = createUser();

        SummitLead newSummitLead = createSummitLead(true);
        SummitLead existingSummitLead = createSummitLeadWithExistingLead(false, user.Id, null);
        SummitLead existingSummitContact = createSummitLeadWithExistingContact(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ newSummitLead, existingSummitLead, existingSummitContact };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Task[] storedTasks = [SELECT Id FROM Task WHERE Subject LIKE :campaign.Name + '%'];

        System.assertEquals(summitLeads.size(), storedTasks.size());
    }

    @isTest
    public static void shouldAddSummitLeadsToCampaign() {
        User user = createUser();

        SummitLead newSummitLead = createSummitLead(true);
        SummitLead existingSummitLead = createSummitLeadWithExistingLead(false, user.Id, null);
        SummitLead existingSummitContact = createSummitLeadWithExistingContact(false, user.Id, null);
        SummitLead[] summitLeads = new List<SummitLead>{ newSummitLead, existingSummitLead, existingSummitContact };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        CampaignMember[] campaignMembers = [SELECT Id FROM CampaignMember WHERE CampaignId = :campaign.Id];

        System.assertEquals(summitLeads.size(), campaignMembers.size());
    }

    @isTest
    public static void shouldNotAddSummitLeadsToCampaignIfAlreadyAdded() {
        User user = createUser();

        Campaign campaign = createCampaign();
        SummitLead existingSummitLead = createSummitLeadWithExistingLead(false, user.Id, campaign.Id);
        SummitLead existingSummitContact = createSummitLeadWithExistingContact(false, user.Id, campaign.Id);
        SummitLead[] summitLeads = new List<SummitLead>{ existingSummitLead, existingSummitContact };

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        CampaignMember[] campaignMembers = [SELECT Id FROM CampaignMember WHERE CampaignId = :campaign.Id];

        System.assertEquals(summitLeads.size(), campaignMembers.size());
    }

    @isTest
    public static void taskDescriptionShouldContainNotes() {
        User user = createUser();

        SummitLead newSummitLead = createSummitLead(true);
        newSummitLead.notes = 'some summit notes';
        SummitLead[] summitLeads = new List<SummitLead>{ newSummitLead };
        Campaign campaign = createCampaign();

        new SummitLeadService().upsertLeads(summitLeads, campaign.Id);

        Task storedTask = [SELECT Description FROM Task WHERE Subject LIKE :campaign.Name + '%' LIMIT 1];

        System.assert(storedTask.Description.contains(newSummitLead.notes));
    }

    private static SummitLead createSummitLeadWithExistingLead(boolean attended, Id ownerId, Id campaignId) {
        SummitLead summitLead = new SummitLead();
        summitLead.attended = attended;
        summitLead.email = 'existing_lead@example.com';
        summitLead.firstName = 'Alfred';
        summitLead.lastName = 'Pennyworth';
        summitLead.phone = '15559876';
        summitLead.company = 'Wayne Enterpises';
        summitLead.title = 'Butler';

        Lead lead = new Lead();
        lead.Email = summitLead.email;
        lead.FirstName = null;
        lead.LastName = LeadConstants.DEFAULT_LAST_NAME;
        lead.Phone = null;
        lead.LeadSource = LeadConstants.DIRECT_SOURCE;
        lead.Company = LeadConstants.DEFAULT_COMPANY_NAME;
        lead.Website = 'example.com';
        lead.NumberOfEmployees = 999;
        lead.Title = null;
        lead.Industry = 'Spelunking';
        insert lead;

        if (campaignId != null) {
            addToCampaign(campaignId, lead, null);
        }

        return summitLead;
    }

    private static SummitLead createSummitLeadWithExistingContact(boolean attended, Id ownerId, Id campaignId) {
        SummitLead summitLead = new SummitLead();
        summitLead.attended = attended;
        summitLead.email = 'existing_contact@example.com';
        summitLead.firstName = 'Selina';
        summitLead.lastName = 'Kyle';
        summitLead.phone = '15551234';
        summitLead.company = 'Kitty Inc';
        summitLead.title = 'Jewel Thief';

        Contact contact = new Contact();
        contact.Email = summitLead.email;
        contact.FirstName = summitLead.firstName;
        contact.LastName = summitLead.lastName;
        contact.Phone = summitLead.phone;
        contact.OwnerId = ownerId;
        insert contact;

        if (campaignId != null) {
            addToCampaign(campaignId, null, contact);
        }

        return summitLead;
    }

    private static SummitLead createSummitLead(boolean attended) {
        SummitLead summitLead = new SummitLead();
        summitLead.attended = attended;
        summitLead.email = 'new_person@example.com';
        summitLead.firstName = 'Bruce';
        summitLead.lastName = 'Wayne';
        summitLead.phone = '15551234';
        summitLead.company = 'Wayne Enterpises Global';
        summitLead.title = 'CEO';
        return summitLead;
    }

    private static Campaign createCampaign() {
        Campaign campaign = new Campaign();
        campaign.Name = 'Some summit';
        insert campaign;
        return campaign;
    }

    private static void addToCampaign(Id campaignId, Lead lead, Contact contact) {
        CampaignMember member = new CampaignMember(
            CampaignId = campaignId,
            LeadId = lead == null ? null : lead.Id,
            ContactId = contact == null ? null : contact.Id
        );

        insert member;
    }

    private static User createUser() {
        User user = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert user;
        return user;
    }
}
