@IsTest
public class TestDataTrialLeadController {
    private static final Logger LOGGER = LogFactory.create(TestDataTrialLeadController.class);

    @isTest static void testCreateDataTrialLead() {
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/DataDeploymentTrialLead/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        
        String testTeamId = '2027f58d-35ef-4101-b237-9b6378fa74c2';
        
        String requestJson = '{' +
            '"email": "new@email.com",' + 
            '"teamId": ' + '"2027f58d-35ef-4101-b237-9b6378fa74c2"' +
        '}';
        
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;
        
        setupAccount(testTeamId);
        
        DataTrialLeadController.DataDeploymentTrialLeadResponse response = DataTrialLeadController.createDataDeploymentTrialLead();
        
        Lead createdTrial = [ SELECT Name, LeadSource, Status, Email FROM Lead WHERE Id = :response.leadId ];
        
        System.assertEquals('Data deployment trial for Firstname Contact', createdTrial.Name);
        System.assertEquals('Trialist', createdTrial.LeadSource);
        System.assertEquals('New', createdTrial.Status);      
        System.assertEquals('new@email.com', createdTrial.Email); 
    }
    
    static void setupAccount(String teamId) {
        Gearset_team__c t = new Gearset_team__c(
            Gearset_Team_Id__c = teamId
        );
        upsert t;

        LOGGER.info('Inserted test Gearset_team__c with Id {0}', t.Id);
        
        Account accountTest = new Account(
            Name = 'TestAccount',
            Gearset_team__c = t.Id
        );
        
        insert accountTest;
        
        Contact contactTest = new Contact(
            FirstName = 'Firstname',
            LastName = 'Contact',
            Email = 'new@email.com',
            AccountId = accountTest.Id
        );
        
        insert contactTest;        
    }
}