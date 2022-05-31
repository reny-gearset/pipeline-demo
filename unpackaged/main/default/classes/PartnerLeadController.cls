@RestResource(urlMapping='/PartnerLead')
global with sharing class PartnerLeadController {
    private static final Logger LOGGER = LogFactory.create(PartnerLeadController.class);
    
    @HttpPost
    global static Boolean createPartnerReferralLead(PartnerLeadInfo info) {
        PartnerService.handlePartnerReferralLead(info);
        
        return true;
    }
    
    global class PartnerLeadInfo {
        global String contactCompanyName;
        global String contactEmail;
        global String contactFirstName;
        global String contactLastName;
        global String referrerCompanyName;
        global String referrerEmail;
        global String referrerFirstName;
        global String referrerLastName;
        global String extraDetails;
        global String teamId;
    }
}