@RestResource(urlMapping='/Contact/*')
global with sharing class ContactController {
	@HttpPatch
    global static void updateContactAddress () {
            
        RestRequest request = RestContext.request;
        String contactId = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
            
        UpdateContactAddressRequest updateContactAddressRequest = (UpdateContactAddressRequest) JSON.deserialize(request.requestbody.tostring(), UpdateContactAddressRequest.class);
        
        Contact contact = [ SELECT Id from Contact WHERE Id = :contactId ];
        
        contact.MailingCity = updateContactAddressRequest.mailingCity;
        contact.MailingState = updateContactAddressRequest.mailingState;
        contact.MailingCountry = updateContactAddressRequest.mailingCountry;
        contact.MailingPostalCode = updateContactAddressRequest.mailingPostalCode;
        contact.MailingStreet = updateContactAddressRequest.mailingStreet;
            
        update contact;
    }
}