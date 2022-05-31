trigger StoreCalculatedTeamRevenue on Revenue_Calculated__e (after insert) {
    System.debug('Storing updated revenues. Received: ' + Trigger.new.size());

    Set<String> teamsToFetch = new Set<String>();
    for (Revenue_Calculated__e event : Trigger.new) {
        teamsToFetch.add(event.Team_Id__c);
    }

    List<Account> fetchedAccounts = new List<Account>(
        [SELECT Id, Gearset_team__r.Gearset_team_id__c
         FROM Account
         WHERE Gearset_team__r.Gearset_team_id__c IN :teamsToFetch]);

    System.debug('Fetched the accounts we need to update ' + fetchedAccounts.size());

    Map<String, Account> accountMap = new Map<String, Account>();
    for (Account a : fetchedAccounts) {
        accountMap.put(a.Gearset_team__r.Gearset_team_id__c, a);
    }
    
    List<Account> accountsToUpdate = new List<Account>();
    for (Revenue_Calculated__e event : Trigger.new) {
        Account toUpdate = accountMap.get(event.Team_id__c);

        if (toUpdate == null) {
            continue;
        }

        toUpdate.MRR__C = event.Revenue_MRR__c;
        accountsToUpdate.add(toUpdate);
    }

    System.debug('About to issue updates against ' + accountsToUpdate.size() + ' accounts');

    update accountsToUpdate;
}