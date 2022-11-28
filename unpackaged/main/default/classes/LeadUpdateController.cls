@RestResource(urlMapping='/LeadUpdate/*')
global without sharing class LeadUpdateController {
	@HttpPatch
    global static void addAdditionalLeadInformation(LeadUpdateInfo additionalInformation) {
        RestRequest request = RestContext.request;
        String leadId = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);

        if (isOpportunityId(leadId)) {
            // it is an Opportunity, not a Lead, so there's nothing to do
            return;
        }

        Lead l = [SELECT Id FROM Lead WHERE Id = :leadId];
        
        // Null check will allow us to remove this in the future without breaking anything
        if (additionalInformation.leadQuality != 'Unknown' && additionalInformation.leadQuality != null) {
            l.Rating = additionalInformation.leadQuality;
        }

        if (additionalInformation.timezone != null) {
        	l.Timezone__c = additionalInformation.timezone;
        }
        
        if (additionalInformation.country != null) {
            l.Sign_In_Country__c = additionalInformation.country;
        }
        
        update l;
    } 

    private static boolean isOpportunityId(string recordIdString) {
        Id recordId = Id.valueOf(recordIdString);

        SObjectType recordType = recordId.getSObjectType();

        return recordType.getDescribe().getName() == 'Opportunity';
    }
}