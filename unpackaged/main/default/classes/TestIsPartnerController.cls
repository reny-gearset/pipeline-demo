@IsTest
public class TestIsPartnerController {
    @isTest static void testNoTeamIdProvided() {
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/IsPartner';
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        
        Boolean response = IsPartnerController.isPartner();
        System.assertEquals(false, response);
    }
    
    @isTest static void testNonPartnerTeamId() {
        String teamId = setupNonPartnerAccountWithTeamId();
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/IsPartner';
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        request.addParameter('gearset_team_id', teamId);
        
        Boolean response = IsPartnerController.isPartner();
        System.assertEquals(false, response);
    }
    
    @isTest static void testPartnerTeamId() {
        String teamId = setupPartnerAccountWithTeamId();
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/IsPartner';
        request.httpMethod = 'GET';
        
        RestContext.request = request;
        request.addParameter('gearset_team_id', teamId);
        
        Boolean response = IsPartnerController.isPartner();
        System.assertEquals(true, response);
    }
    
    static string setupNonPartnerAccountWithTeamId() {
        Gearset_Team__c team = new Gearset_Team__c(
            Gearset_Team_Id__c = 'test team id', 
            Name = 'test team'
        );
        
        insert team;
        
        Account nonPartnerAccount = new Account(
        	Name = 'Non Partner 1 With Team Id',
            Gearset_Team__c = team.Id
        );
        
        insert nonPartnerAccount;
        
        return team.Gearset_Team_Id__c;
    }
    
    static string setupPartnerAccountWithTeamId() {
        Gearset_Team__c team = new Gearset_Team__c(
            Gearset_Team_Id__c = 'test team id', 
            Name = 'test team'
        );
        
        insert team;
        
        Account partnerAccount = new Account(
        	Name = 'Partner 1 With Team Id',
            Type = 'Implementation Partner',
            Gearset_Team__c = team.Id
        );
        
        insert partnerAccount;
        
        return team.Gearset_Team_Id__c;
    }
}