public without sharing class NoteCreationService {
    public static void createNote(Id linkedEntityId, String title, String noteContents) {
        ContentNote contentNoteObj = new ContentNote(
            Title = title,
            Content = Blob.valueOf(noteContents)
        );
        
        insert contentNoteObj;
        
        ContentDocumentLink contentDocumentLinkObj = new ContentDocumentLink(
        	LinkedEntityId = linkedEntityId,
            ContentDocumentId = contentNoteObj.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert contentDocumentLinkObj;
    }
}