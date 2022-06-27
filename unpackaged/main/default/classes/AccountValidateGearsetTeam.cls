@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class AccountValidateGearsetTeam {
    public static void validateGearsetTeam(List<Account> accounts) {    
        //only run for single triggers, not bulk loading    
        if(accounts.size() != 1) {
            return;
        }
        
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

    private static List<Account> getOtherTeamAccounts(Gearset_Team__c team, Account account) {
        List<Account> accounts = new List<Account>();
        for (Account teamAccount: team.Accounts__r) {
            if(teamAccount.Id != account.Id) {
                accounts.add(teamAccount);
            }
        }
        return accounts;
    }

    private static Set<Id> getTeamIds(List<Account> accounts) {
        Set<Id> teamIds = new Set<Id>();
        for (Account account: accounts) {
            if(account.Gearset_Team__c != null) {
                teamIds.add(account.Gearset_Team__c);
            }
        }
        return teamIds;
    }
}