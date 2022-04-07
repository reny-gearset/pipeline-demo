@isTest
private class LeadUtilitiesTests {
    @isTest
    public static void shouldSummariseLeadWithAllFields() {
        Lead l = new Lead(
        	LastName = 'Kuiper',
            Company = 'Gearset',
            Discovery_Notes__c = 'Test discovery notes',
            How_they_currently_use_Salesforce__c = 'Test how they currently use Salesforce',
            Pains_and_aims__c = 'Test pains and aims',
            Processes_and_environments__c = 'Test processes and environments',
            Team_structure__c = 'Test team structure'
        );
        
        String summary = LeadUtilities.stakeholderSummary(l);
        
        System.assert(summary.contains('Test discovery notes'));
        System.assert(summary.contains('Test how they currently use Salesforce'));
        System.assert(summary.contains('Test pains and aims'));
        System.assert(summary.contains('Test processes and environments'));
        System.assert(summary.contains('Test team structure'));
    }
    
    @isTest
    public static void shouldHandleLeadWithNoDiscoveryNotes() {
        Lead l = new Lead(LastName = 'Kuiper', Company = 'Gearset');
        String summary = LeadUtilities.stakeholderSummary(l);
        
        System.assert(summary.contains('No notes about current Salesforce use'));
    }
}