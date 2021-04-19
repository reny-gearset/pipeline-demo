@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class AccountValidateGearsetTeam implements nebc.BeforeInsert, nebc.BeforeUpdate {
    public void handleBeforeInsert(List<Account> accounts){
        validateGearsetTeam(accounts);
    }

    public void handleBeforeUpdate(List<Account> oldAccounts, List<Account> newAccounts){
        validateGearsetTeam(newAccounts);
    }

    private void validateGearsetTeam(List<Account> accounts) {
        Set<Id> teamIds = getTeamIds(accounts);

        if(teamIds.size() == 0) {
            return;
        }

        Map<Id, Gearset_Team__c> teams = new Map<Id, Gearset_Team__c>([
            SELECT Id, Name,
            (SELECT Id, Name from Accounts__r)
            FROM Gearset_Team__c
            WHERE Id IN :teamIds
        ]);

        for(Account account: accounts) {
            Gearset_Team__c team = teams.get(account.Gearset_Team__c);
            List<Account> teamAccounts = getOtherTeamAccounts(team, account);

            if(teamAccounts.size() > 0) {
                account.Gearset_Team__c.addError(team.Name + ' team is already linked to ' + teamAccounts[0].Name + ' account.');
            }
        }
    }

    private List<Account> getOtherTeamAccounts(Gearset_Team__c team, Account account) {
        List<Account> accounts = new List<Account>();
        for (Account teamAccount: team.Accounts__r) {
            if(teamAccount.Id != account.Id) {
                accounts.add(teamAccount);
            }
        }
        return accounts;
    }

    private Set<Id> getTeamIds(List<Account> accounts) {
        Set<Id> teamIds = new Set<Id>();
        for (Account account: accounts) {
            if(account.Gearset_Team__c != null) {
                teamIds.add(account.Gearset_Team__c);
            }
        }
        return teamIds;
    }
}