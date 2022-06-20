@IsTest
public class TestOrderCompletedController {
    @isTest static void processOrderCompletionShouldCreateNoteAndTask() {
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';
        Opportunity opportunity = setupOpportunity(testTeamId);
        Id opportunityId = opportunity.Id;
        
        RestRequest request = new RestRequest();
        request.requestUri = String.format('https://instance.salesforce.com/services/apexrest/OrderCompleted/{0}', new List<String> { opportunityId });
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        
        String requestJson = '{' + 
            '"subscriptionReference": "license123",' + 
            '"orderId": "GEA000000-1111-12345",' +
            '"productName": "Enterprise",' +
            '"productQuantity": 123,' +
            '"productPriceUsd": "billions and billions",' +
            '"teamId": "' + testTeamId + '"' +
        '}';
        
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;
        
        OrderCompletedController.processOrderCompletion();
        
        Task task = [SELECT Subject, Description FROM Task];
        ContentDocumentLink noteLink = [SELECT ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId];
        
        System.assertEquals(task.Subject, '123 x Enterprise from GEA000000-1111-12345 has been assigned to f4d1a738-e8d8-4c1f-8cb5-8904fef2f076');
        System.assertEquals(task.Description, 'Verify that the order has resulted in the correct subscription type and quantity being set on the team. If any subscriptions were preassigned, then verify that we haven\'t given this team a duplicate subscription.');
        System.assertEquals(noteLink.ContentDocument.Title, 'Subscription reference: license123');
    }
    
    public static Opportunity setupOpportunity(String testTeamId) {
        Gearset_Team__c team = new Gearset_Team__c(
            Gearset_Team_Id__c = testTeamId
        );
        upsert team;
        
        Account account = new Account();
        account.Name = 'Gearset';
        account.Gearset_team__c = team.Id;
        insert account;
        
        String recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Gearset Renewals Process').getRecordTypeId();
        
        Opportunity newOpportunity = new Opportunity(
            Name = 'opportunityName',
            AccountId = account.Id,
            CloseDate = System.today(),
            RecordTypeId = recordTypeId,
            StageName = 'Approaching Renewal',
            Renewal_Date__c = System.today(),
            Type = 'Renewal'
        );
        
        insert newOpportunity;
        
        return newOpportunity;
    }
}