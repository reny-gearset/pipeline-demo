@IsTest
public class TestContactController {
    @isTest static void testUpdateContactAddress() {        
        Id contactId = setupContact();
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/Contact/' + contactId;
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        
        String requestJson = '{' +
            '"mailingCity": "New Cambridge",' + 
            '"mailingState": "New Cambridgeshire",' + 
            '"mailingCountry": "New England",' + 
            '"mailingPostalCode": "ABC 123",' + 
            '"mailingStreet": "123 New street"' +
        '}';
        
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;
        
        ContactController.updateContactAddress();
        
        Contact contact = [
            SELECT
                MailingCity,
                MailingState,
                MailingCountry,
                MailingPostalCode,
                MailingStreet
            FROM Contact
            WHERE Id = :contactId
        ];
        
        System.assertEquals('New Cambridge', contact.MailingCity);
        System.assertEquals('New Cambridgeshire', contact.MailingState);
        System.assertEquals('New England', contact.MailingCountry);
        System.assertEquals('ABC 123', contact.MailingPostalCode);
        System.assertEquals('123 New street', contact.MailingStreet);  
    }
    
    static Id setupContact() {
        Contact contactTest = new Contact(
            LastName = 'Contact'
        );
        
        insert contactTest;
        
        return contactTest.Id;
    }
}