public without sharing class CsmAssignment {
    
    private class CsmAssignmentException extends Exception {}
    
    private static UserRole mmCsmRole = [SELECT Id, Name FROM UserRole WHERE DeveloperName = 'Customer_Success_Manager'];
    private static UserRole smbCsmRole = [SELECT Id, Name FROM UserRole WHERE DeveloperName = 'Small_and_Medium_Customer_Success_Manager'];
    private static UserRole leadCsmRole = [SELECT Id, Name FROM UserRole WHERE DeveloperName = 'Lead_Customer_Success_Manager'];
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
    
    public static Id assigneeForNewRenewalOpp(Account accountForOpp) 
    {
        if (accountForOpp.OwnerId != gearbot.Id) 
        {
            return accountForOpp.OwnerId;
        }
        
        List<User> csms = [SELECT Id FROM User WHERE IsActive = True AND (UserRoleId = :mmCsmRole.Id OR UserRoleId = :smbCsmRole.Id OR UserRoleId = :leadCsmRole.Id) ORDER BY Email];
        Boolean currentAccountOwnerIsACsm = isUserInList(accountForOpp.OwnerId, csms);
        
        if (currentAccountOwnerIsACsm) 
        {
            return accountForOpp.OwnerId;
        }
        
        Integer numCsmdOpps = [SELECT Count() FROM Opportunity WHERE RecordType.DeveloperName = 'Gearset_Renewals_Process' AND (Owner.UserRoleId = :mmCsmRole.Id OR Owner.UserRoleId = :smbCsmRole.Id OR Owner.UserRoleId = :leadCsmRole.Id)];
        
        return csms[Math.mod(numCsmdOpps, csms.size())].Id;
    }

    public static void handleWonOpportunity(Opportunity wonOp) {

        // do nothing unless the opportunity is new business
        if (wonOp.Type != 'New') 
        {
            return;
        }

        Account accountForOp = [SELECT Id, Name, Customer_segment__c, OwnerId FROM Account WHERE Id = :wonOp.AccountId];
        String customerSegment = accountForOp.Customer_segment__c;
        
        UserRole targetCsmRole = getCsmRoleForOpportunity(wonOp, customerSegment);
        List<User> targetCsmUsers = [SELECT Id FROM User WHERE IsActive = True AND UserRoleId = :targetCsmRole.Id ORDER BY Email];

        if (targetCsmUsers.isEmpty())
        {
            throw new CsmAssignmentException('Unable to assign an Account! There are no users in a CSM role (' + targetCsmRole.Name + ').');
        }

        // check if current account owner has any CSM role
        List<User> allCsmUsers = [SELECT Id FROM User WHERE IsActive = True AND (UserRoleId = :mmCsmRole.Id OR UserRoleId = :smbCsmRole.Id OR UserRoleId = :leadCsmRole.Id) ORDER BY Email];
        Boolean currentAccountOwnerIsInTargetRole = isUserInList(accountForOp.OwnerId, allCsmUsers);

        if (currentAccountOwnerIsInTargetRole) {
            createOpportunityClosedTask(accountForOp, wonOp);
            return;
        }
        else {
            // assign account to the target CSM user pool
            User currentOpOwner = [SELECT Id, Name FROM User WHERE Id = :wonOp.OwnerId];
            Id newAccountOwnerId = assignAccountToCsmUser(accountForOp, currentOpOwner, targetCsmUsers, targetCsmRole.Id);
            createOpportunityHandoverTask(currentOpOwner, newAccountOwnerId, wonOp, accountForOp);
        }
    }
    
    private static UserRole getCsmRoleForOpportunity(Opportunity wonOp, String customerSegment)
    {
        if (customerSegment != 'Implementation Partner' && customerSegment != 'Enterprise')
        {
            if (wonOp.Amount >= 1000) 
            {
                // assign to Mid-market CSM user pool
                return mmCsmRole;
            }
            else if (wonOp.Amount < 1000)
            {
                // assign to Small and Medium Business CSM user pool
                return smbCsmRole;
            }
        }

        // assign to Lead CSM user pool
        return leadCsmRole;
    }

    private static void createOpportunityClosedTask(Account accountForOp, Opportunity wonOp) 
    {
        String opportunitySizeName = getWonOpSizeName(wonOp.Amount);
        insert new Task(
            Subject = String.format('{0} opportunity just closed for {1}', new List<Object> { opportunitySizeName, accountForOp.Name }),
            Description = descriptionForOpportunity(wonOp),
            WhatId = accountForOp.Id,
            OwnerId = accountForOp.OwnerId,
            ActivityDate = Date.today()
        );
    }

    private static Id assignAccountToCsmUser(Account accountForOp, User currentOpOwner, List<User> csms, Id csmRoleId)
    {      
        Integer numManagedAccounts = [SELECT COUNT() FROM Account WHERE Owner.UserRoleId = :csmRoleId];
        Id newAccountOwnerId = csms.get(Math.mod(numManagedAccounts, csms.size())).Id;
        accountForOp.OwnerId = newAccountOwnerId;
        
        update accountForOp;

        return newAccountOwnerId;
    }
    
    private static void createOpportunityHandoverTask(User currentOpOwner, Id newAccountOwnerId, Opportunity wonOp, Account accountForOp)
    {
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

    private static String descriptionForOpportunity(Opportunity o) 
    {
        return String.format('Opportunity {0} with MRR ${1} just closed. {2}', new List<Object> {
            o.Name,
            o.Amount,
            URL.getSalesforceBaseUrl().toExternalForm()+'/'+o.Id
        });
    }
    
    private static Boolean isUserInList(Id userId, List<User> users) 
    {
        for (User user : users) 
        {
            if (user.Id == userId) 
            {
                return true;
            }
        }
        
        return false;
    }
    
    private static String getWonOpSizeName(Decimal amount) 
    {
        if (amount >= 2000) 
        {
            return 'Spicy meatball';
        }
        else if (amount >= 1000) 
        {
            return 'Meatball';
        } 
        else 
        {
            return 'New';
        }
    }
}