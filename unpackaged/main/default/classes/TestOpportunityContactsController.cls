@IsTest
public class TestOpportunityContactsController {
    @isTest static void testGetOpportunityAccountContacts() {
        Account opportunityAccount = new Account(
            Name = 'Opportunity account'
        );
        
        insert opportunityAccount;
        
        Id opportunityId = setupOpportunity(opportunityAccount);
        
        RestRequest request = new RestRequest();
        request.requestUri = 'https://instance.salesforce.com/services/apexrest/Opportunity/' + opportunityId + '/Contacts';
        request.httpMethod = 'GET';
        RestContext.request = request;
        
        List<OpportunityContactsController.OpportunityContactResponse> response = OpportunityContactsController.getOpportunityContacts();
        
        OpportunityContactsController.OpportunityContactResponse opportunityContact = response.get(0);
        
        System.assertEquals(opportunityAccount.Id, opportunityContact.opportunityAccountId);
        
        System.assertEquals('Contact account', opportunityContact.companyName);
        
        System.assertEquals('Test', opportunityContact.firstName);
        System.assertEquals('Contact', opportunityContact.lastName);
        System.assertEquals('1234567890', opportunityContact.phone);
        System.assertEquals('test@fake.com', opportunityContact.email);
        System.assertEquals('Cambridge', opportunityContact.mailingCity);
        System.assertEquals('Cambridgeshire', opportunityContact.mailingState);
        System.assertEquals('United Kingdom', opportunityContact.mailingCountry);
        System.assertEquals('CB4 2K3', opportunityContact.mailingPostalCode);
        System.assertEquals('Gearset avenue', opportunityContact.mailingStreet);        
    }
    
    static Id setupOpportunity(Account opportunityAccount) {       
        Account contactAccount = new Account(
        	Name = 'Contact account'
        );
        
        insert contactAccount;
        
        Contact contactTest = new Contact(
            AccountId = contactAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            Phone = '1234567890',
            Email = 'test@fake.com',
            MailingCity = 'Cambridge',
            MailingState = 'Cambridgeshire',
            MailingCountry = 'United Kingdom',
            MailingPostalCode = 'CB4 2K3',
            MailingStreet = 'Gearset avenue'
        );
        
        insert contactTest;
        
        Opportunity opportunityTest = new Opportunity(
            AccountId = opportunityAccount.Id,
            Name = 'Test opportunity',
            StageName = 'Discovery',
            CloseDate = date.today(),
            LeadSource = 'Direct',
            Type = 'New'
        );
            
        insert opportunityTest;
        
        OpportunityContactRole opportunityContactRoleTest = new OpportunityContactRole(
        	ContactId = contactTest.Id,
            OpportunityId = opportunityTest.Id
        );
        
        insert opportunityContactRoleTest;
        
        return opportunityTest.Id;
    }
}