@isTest
private class TestOpportunityTypeOnLeadConversion {
    @isTest static void shouldFillOpportunityTypeOnDemoBookedLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('Demo Booked');
        
        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertEquals(opp.Type, 'New');
    }
    
    @isTest static void shouldFillOpportunityTypeOnExistingAccountLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('Existing Account');
        
        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertEquals(opp.Type, 'New');
    }
    
    @isTest static void shouldFillOpportunityTypeOnProvidedEnoughInfoLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('No Demo - Provided Enough Info');
        
        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertEquals(opp.Type, 'New');
    }
    
    @isTest static void shouldFillOpportunityTypeOnQualifiedAsExpansionOpportunityLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('Qualified as Expansion Opportunity');
        
        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertEquals(opp.Type, 'Expansion');
    }
    
    @isTest static void shouldLeaveFilledOpportunityTypeOnDemoBookedLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('Demo Booked');

        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertNotEquals(opp.Type, null);
        
        Database.LeadConvertResult lcr2 = createAndConvertLead('Qualified as Expansion Opportunity', lcr);
        
        Id reusedOpportunityId = lcr2.getOpportunityId();
        Opportunity reusedOpp = [SELECT Id, Type from Opportunity WHERE Id = :reusedOpportunityId];
        
        System.assertEquals(reusedOpportunityId, opportunityId);
        System.assertEquals(reusedOpp.Type, opp.Type);
    }
    
    @isTest static void shouldLeaveFilledOpportunityTypeOnExistingAccountLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('Existing Account');

        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertNotEquals(opp.Type, null);
        
        Database.LeadConvertResult lcr2 = createAndConvertLead('Qualified as Expansion Opportunity', lcr);
        
        Id reusedOpportunityId = lcr2.getOpportunityId();
        Opportunity reusedOpp = [SELECT Id, Type from Opportunity WHERE Id = :reusedOpportunityId];
        
        System.assertEquals(reusedOpportunityId, opportunityId);
        System.assertEquals(reusedOpp.Type, opp.Type);
    }
    
    @isTest static void shouldLeavedFilledOpportunityTypeOnProvidedEnoughInfoLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('No Demo - Provided Enough Info');

        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertNotEquals(opp.Type, null);
        
        Database.LeadConvertResult lcr2 = createAndConvertLead('Qualified as Expansion Opportunity', lcr);
        
        Id reusedOpportunityId = lcr2.getOpportunityId();
        Opportunity reusedOpp = [SELECT Id, Type from Opportunity WHERE Id = :reusedOpportunityId];
        
        System.assertEquals(reusedOpportunityId, opportunityId);
        System.assertEquals(reusedOpp.Type, opp.Type);
    }
    
    @isTest static void shouldLeaveFilledOpportunityTypeOnQualifiedAsExpansionOpportunityLeadConversion() {
        Database.LeadConvertResult lcr = createAndConvertLead('Qualified as Expansion Opportunity');

        Id opportunityId = lcr.getOpportunityId();
        Opportunity opp = [SELECT Id, Type from Opportunity WHERE Id = :opportunityId];
        
        System.assertNotEquals(opp.Type, null);
        
        Database.LeadConvertResult lcr2 = createAndConvertLead('No Demo - Provided Enough Info', lcr);
        
        Id reusedOpportunityId = lcr2.getOpportunityId();
        Opportunity reusedOpp = [SELECT Id, Type from Opportunity WHERE Id = :reusedOpportunityId];
        
        System.assertEquals(reusedOpportunityId, opportunityId);
        System.assertEquals(reusedOpp.Type, opp.Type);
    }
    
    private static Database.LeadConvertResult createAndConvertLead(string convertedStatus) {
        return createAndConvertLead(convertedStatus, null);
    }
    
    private static Database.LeadConvertResult createAndConvertLead(string convertedStatus, Database.LeadConvertResult existingLcr) {
        Lead myLead = new Lead(
        	LastName = 'Yankai',
            Company = 'Gearset',
            LeadSource = 'Inbound',
            Industry = 'Utilities',
            Website = 'example.com',
            NumberOfEmployees = 50
        );
        
        insert myLead;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.Id);
        lc.setConvertedStatus(convertedStatus);
        
        if (existingLcr != null) {
            lc.setOpportunityId(existingLcr.getOpportunityId());
            lc.setAccountId(existingLcr.getAccountId());
        }
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        return lcr;
    }
}