@isTest
private class LeadInsertControllerTests {
	@isTest
    public static void shouldImportLeadCorrectly() {
        LeadInfo info = new LeadInfo();
        info.firstName = 'Gwilym';
        info.lastName = 'Kuiper';
        info.email = 'gwilym@gearset.com';
        info.telephone = '01223 333333';
        LeadInsertController.upsertLead(info);
        
        Lead l = [SELECT FirstName, LastName, Email, Phone FROM Lead];
        
        System.assertEquals('Gwilym', l.FirstName);
        System.assertEquals('Kuiper', l.LastName);
        System.assertEquals('gwilym@gearset.com', l.Email);
        System.assertEquals('01223 333333', l.Phone);
    }
    
    @isTest
    public static void shouldImportLeadWithInboundSourceIfNotJoiningTeam() {
        LeadInfo info = new LeadInfo();
        info.firstName = 'Gwilym';
        info.lastName = 'Kuiper';
        info.email = 'gwilym@gearset.com';
        info.telephone = '01223 333333';
        info.isAcceptingTeamInvite = false;
        LeadInsertController.upsertLead(info);
        
        Lead l = [SELECT LeadSource FROM Lead];
        
        System.assertEquals('Trialist', l.LeadSource);
    }
    
    @isTest
    public static void shouldImportLeadWithJoiningTeamSourceIfJoiningTeam() {
        LeadInfo info = new LeadInfo();
        info.firstName = 'Gwilym';
        info.lastName = 'Kuiper';
        info.email = 'gwilym@gearset.com';
        info.telephone = '01223 333333';
        info.isAcceptingTeamInvite = true;
        LeadInsertController.upsertLead(info);
        
        Lead l = [SELECT LeadSource FROM Lead];
        
        System.assertEquals('Joining team', l.LeadSource);
    }
}