@RestResource(urlMapping='/MarketingLead/*')
global with sharing class MarketingLeadController {
    private static final Logger LOGGER = LogFactory.create(MarketingLeadController.class);

    @HttpPost
    global static String upsertLead(SalesforceMarketingLead info) {
        LOGGER.info('Upserting marketing lead to campaign');

        return new MarketingLeadService().upsertLead(info);
    }
}
