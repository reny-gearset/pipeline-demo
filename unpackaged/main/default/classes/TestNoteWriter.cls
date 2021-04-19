@isTest
private class TestNoteWriter {
	@isTest
    public static void shouldCreateANoteOnALead() {
        Lead l = new Lead(LastName = 'Kuiper', Email = 'gwilym@gearset.com', Company = 'Unknown', LeadSource='Inbound');
        insert l;
        
        NoteWriter.addNote('gwilym@gearset.com', 'Some', 'Note');
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :l.Id];
        System.assertEquals(1, contentDocumentLinks.size());
    }
    
    @isTest
    public static void shouldCreateANoteOnAnOpportunity() {
        Account a = new Account(Name = 'Gearset');
        insert a;
        Contact c = new Contact(LastName = 'Kuiper', AccountId = a.Id, Email = 'gwilym@gearset.com');
        insert c;
        
        Opportunity o = new Opportunity(
            Name = 'Gearset buys stuff',
            Notify_if_logs_in__c = true,
            Loss_Reason__c = 'Competitior',
            StageName = 'Closed Lost', 
            AccountId = a.Id, 
            CloseDate = System.today(),
            LeadSource = 'Inbound',
            Type = 'New'
        );
        insert o;
        
        NoteWriter.addNote('gwilym@gearset.com', 'Some', 'Note');
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :o.Id];
        System.assertEquals(1, contentDocumentLinks.size());
    }
}