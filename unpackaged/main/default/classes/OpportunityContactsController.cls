@RestResource(urlMapping='/Opportunity/*/Contacts')
global without sharing class OpportunityContactsController {
    @HttpGet
    global static List<OpportunityContactResponse> getOpportunityContacts() {
        RestRequest request = RestContext.request;

        String opportunityId = request.requestURI.substringBetween('/Opportunity/','/Contacts');
        
        Opportunity opportunityContactRoles = [ 
            SELECT
            	Account.Id,
            	(SELECT
                 	Contact.Account.Name,
                    Contact.Id,
                    Contact.FirstName,
                    Contact.LastName,
                    Contact.Phone,
                    Contact.Email,
                    Contact.MailingCity,
                    Contact.MailingState,
                    Contact.MailingCountry,
                    Contact.MailingPostalCode,
                    Contact.MailingStreet FROM OpportunityContactRoles
                )
            FROM Opportunity
            WHERE Id = :opportunityId 
        ];
        
        List<OpportunityContactResponse> opportunityContactResponses = new List<OpportunityContactResponse>();
        
        for (OpportunityContactRole opportunityContactRole: opportunityContactRoles.OpportunityContactRoles) {
            OpportunityContactResponse opportunityContactResponse = new OpportunityContactResponse();

			opportunityContactResponse.opportunityAccountId = opportunityContactRoles.Account.Id;
            
            opportunityContactResponse.ContactId = opportunityContactRole.Contact.Id;
            opportunityContactResponse.CompanyName = opportunityContactRole.Contact.Account.Name;
            opportunityContactResponse.FirstName = opportunityContactRole.Contact.FirstName;
            opportunityContactResponse.LastName = opportunityContactRole.Contact.LastName;
            opportunityContactResponse.Phone = opportunityContactRole.Contact.Phone;
            opportunityContactResponse.Email = opportunityContactRole.Contact.Email;
            opportunityContactResponse.MailingCity = opportunityContactRole.Contact.MailingCity;
            opportunityContactResponse.MailingState = opportunityContactRole.Contact.MailingState;
            opportunityContactResponse.MailingCountry = opportunityContactRole.Contact.MailingCountry;
            opportunityContactResponse.MailingPostalCode = opportunityContactRole.Contact.MailingPostalCode;
            opportunityContactResponse.MailingStreet = opportunityContactRole.Contact.MailingStreet;
            
            opportunityContactResponses.add(opportunityContactResponse);
        }        
        
        return opportunityContactResponses;       
    }
    
    global class OpportunityContactResponse {
        global Id contactId { get; set; }
        global Id opportunityAccountId { get; set; }
        global String companyName { get; set; }
        global String firstName { get; set; }
        global String lastName { get; set; }
        global String phone { get; set; }
        global String email { get; set; }
        global String mailingCity { get; set; }
        global String mailingState { get; set; }
        global String mailingCountry { get; set; }
        global String mailingPostalCode { get; set; }
        global String mailingStreet { get; set; }        
    }
}