@isTest
private class TestContactInformationController {
    @isTest
    public static void shouldDoNothingIfNoLeadOrContactExists() {
        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'gwilym@gearset.com.production';
        ocr.source = 'UserSubmitted';
        ocr.phoneNumber = '01223 333 333';

        ContactInformationController.addOrgConnection(ocr);

        List<Org_Connection__c> orgConnections = [SELECT Id FROM Org_Connection__c];
        System.assertEquals(0, orgConnections.size());
    }

    @isTest
    public static void shouldAddPhoneToLeadIfNoNumberCurrentlySet() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Email = 'gwilym@gearset.com', LeadSource = 'Direct');
        insert l;

        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'gwilym@gearset.com.production';
        ocr.source = 'UserSubmitted';
        ocr.phoneNumber = '01223 333 333';

        ContactInformationController.addOrgConnection(ocr);

        // We shouldn't have created an OrgConnection__c as the phone number source is UserSubmitted
        List<Org_Connection__c> orgConnections = [SELECT Id FROM Org_Connection__c];
        System.assertEquals(0, orgConnections.size());

        List<Lead> leads = [SELECT Id, Phone FROM Lead];
        System.assertEquals(1, leads.size());

        Lead updatedLead = leads.get(0);
        System.assertEquals(updatedLead.Phone, '01223 333 333');
    }

    @isTest
    public static void shouldAddOrgConnectionIfLeadAlreadyHasPhoneNumber() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Email = 'gwilym@gearset.com', Phone = '01224 444 444', LeadSource = 'Direct');
        insert l;

        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'initial.gwilym@gearset.com.production';
        ocr.source = 'UserSubmitted';
        ocr.phoneNumber = '01223 333 333';

        ContactInformationController.addOrgConnection(ocr);

        // The org connection should store the additional number we've been given during profile signup
        List<Org_Connection__c> orgConnections = [SELECT Id, Lead__c, Org_Username__c, Phone__c FROM Org_Connection__c];
        System.assertEquals(1, orgConnections.size());
        Org_Connection__c oc = orgConnections.get(0);
        System.assertEquals(oc.Lead__c, l.Id);
        System.assertEquals(oc.Org_Username__c, 'initial.gwilym@gearset.com.production');
        System.assertEquals(oc.Phone__c, '01223 333 333');

        List<Lead> leads = [SELECT Id, Phone FROM Lead];
        System.assertEquals(1, leads.size());

        // The lead should be unchanged. Whatever was there before wins.
        Lead updatedLead = leads.get(0);
        System.assertEquals(updatedLead.Phone, '01224 444 444');
    }

    @isTest
    public static void shouldAddOrgConnectionForLeadIfOAuthNumberDoesNotAlreadyExist() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Email = 'gwilym@gearset.com', LeadSource = 'Direct');
        insert l;

        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'gwilym@gearset.com.production';
        ocr.source = 'OAuth';
        ocr.phoneNumber = '01223 333 333';

        ContactInformationController.addOrgConnection(ocr);

        List<Org_Connection__c> orgConnections = [SELECT Id, Lead__c, Org_Username__c, Phone__c FROM Org_Connection__c];
        System.assertEquals(1, orgConnections.size());

        Org_Connection__c oc = orgConnections.get(0);
        System.assertEquals(oc.Lead__c, l.Id);
        System.assertEquals(oc.Org_Username__c, 'gwilym@gearset.com.production');
        System.assertEquals(oc.Phone__c, '01223 333 333');
    }

    @isTest
    public static void shouldNotAddOrgConnectionForLeadIfOAuthDoesAlreadyExist() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset', Email = 'gwilym@gearset.com', LeadSource = 'Direct');
        insert l;

        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'gwilym@gearset.com.production';
        ocr.source = 'OAuth';
        ocr.phoneNumber = '01223 333 333';

        // Run twice, second time should be a no-op
        ContactInformationController.addOrgConnection(ocr);
        ContactInformationController.addOrgConnection(ocr);

        List<Org_Connection__c> orgConnections = [SELECT Id, Lead__c, Org_Username__c, Phone__c FROM Org_Connection__c];
        System.assertEquals(1, orgConnections.size());

        Org_Connection__c oc = orgConnections.get(0);
        System.assertEquals(oc.Lead__c, l.Id);
        System.assertEquals(oc.Org_Username__c, 'gwilym@gearset.com.production');
        System.assertEquals(oc.Phone__c, '01223 333 333');
    }

    @isTest
    public static void shouldAddOrgConnectionForContactIfOAuthNumberDoesNotAlreadyExist() {
        Contact c = new Contact(LastName = 'Kuiper', Email = 'gwilym@gearset.com');
        insert c;

        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'gwilym@gearset.com.production';
        ocr.source = 'OAuth';
        ocr.phoneNumber = '01223 333 333';

        ContactInformationController.addOrgConnection(ocr);

        List<Org_Connection__c> orgConnections = [
            SELECT Id, Contact__c, Org_Username__c, Phone__c
            FROM Org_Connection__c
        ];
        System.assertEquals(1, orgConnections.size());

        Org_Connection__c oc = orgConnections.get(0);
        System.assertEquals(oc.Contact__c, c.Id);
        System.assertEquals(oc.Org_Username__c, 'gwilym@gearset.com.production');
        System.assertEquals(oc.Phone__c, '01223 333 333');
    }

    @isTest
    public static void shouldNotAddOrgConnectionForContactIfOAuthNumberDoesAlreadyExist() {
        Contact c = new Contact(LastName = 'Kuiper', Email = 'gwilym@gearset.com');
        insert c;

        ContactInformationController.OrgConnectionRequest ocr = new ContactInformationController.OrgConnectionRequest();
        ocr.email = 'gwilym@gearset.com';
        ocr.orgName = 'gwilym@gearset.com.production';
        ocr.source = 'OAuth';
        ocr.phoneNumber = '01223 333 333';

        // Run twice, second time should be a no-op
        ContactInformationController.addOrgConnection(ocr);
        ContactInformationController.addOrgConnection(ocr);

        List<Org_Connection__c> orgConnections = [
            SELECT Id, Contact__c, Org_Username__c, Phone__c
            FROM Org_Connection__c
        ];
        System.assertEquals(1, orgConnections.size());

        Org_Connection__c oc = orgConnections.get(0);
        System.assertEquals(oc.Contact__c, c.Id);
        System.assertEquals(oc.Org_Username__c, 'gwilym@gearset.com.production');
        System.assertEquals(oc.Phone__c, '01223 333 333');
    }
}