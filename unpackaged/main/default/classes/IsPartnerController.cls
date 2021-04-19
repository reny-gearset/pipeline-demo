@RestResource(urlMapping='/IsPartner')
global with sharing class IsPartnerController {
    @HttpGet
    global static Boolean isPartner() {
        RestRequest request = RestContext.request;
        
        String teamId = request.params.get('gearset_team_id');
        
        if (String.isBlank(teamId)) {
            return false;
        }
        
        List<Account> partnerAccounts = 
            [SELECT Id 
             FROM Account 
             WHERE Type = 'Implementation Partner' AND Gearset_Team__r.Gearset_Team_Id__c = :teamId LIMIT 1 ];
        
        return !partnerAccounts.isEmpty();
    }
}