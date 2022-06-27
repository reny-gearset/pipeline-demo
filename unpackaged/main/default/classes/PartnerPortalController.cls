@RestResource(urlMapping='/ShouldShowPartnerPortal')
global with sharing class PartnerPortalController {
    @HttpGet
    global static Boolean shouldShow() {
        RestRequest request = RestContext.request;
        String teamId = request.params.get('gearset_team_id');
        
        return PartnerService.shouldShowPartnerPortal(teamId);
    }
}