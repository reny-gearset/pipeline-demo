@isTest
private class TestLeadImporter {
	@isTest
    public static void shouldImportLeadCorrectly() {
        LeadImporter.LeadInfo info = new LeadImporter.LeadInfo();
        info.firstName = 'Gwilym';
        info.lastName = 'Kuiper';
        info.email = 'gwilym@gearset.com';
        info.telephone = '01223 333333';
        LeadImporter.upsertLead(info);
        
        Lead l = [SELECT FirstName, LastName, Email, Phone FROM Lead];
        
        System.assertEquals('Gwilym', l.FirstName);
        System.assertEquals('Kuiper', l.LastName);
        System.assertEquals('gwilym@gearset.com', l.Email);
        System.assertEquals('01223 333333', l.Phone);
    }
    
    @isTest
    public static void shouldImportLeadWithInboundSourceIfNotJoiningTeam() {
        LeadImporter.LeadInfo info = new LeadImporter.LeadInfo();
        info.firstName = 'Gwilym';
        info.lastName = 'Kuiper';
        info.email = 'gwilym@gearset.com';
        info.telephone = '01223 333333';
        info.isAcceptingTeamInvite = false;
        LeadImporter.upsertLead(info);
        
        Lead l = [SELECT LeadSource FROM Lead];
        
        System.assertEquals('Trialist', l.LeadSource);
    }
    
    @isTest
    public static void shouldImportLeadWithJoiningTeamSourceIfJoiningTeam() {
        LeadImporter.LeadInfo info = new LeadImporter.LeadInfo();
        info.firstName = 'Gwilym';
        info.lastName = 'Kuiper';
        info.email = 'gwilym@gearset.com';
        info.telephone = '01223 333333';
        info.isAcceptingTeamInvite = true;
        LeadImporter.upsertLead(info);
        
        Lead l = [SELECT LeadSource FROM Lead];
        
        System.assertEquals('Joining team', l.LeadSource);
    }
}