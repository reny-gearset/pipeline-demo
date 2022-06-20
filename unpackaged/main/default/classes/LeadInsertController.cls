@RestResource(urlMapping='/LeadImport/*')
global with sharing class LeadInsertController {
    @HttpPost
    global static LeadResponse upsertLead(LeadInfo info) {
        List<SignupObjectImpact> result = LeadIngestionService.upsertLead(info);

        return new LeadResponse(result);
    }

    global class LeadResponse {
        public LeadResponse(List<SignupObjectImpact> impactedObjects) {
            this.impactedObjects = impactedObjects;
        }

        global List<SignupObjectImpact> impactedObjects;
    }
}