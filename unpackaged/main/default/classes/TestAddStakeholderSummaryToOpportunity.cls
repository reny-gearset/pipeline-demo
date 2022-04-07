@isTest
private class TestAddStakeholderSummaryToOpportunity {
    @isTest
    public static void shouldAddStakeholderSummaryToOpportunity() {
        Lead myLead = new Lead(
            LastName = 'Kuiper',
            Company = 'Gearset',
            LeadSource = 'Direct',
            Industry = 'Hi Tech',
            NumberOfEmployees = 70,
            Website = 'gearset.com',
            NumberOfSFUsers__c = 42,
            No_of_people_making_changes_to_SF__c = 10,
            Discovery_Notes__c = 'Test discovery notes',
            How_they_currently_use_Salesforce__c = 'Test how they currently use Salesforce',
            Pains_and_aims__c = 'Test pains and aims'
        );

        insert myLead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.Id);

        lc.setConvertedStatus('Demo Booked');

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        System.assert(lcr.isSuccess());

        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Stakeholder_Summary__c FROM Opportunity WHERE Id = :opportunityId];

        String summary = opp.Stakeholder_Summary__c;

        System.assert(summary.contains('Test pains and aims'));
    }
}
