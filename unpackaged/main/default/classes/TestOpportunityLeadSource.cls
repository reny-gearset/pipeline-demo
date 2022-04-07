@isTest
private class TestOpportunityLeadSource {

    @isTest static void shouldRefuseToCreateOpportunityWithLeadSourceJoiningTeam() {
        Opportunity o;

        try {
            o = createOpportunityWithLeadSource('Joining Team');
        }
        catch(DmlException e) {
            AssertItFiredTheCorrectValidationRule(e);
        }

        System.assertEquals(null, o, 'Opportunity should not have been created.');
    }

    @isTest static void shouldRefuseToUpdateOpportunityWithLeadSourceJoiningTeam() {
        Opportunity o = createOpportunityWithLeadSource('Direct');

        try {
            o.LeadSource = 'Joining Team';
            update o;
        }
        catch(DmlException e) {
            AssertItFiredTheCorrectValidationRule(e);
        }

        Opportunity notUpdatedOpportunity = [SELECT LeadSource FROM Opportunity WHERE Id = :o.Id];

        System.assertEquals('Direct', notUpdatedOpportunity.LeadSource, 'Opportunity should not have been updated.');
    }

    @isTest static void shouldRefuseToConvertLeadToOpportunityWithLeadSourceJoiningTeam() {
        Database.LeadConvertResult lcr;

        try {
            lcr = createAndConvertLeadWithLeadSource('Joining Team');
        }
        catch(DmlException e) {
            AssertItFiredTheCorrectValidationRule(e);
        }

        System.assertEquals(null, lcr, 'Lead should not have been converted to an Opportunity.');
    }

    private static Opportunity createOpportunityWithLeadSource(string leadSource) {
        Opportunity o = new Opportunity(
            Name = 'Test opportunity',
            CloseDate = Date.today().addDays(3),
            StageName = 'Invoice Issued',
            LeadSource = leadSource,
            Type = 'New'
        );

        insert o;
        return o;
    }

    private static Database.LeadConvertResult createAndConvertLeadWithLeadSource(string leadSource) {
        Lead myLead = new Lead(
            LastName = 'Baldrick',
            Company = 'Gearset',
            LeadSource = leadSource
        );

        insert myLead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.setConvertedStatus('Existing Account');

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        return lcr;
    }

    private static void assertItFiredTheCorrectValidationRule(DmlException e) {
        System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        System.Assert(e.getMessage().contains('Lead Source'));
        System.Assert(e.getMessage().contains('Joining team'));
    }
}