@RestResource(urlMapping='/RenewalOpportunity/*')
global without sharing class RenewalOpportunityController {
    private static final Logger LOGGER = LogFactory.create(RenewalOpportunityController.class);
    
    @HttpPost
    global static TeamRenewalsResponse processRenewal() {
        RestRequest request = RestContext.request;
        
        String requestBody = request.requestbody.tostring();
        LOGGER.info('Deserializing request body {0}', requestbody);
        
        TeamRenewalsRequest teamRenewalRequest = (TeamRenewalsRequest) JSON.deserialize(
            requestBody,
            TeamRenewalsRequest.class
        );
        
        List<TeamLicenseRenewal> teamLicenseRenewals = new List<TeamLicenseRenewal>();
        
        for (LicenseRenewalRequest renewalRequest : teamRenewalRequest.teamRenewals) {
            String teamId = renewalRequest.teamId;
            List<LicenseRenewalData> renewals = new List<LicenseRenewalData>();
            
            for (LicenseRenewalDataRequest licenseRenewalDataRequest: renewalRequest.expiringLicenses) {
                renewals.add(new LicenseRenewalData(
                    licenseRenewalDataRequest.licenseId,
                    licenseRenewalDataRequest.licensePlanName,
                    licenseRenewalDataRequest.licenseQuantity,
                    licenseRenewalDataRequest.fastspringReference));
            }
            
            teamLicenseRenewals.add(new TeamLicenseRenewal(teamId, renewals));
        }
        
        List<CreatedRenewalOpportunity> createdRenewalOpportunities = RenewalOpportunityService.createRenewalOpportunities(teamLicenseRenewals);
        
        List<CreatedRenewalOpportunityResponse> renewalResponses = new List<CreatedRenewalOpportunityResponse>();
        
        for (CreatedRenewalOpportunity renewalOpportunity : createdRenewalOpportunities) {
            renewalResponses.add(new CreatedRenewalOpportunityResponse(renewalOpportunity.opportunityId, renewalOpportunity.licenseIds));
        }
        
        return new TeamRenewalsResponse(renewalResponses);
    }
    
    global class TeamRenewalsRequest {
        global LicenseRenewalRequest[] teamRenewals { get; set; }
    }
    
    global class LicenseRenewalRequest {
        global String teamId { get; set; }
        global LicenseRenewalDataRequest[] expiringLicenses { get; set; }
    }
    
    global class LicenseRenewalDataRequest {
        public String licenseId { get; set; }
        public String licensePlanName { get; set; }
        public Integer licenseQuantity { get; set; }
        public String fastspringReference { get; set; }
    }
    
    global class CreatedRenewalOpportunityResponse {
        global CreatedRenewalOpportunityResponse(Id opportunityId, List<String> licenseIds) {
            this.opportunityId = opportunityId;
            this.licenseIds = licenseIds;
        }
        
        global Id opportunityId { get; private set; }
        global List<String> licenseIds { get; private set; }
    }
    
    global class TeamRenewalsResponse {
        public TeamRenewalsResponse(List<CreatedRenewalOpportunityResponse> renewalOpportunities) {
            this.renewalOpportunities = renewalOpportunities;
        }
        
        global List<CreatedRenewalOpportunityResponse> renewalOpportunities { get; private set; }
    }
}