@RestResource(urlMapping='/DataDeploymentTrialLead')
global without sharing class DataTrialLeadController {
    @HttpPost
    global static DataDeploymentTrialLeadResponse createDataDeploymentTrialLead() {
        RestRequest restRequest = RestContext.request;
        DataDeploymentTrialLeadRequest request = (DataDeploymentTrialLeadRequest) JSON.deserialize(restRequest.requestbody.tostring(), DataDeploymentTrialLeadRequest.class);
        
        Id expansionLeadId = ExpansionService.createDataDeploymentTrialLead(request.teamId, request.email);
        
        DataDeploymentTrialLeadResponse response = new DataDeploymentTrialLeadResponse();
        response.leadId = expansionLeadId;
        return response;
    }
    
    global class DataDeploymentTrialLeadRequest {
        global string email { get; set; }
        global string teamId { get; set; }
    }
        
    global class DataDeploymentTrialLeadResponse {
        global Id leadId { get; set; }
    }
}