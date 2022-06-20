@RestResource(urlMapping='/OrderCompleted/*')
global without sharing class OrderCompletedController {
    private static final Logger LOGGER = LogFactory.create(DataBackupTrialLeadController.class);
    
    @HttpPost
    global static void processOrderCompletion() {
        RestRequest request = RestContext.request;
        String requestBody = request.requestbody.tostring();
        String opportunityIdRaw = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        Id opportunityId = Id.valueOf(opportunityIdRaw);
        
        LOGGER.info('Deserializing request body {0}', requestbody);
        
        OrderCompletedRequest orderCompletedRequest = (OrderCompletedRequest) JSON.deserialize(
            requestBody,
            OrderCompletedRequest.class
        );
        
        addNoteToOpportunity(orderCompletedRequest, opportunityId);
        
        addTaskToOpportunity(orderCompletedRequest, opportunityId);
        
        updateOpportunityPaymentField(orderCompletedRequest.orderId , opportunityId);
    }
    
    private static void updateOpportunityPaymentField(String paymentId, Id opportunityId) {

        Opportunity opportunity = [SELECT Payment__c FROM Opportunity WHERE Id = :opportunityId];
        opportunity.Payment__c = paymentId;
        update opportunity;
    }
    
    private static void addNoteToOpportunity(OrderCompletedRequest orderCompletedRequest, Id opportunityId) {
        String title = String.format('Subscription reference: {0}', new List<String> { orderCompletedRequest.subscriptionReference });
        
        String content = '';
        content += String.format('<p>Order has been completed: {0}</p>', new List<String> { orderCompletedRequest.subscriptionReference });
        content += String.format('<p>Order ID: {0}</p>', new List<String> { orderCompletedRequest.orderId });
        content += String.format('<p>Product name: {0}</p>', new List<String> { orderCompletedRequest.productName });
        content += String.format('<p>Product quantity: {0}</p>', new List<Integer> { orderCompletedRequest.productQuantity });
        content += String.format('<p>Product price: {0} USD</p>', new List<String> { orderCompletedRequest.productPriceUsd });
        content += String.format('<p>Team ID: <a href="https://admin.gearsethq.com/#teams?id={0}">{0}</a></p>', new List<String> { orderCompletedRequest.teamId });
        
        NoteCreationService.createNote(opportunityId, title, content);
    }
    
    private static void addTaskToOpportunity(OrderCompletedRequest orderCompletedRequest, Id opportunityId) {
        User katharine = [SELECT Id FROM User WHERE Name = 'Katharine Darbishire' ];
        
        String subject = String.format('{0} x {1} from {2} has been assigned to {3}',
                                       new List<String> { 
                                           String.valueOf(orderCompletedRequest.productQuantity),
                                               orderCompletedRequest.productName,
                                               orderCompletedRequest.orderId,
                                               orderCompletedRequest.teamId
                                           });
        
        Task task = new Task(
            Subject = subject,
            Description = 'Verify that the order has resulted in the correct subscription type and quantity being set on the team. If any subscriptions were preassigned, then verify that we haven\'t given this team a duplicate subscription.',
            Status = 'Open',
            Priority = 'Normal',
            WhatId = opportunityId,
            OwnerId = katharine.Id,
            ActivityDate = Date.today()
        );
        
        insert task;
    }
    
    global class OrderCompletedRequest {
        global String subscriptionReference { get; set; }
        global String orderId { get; set; }
        global String productName { get; set; }
        global Integer productQuantity { get; set; }
        global String productPriceUsd { get; set; }
        global String teamId { get; set; }
    }
}