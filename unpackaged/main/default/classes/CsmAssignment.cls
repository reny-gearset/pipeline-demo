public without sharing class CsmAssignment {
    private static UserRole csmRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
    
    public static Id assigneeForNewRenewalOpp(Account accountForOpp) {
        if (accountForOpp.OwnerId != gearbot.Id) {
            return accountForOpp.OwnerId;
        }
        
        List<User> csms = [SELECT Id FROM User WHERE UserRoleId = :csmRoleId.Id ORDER BY Email];
        Boolean currentAccountOwnerIsACsm = isUserInList(accountForOpp.OwnerId, csms);
        
        if (currentAccountOwnerIsACsm) {
            return accountForOpp.OwnerId;
        }
        
        Integer numCsmdOpps = [SELECT Count() FROM Opportunity WHERE Owner.UserRoleId = :csmRoleId.Id AND RecordType.DeveloperName = 'Gearset_Renewals_Process'];
        
        return csms[Math.mod(numCsmdOpps, csms.size())].Id;
    }
    
    public static void handleWonOpportunity(Opportunity wonOp) {
        if (wonOp.Type != 'New') {
            return; // do nothing unless the opportunity is new business
        }
        
        Account accountForOp = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :wonOp.AccountId];
                        
        if (wonOp.Amount >= 500) {
            List<User> csms = [SELECT Id FROM User WHERE UserRoleId = :csmRoleId.Id ORDER BY Email];
            Boolean currentAccountOwnerIsACsm = isUserInList(accountForOp.OwnerId, csms);

            if (currentAccountOwnerIsACsm) {
                String opportunitySizeName = getWonOpSizeName(wonOp.Amount);
                insert new Task(
                    Subject = String.format('{0} opportunity just closed for {1}', new List<Object> { opportunitySizeName, accountForOp.Name }),
                    Description = descriptionForOpportunity(wonOp),
                    WhatId = accountForOp.Id,
                    OwnerId = accountForOp.OwnerId,
                    ActivityDate = Date.today()
                );
                return;
            }
            
            assignAccountToCsm(accountForOp, csms, wonOp);
        } else {           
            if (accountForOp.OwnerId == gearbot.Id) {
                accountForOp.OwnerId = wonOp.OwnerId;
                update accountForOp;
            }
        }
    }
    
    private static void assignAccountToCsm(Account accountForOp, List<User> csms, Opportunity wonOp) {
        Integer numManagedAccounts = [SELECT COUNT() FROM Account WHERE Owner.UserRoleId = :csmRoleId.Id];
        User currentOpOwner = [SELECT Id, Name FROM User WHERE Id = :wonOp.OwnerId];
        
        Id newAccountOwnerId = csms.get(Math.mod(numManagedAccounts, csms.size())).Id;
        accountForOp.OwnerId = newAccountOwnerId;
        
        update accountForOp;
        
        insert new Task(
            Subject = String.format('Handover for {0} account', new List<Object> { getWonOpSizeName(wonOp.Amount).toLowerCase() }),
            WhatId = accountForOp.Id,
            OwnerId = newAccountOwnerId,
            Description = String.format('Handover from {0} about account {1}. {2}', new List<Object> { 
                currentOpOwner.Name,
                accountForOp.Name,
                descriptionForOpportunity(wonOp)
            }),
            ActivityDate = Date.today()
        );
    }
    
    private static String descriptionForOpportunity(Opportunity o) {
        return String.format('Opportunity {0} with MRR ${1} just closed. {2}', new List<Object>{
            o.Name,
            o.Amount,
            URL.getSalesforceBaseUrl().toExternalForm()+'/'+o.Id
        });
    }
    
    private static Boolean isUserInList(Id userId, List<User> users) {
        for (User user : users) {
            if (user.Id == userId) {
                return true;
            }
        }
        
        return false;
    }
    
    private static String getWonOpSizeName(Decimal amount) {
        if (amount >= 2000) {
            return 'Spicy meatball';
        } else if (amount >= 1000) {
            return 'Meatball';
        } else {
            return 'New';
        }
    }
}