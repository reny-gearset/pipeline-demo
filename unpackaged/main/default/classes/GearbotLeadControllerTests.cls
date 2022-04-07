@isTest
public class GearbotLeadControllerTests {
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];    
    
	@isTest
    static void reassignGearbotLeadsShouldReassignGearbotLead() {
		Lead testLead = insertLead('smith@email.com', gearbot.Id);
        
        RestContext.request = setupRestRequest(new List<String> { testLead.Email });        
        GearbotLeadController.reassignGearbotLeads();
        
        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];
        
        System.assertNotEquals(gearbot.Id, updatedLead.OwnerId);
    }
    
    @isTest
    static void reassignGearbotLeadsShouldCreateTaskForReassignedLeads() {
        Lead testLead = insertLead('lead@email.com', gearbot.Id);

        RestContext.request = setupRestRequest(new List<String> { testLead.Email });        
        GearbotLeadController.reassignGearbotLeads();

        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];
        Task createdTask = [SELECT Subject, Status, Priority, OwnerId, Description FROM Task WHERE WhoId = :updatedLead.Id];

        System.assertEquals('Can we get this lead to be an opp?', createdTask.Subject);
        System.assertEquals('Open', createdTask.Status);
        System.assertEquals('Normal', createdTask.Priority);
        System.assertEquals(updatedLead.OwnerId, createdTask.OwnerId);
        System.assertEquals('Lead lead@email.com needs triaging', createdTask.Description);
    }

    @isTest
    static void reassignGearbotLeadWithStatusNewShouldSetStatusToReadyForSdr() {
        Lead testLead = insertLead('new-lead@email.com', gearbot.Id);

        RestContext.request = setupRestRequest(new List<String> { testLead.Email });        
        GearbotLeadController.reassignGearbotLeads();

        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Ready for SDR', updatedLead.Status);
    }

    @isTest
    static void reassignGearbotLeadWithStatusNotNewShouldNotSetStatusToReadyForSdr() {
        Lead testLead = insertLead('new-lead@email.com', gearbot.Id, 'Researched');

        RestContext.request = setupRestRequest(new List<String> { testLead.Email });        
        GearbotLeadController.reassignGearbotLeads();

        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Researched', updatedLead.Status);
    }

    @isTest
    static void reassignGearbotLeadsShouldNotReassignNonGearbotLead() {
        List<User> sdrs = [SELECT Id FROM User WHERE UserRole.DeveloperName = 'Sales_Development_Representative' ORDER BY Email];
        Id sdrId = sdrs.get(0).Id;
        
		Lead testLead = insertLead('blah@email.com', sdrId);
        
        RestContext.request = setupRestRequest(new List<String> { testLead.Email });        
        GearbotLeadController.reassignGearbotLeads();
        
        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :testLead.Id];
        
        System.assertEquals(sdrId, updatedLead.OwnerId);
    }
    
    @isTest
    static void reassignGearbotLeadsShouldRoundRobinAssignees() {
        Lead leadOne = insertLead('one@email.com', gearbot.Id);        
		Lead leadTwo = insertLead('two@email.com', gearbot.Id);
        
        RestContext.request = setupRestRequest(new List<String> { leadOne.Email, leadTwo.Email });        
        GearbotLeadController.reassignGearbotLeads();
        
        Lead updatedLeadOne = [SELECT OwnerId FROM Lead WHERE Id = :leadOne.Id];
        Lead updatedLeadtwo = [SELECT OwnerId FROM Lead WHERE Id = :leadTwo.Id];
        
        System.assertNotEquals(updatedLeadOne.OwnerId, updatedLeadtwo.OwnerId);
    }
    
    private static Lead insertLead(String email, Id owner) {
        return insertLead(email, owner, 'New');
    }

    private static Lead insertLead(String email, Id owner, String status) {
        Lead testLead = new Lead();
        testLead.Email = email;
        testLead.OwnerId = owner;
        testLead.Status = status;
        testLead.LeadSource = 'Inbound';
        testLead.NumberOfEmployees = 1;
        testLead.LastName = 'Smith';
        testLead.Company = 'bigCo';
        
        insert testLead;
        
        return testLead;
    }
    
    private static RestRequest setupRestRequest(List<String> userEmails) {
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/ReassignGearbotLeads/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        
        String userEmailsForJson = '"' + String.join(userEmails, '","') + '"';
                
        String requestJson = '{' +
            '"userEmails": [' + userEmailsForJson + ']' + 
        '}';
        
        request.requestBody = Blob.valueOf(requestJson);
        
        return request;
    }
}