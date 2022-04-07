@RestResource(urlMapping='/HandleCreatedQuote')
global without sharing class WebsiteQuoteLeadController {
    @HttpPost
    global static void handleCreatedQuote() {
        RestRequest restRequest = RestContext.request;
        HandleCreatedQuoteRequest request = (HandleCreatedQuoteRequest) JSON.deserialize(
            restRequest.requestbody.tostring(),
            HandleCreatedQuoteRequest.class
        );

        WebsiteQuoteLeadService websiteQuoteLeadService = new WebsiteQuoteLeadService();
        websiteQuoteLeadService.handleCreatedQuote(request.leadEmail, request.quoteReference, request.quoteUrl);
    }

    global class HandleCreatedQuoteRequest {
        global String leadEmail { get; set; }
        global String quoteReference { get; set; }
        global String quoteUrl { get; set; }
    }
}
