@RestResource(urlMapping='/LeadImport/*')
global with sharing class LeadImporter {
    @HttpPost
    global static LeadResponse upsertLead(LeadInfo info) {
        List<SignupObjectImpact> result = LeadIngestionService.upsertLead(info);

        return new LeadResponse(result);
    }

    global class LeadInfo {
        global String firstName;
        global String lastName;
        global String email;
        global String telephone;
        global String intercomUrl;
        global Boolean isAcceptingTeamInvite;
        global Boolean isNewUser;
        global String teamInviteTargetTeamId;
    }

    global class LeadResponse {
        public LeadResponse(List<SignupObjectImpact> impactedObjects) {
            this.impactedObjects = impactedObjects;
        }

        global List<SignupObjectImpact> impactedObjects;
    }
}
