@isTest
private class TestUpdateOrgConnectionOnLeadConversion {
    @isTest
    public static void shouldAddContactToOrgConnectionOnConversion() {
        Lead myLead = new Lead(
            LastName = 'Kuiper',
            Company = 'Gearset',
            LeadSource = 'Direct',
            Industry = 'Hi Tech',
            NumberOfEmployees = 70,
            Website = 'gearset.com',
            NumberOfSFUsers__c = 42,
            No_of_people_making_changes_to_SF__c = 10
        );

        insert myLead;

        Org_Connection__c oc = new Org_Connection__c(
            Org_Username__c = 'gwilym@gearset.com.dev',
            Phone__c = '01223 333 333',
            Lead__c = myLead.Id
        );

        insert oc;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.setConvertedStatus('Demo Booked');

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        Id contactId = lcr.getContactId();
        Org_Connection__c newOc = [SELECT Contact__r.Id FROM Org_Connection__c WHERE Id = :oc.Id];

        System.assertEquals(contactId, newOc.Contact__r.Id);
    }
}
