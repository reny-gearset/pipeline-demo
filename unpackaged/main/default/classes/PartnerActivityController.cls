@RestResource(urlMapping='/PartnerActivity')
global with sharing class PartnerActivityController { 
    @HttpPost
    global static Boolean partnerPortalActivity(PartnerActivityInfo info) {
        PartnerService.handlePartnerActivity(info);
        
        return true;
    }
    
    global class PartnerActivityInfo {
        global String teamId;
        global String summary;
    }
}