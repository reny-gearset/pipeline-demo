@RestResource(urlMapping='/DataBackupTrialLead')
global without sharing class DataBackupTrialLeadController {
    private static final Logger LOGGER = LogFactory.create(DataBackupTrialLeadController.class);

    @HttpPost
    global static DataBackupTrialLeadResponse createDataBackupTrialLead() {
        LOGGER.info('Creating Data Backup trial lead');

        RestRequest restRequest = RestContext.request;
        String requestBody = restRequest.requestbody.tostring();

        LOGGER.info('Deserializing request body {0}', requestbody);

        DataBackupTrialLeadRequest request = (DataBackupTrialLeadRequest) JSON.deserialize(
            requestBody,
            DataBackupTrialLeadRequest.class
        );

        Id expansionLeadId = ExpansionService.createDataBackupTrialLead(request.teamId, request.email);

        DataBackupTrialLeadResponse response = new DataBackupTrialLeadResponse();
        response.leadId = expansionLeadId;
        return response;
    }

    global class DataBackupTrialLeadRequest {
        global string email { get; set; }
        global string teamId { get; set; }
    }

    global class DataBackupTrialLeadResponse {
        global Id leadId { get; set; }
    }
}