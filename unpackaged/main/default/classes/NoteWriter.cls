@RestResource(urlMapping='/Notes/*')
global without sharing class NoteWriter {
	@HttpPost
    global static void addNote(String email, String title, String content) {
        // First try to find a contact with the email, then a lead. Since contacts would be created
        // by converting leads.
        List<Contact> contactsWithEmail = [SELECT AccountId FROM Contact WHERE Email = :email LIMIT 1];
        if (contactsWithEmail.size() == 1) {
            attachNoteToContact(contactsWithEmail.get(0), title, content);
            return;
        }
        
        List<Lead> leadsWithEmail = [SELECT Id FROM Lead WHERE Email = :email LIMIT 1];
        if (leadsWithEmail.size() == 1) {
            attachNoteToLead(leadsWithEmail.get(0), title, content);
            return;
        }
    }
    
    private static void attachNoteToContact(Contact c, String title, String content) {
        // We ideally want the note on the opportunity related to the contact. There can be multiple of these
        // however, so we'll add it to all of them for now until it gets annoying
        List<Opportunity> opportunitiesWithContact = [SELECT Id FROM Opportunity WHERE AccountId = :c.AccountId];
        for (Opportunity o : opportunitiesWithContact) {
            NoteCreationService.createNote(o.Id, title, content);
        }
    }
    
    private static void attachNoteToLead(Lead l, String title, String content) {
        NoteCreationService.createNote(l.Id, title, content);
    }
}