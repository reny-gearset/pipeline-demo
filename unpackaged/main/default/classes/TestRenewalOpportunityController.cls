@isTest
private class TestRenewalOpportunityController {
    private static final Logger LOGGER = LogFactory.create(TestRenewalOpportunityController.class);

    @isTest
    public static void shouldCreateRenewalOpportunityCorrectly() {        
        String testTeamId = 'f4d1a738-e8d8-4c1f-8cb5-8904fef2f076';

        Gearset_Team__c gt = new Gearset_Team__c(
            Gearset_Team_Id__c = testTeamId
        );
        upsert gt;

        LOGGER.info('Inserted test Gearset_team__c {0}', gt.Id);
        
        Account account = new Account();
        account.Name = 'Gearset';
        account.Gearset_team__c = gt.Id;
        insert account;
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/DataBackupTrialLead/' + testTeamId;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        
        String requestJson = '{' + 
            '"teamRenewals": [{' +
                '"teamId": "' + testTeamId + '",' +
                '"expiringLicenses": [{' +
                    '"licenseId": "abcd",' + 
                    '"licensePlanName": ' + '"Pro",' +
                    '"licenseQuantity": ' + '28,' +
                    '"fastspringReference": ' + '"GEA-123-123-123"' +
                '}]' + 
            '}]' +
        '}';
        
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;

        RenewalOpportunityController.TeamRenewalsResponse teamRenewalsResponse = RenewalOpportunityController.processRenewal();
        
        RenewalOpportunityController.CreatedRenewalOpportunityResponse renewalOpportunityResponse = teamRenewalsResponse.renewalOpportunities.get(0);

        System.assertEquals(renewalOpportunityResponse.licenseIds.get(0), 'abcd');
    }
}