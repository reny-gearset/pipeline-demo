public without sharing class RatingSubmittedEventConverter {
    public static final Logger LOGGER = LogFactory.create(RatingSubmittedEventConverter.class);

    public List<Rating__c> getItemsFromEvents(List<Rating_Submitted__e> events) {
        Set<String> emailsToFetch = new Set<String>();
        Set<String> teamsToFetch = new Set<String>();
        for (Rating_Submitted__e event : events) {
            emailsToFetch.add(event.Email__c);
            teamsToFetch.add(event.Team_Id__c);
        }

        List<Contact> fetchedContacts = [SELECT Id, Email FROM Contact WHERE Email IN :emailsToFetch];
        LOGGER.info('Found contacts for ratings submitted: {0}', fetchedContacts.size());

        List<Gearset_Team__c> fetchedTeams = [
            SELECT Id, Gearset_Team_Id__c
            FROM Gearset_Team__c
            WHERE Gearset_Team_Id__c IN :teamsToFetch
        ];
        LOGGER.info('Found teams for ratings submitted: {0}', fetchedTeams.size());

        List<Account> fetchedAccounts = [
            SELECT Id, Gearset_team__r.Gearset_team_id__c, OwnerId
            FROM Account
            WHERE Gearset_team__r.Gearset_team_id__c IN :teamsToFetch
        ];
        LOGGER.info('Found accounts for ratings submitted: {0}', fetchedAccounts.size());

        Map<string, Contact> contactMap = new Map<string, Contact>();
        for (Contact a : fetchedContacts) {
            contactMap.put(a.Email, a);
        }

        Map<string, Gearset_Team__c> teamMap = new Map<string, Gearset_Team__c>();
        for (Gearset_Team__c team : fetchedTeams) {
            teamMap.put(team.Gearset_Team_Id__c, team);
        }

        Map<string, Account> accountMap = new Map<string, Account>();
        for (Account account : fetchedAccounts) {
            accountMap.put(account.Gearset_team__r.Gearset_team_id__c, account);
        }

        List<Rating__c> ratings = new List<Rating__c>();
        List<Contact> newContacts = new List<Contact>();
        Map<string, Rating__c> newContactsRatingMap = new Map<string, Rating__c>();
        for (Rating_Submitted__e event : events) {
            Rating__c item = new Rating__c();
            item.Rating_Id__c = event.Rating_Id__c;
            item.Gearset_Team__c = teamMap.get(event.Team_Id__c)?.Id;
            
            Account account = accountMap.get(event.Team_Id__c);
            Contact contact = contactMap.get(event.Email__c);
            item.Contact__c = contact?.Id;
            
            if (account != null) {
                LOGGER.info('Account exists');
                item.Account__c = account.Id;
                item.OwnerId = account.OwnerId;
                
                if (contact == null) {
                    Contact newContact = generateContactFromEvent(event, account);
                    newContacts.add(newContact);
                    newContactsRatingMap.put(newContact.Email, item);
                }
            }
            
            item.Comment__c = event.Comment__c;
            item.Question__c = event.Question__c;
            item.Score__c = event.Score__c;
            item.Date__c = (DateTime) JSON.deserialize('"' + event.Date__c + '"', DateTime.class);
            ratings.add(item);
        }
        
        insert newContacts;
        
        for (Contact contact : newContacts) {
            Rating__c rating = newContactsRatingMap.get(contact.Email);
            rating.Contact__c = contact.Id;
        }

        return ratings;
    }
    
    private Contact generateContactFromEvent(Rating_Submitted__e event, Account account) {
        LOGGER.info('Creating new contact for account');
        Contact item = new Contact();
        item.FirstName = event.FirstName__c;
        item.LastName = event.LastName__c;
        item.Email = event.Email__c;
        item.AccountId = account.Id;
        item.OwnerId = account.OwnerId;
        return item;
    }
}