@isTest
private class TestLeadAdditionalInformationController {
	@isTest
    public static void shouldUpdateTimezoneIfPassedOne() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', LeadSource = 'Inbound');
        insert l;
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/LeadUpdate/' + l.Id;
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        
        LeadAdditionalInformationController.LeadInformation info = new LeadAdditionalInformationController.LeadInformation();
        info.leadQuality = 'Tier5';
        info.timezone = 'CEST';
        
        LeadAdditionalInformationController.addAdditionalLeadInformation(info);
        
        Lead updatedLead = [SELECT Timezone__c FROM Lead WHERE Id = :l.Id];
        
        System.assertEquals('CEST', updatedLead.Timezone__c);
    }
    
    @isTest
    public static void shouldNotUpdateTimezoneIfNotPassedOne() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Timezone__c = 'GMT', LeadSource = 'Inbound');
        insert l;
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/LeadUpdate/' + l.Id;
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        
        LeadAdditionalInformationController.LeadInformation info = new LeadAdditionalInformationController.LeadInformation();
        info.leadQuality = 'Tier5';
        
        LeadAdditionalInformationController.addAdditionalLeadInformation(info);
        
        Lead updatedLead = [SELECT Timezone__c FROM Lead WHERE Id = :l.Id];
        
        System.assertEquals('GMT', updatedLead.Timezone__c);
    }
    
    @isTest
    public static void shouldUpdateRatingIfQualityIsSet() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Rating = 'Tier3', LeadSource = 'Inbound');
        insert l;
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/LeadUpdate/' + l.Id;
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        
        LeadAdditionalInformationController.LeadInformation info = new LeadAdditionalInformationController.LeadInformation();
        info.leadQuality = 'Tier5';
        
        LeadAdditionalInformationController.addAdditionalLeadInformation(info);
        
        Lead updatedLead = [SELECT Rating FROM Lead WHERE Id = :l.Id];
        
        System.assertEquals('Tier5', updatedLead.Rating);
    }
    
    @isTest
    public static void shouldNotUpdateRatingIfQualityIsUnknown() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Rating = 'Tier3', LeadSource = 'Inbound');
        insert l;
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/LeadUpdate/' + l.Id;
        request.httpMethod = 'PATCH';
        RestContext.request = request;
        
        LeadAdditionalInformationController.LeadInformation info = new LeadAdditionalInformationController.LeadInformation();
        info.leadQuality = 'Unknown';
        
        LeadAdditionalInformationController.addAdditionalLeadInformation(info);
        
        Lead updatedLead = [SELECT Rating FROM Lead WHERE Id = :l.Id];
        
        System.assertEquals('Tier3', updatedLead.Rating);
    }

    @isTest
    public static void shouldNotUpdateLeadIfGivenOpportunityId() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Rating = 'Tier3', LeadSource = 'Inbound', Industry = 'Retail', NumberOfEmployees = 3, Website = 'unknown.example.com');
        insert l;

        Database.LeadConvertResult lcr = convertLead(l);
        Id opportunityId = lcr.getOpportunityId();

        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/LeadUpdate/' + opportunityId;
        request.httpMethod = 'PATCH';
        RestContext.request = request;

        LeadAdditionalInformationController.LeadInformation info = new LeadAdditionalInformationController.LeadInformation();
        info.leadQuality = 'Tier1';

        LeadAdditionalInformationController.addAdditionalLeadInformation(info);

        Lead updatedLead = [SELECT Rating FROM Lead WHERE Id = :l.Id];

        System.assertEquals('Tier3', updatedLead.Rating);
    }

    private static Database.LeadConvertResult convertLead(Lead l) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus('Demo Booked');

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        return lcr;
    }
}