@RestResource(urlMapping='/SummitLead/*')
global with sharing class SummitController {
    private static final Logger LOGGER = LogFactory.create(SummitController.class);

    @HttpPost
    global static void upsertLeads() {
        LOGGER.info('Upserting leads to campaign');

        RestRequest request = RestContext.request;

        String requestBody = request.requestbody.tostring();
        LOGGER.info('Deserializing request body {0}', requestbody);

        UpsertSummitLeadsRequest upsertSummitLeadsRequest = (UpsertSummitLeadsRequest) JSON.deserialize(
            requestBody,
            UpsertSummitLeadsRequest.class
        );

        new SummitLeadService().upsertLeads(upsertSummitLeadsRequest.leads, upsertSummitLeadsRequest.campaignId);
    }
}
