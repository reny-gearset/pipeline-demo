@isTest
public class WebsiteQuoteLeadServiceTest {
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];

    @isTest
    static void shouldCreateNewLeadIfItDoesntExist() {
        WebsiteQuoteLeadService websiteQuoteLeadService = new WebsiteQuoteLeadService();
        websiteQuoteLeadService.handleCreatedQuote('new-lead@example.com', 'REF001', 'example.com');

        Lead createdLead = [
            SELECT Email, OwnerId, Name, Status, LeadSource
            FROM Lead
            WHERE Email = 'new-lead@example.com'
        ];

        System.assertEquals('new-lead@example.com', createdLead.Email);
        System.assertEquals('Web quote generated for new-lead@example.com', createdLead.Name);
        System.assertEquals('Ready for SDR', createdLead.Status);
        System.assertEquals('Direct', createdLead.LeadSource);

        // verify that task has been created and is correct
        Task createdTask = [
            SELECT Subject, Description, Status, Priority, WhoId, OwnerId
            FROM Task
            WHERE WhoId = :createdLead.Id
        ];

        System.assertEquals('Created quote on website', createdTask.Subject);
        System.assertEquals('Quote reference: REF001\nQuote URL: example.com', createdTask.Description);
        System.assertEquals('Open', createdTask.Status);
        System.assertEquals('Normal', createdTask.Priority);
        System.assertEquals(createdLead.OwnerId, createdTask.OwnerId);
    }

    @isTest
    static void shouldInsertTaskIfLeadAlreadyExists() {
        // create an existing lead
        Lead newLead = new Lead(
            FirstName = 'Bob',
            LastName = 'Vance',
            Email = 'bob.vance@example.com',
            OwnerId = gearbot.Id,
            Status = 'New',
            LeadSource = 'Outbound',
            Company = 'Bob Vance, Vance Refrigeration'
        );

        insert newLead;

        // run the lead creator
        WebsiteQuoteLeadService websiteQuoteLeadService = new WebsiteQuoteLeadService();
        websiteQuoteLeadService.handleCreatedQuote('bob.vance@example.com', 'THEOFFICEREFERENCE', 'example.com');

        // verify that the lead has not been modified
        Lead currentLead = [
            SELECT Id, OwnerId, Company, Email, Name, Status, LeadSource
            FROM Lead
            WHERE Email = 'bob.vance@example.com'
        ];

        System.assertEquals('bob.vance@example.com', currentLead.Email);
        System.assertEquals('Bob Vance', currentLead.Name);
        System.assertEquals('New', currentLead.Status);
        System.assertEquals('Outbound', currentLead.LeadSource);
        System.assertEquals('Bob Vance, Vance Refrigeration', currentLead.Company);

        // verify that task has been created and is correct
        Task createdTask = [
            SELECT Subject, Description, Status, Priority, WhoId, OwnerId
            FROM Task
            WHERE WhoId = :currentLead.Id
        ];

        System.assertEquals('Created quote on website', createdTask.Subject);
        System.assertEquals('Quote reference: THEOFFICEREFERENCE\nQuote URL: example.com', createdTask.Description);
        System.assertEquals('Open', createdTask.Status);
        System.assertEquals('Normal', createdTask.Priority);
        System.assertEquals(currentLead.OwnerId, createdTask.OwnerId);
    }
}
