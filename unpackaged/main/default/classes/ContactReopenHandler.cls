public without sharing class ContactReopenHandler {
    public static List<SignupObjectImpact> handleExistingContactLogin(Contact c, Boolean isNewUser) {
        Id contactAccountId = c.AccountId;
        List<Opportunity> opportunitiesForAccount = [
            SELECT Id, Notify_if_logs_in__c, OwnerId, StageName
            FROM Opportunity
            WHERE AccountId = :contactAccountId
        ];

        List<Task> tasks = new List<Task>();

        List<SignupObjectImpact> result = new List<SignupObjectImpact>();

        for (Opportunity o : opportunitiesForAccount) {
            Boolean oppsNeedReopened = (o.Notify_if_logs_in__c == true || isNewUser) && o.StageName == 'Closed Lost';

            if (oppsNeedReopened) {
                tasks.add(createTask(o, c, isNewUser));
                
                result.add(new SignupObjectImpact(
                    o.Id,
                    o.OwnerId,
                    SignupObjectImpactStatus.REOPENED_OBJECT
                ));
            } else {
                result.add(new SignupObjectImpact(
                    o.Id,
                    o.OwnerId,
                    SignupObjectImpactStatus.NO_IMPACT
                ));
            }
        }

        insert tasks;

        return result;
    }

    public static Task createTask(Opportunity opp, Contact contact, Boolean isNewUser) {
        return new Task(
            WhatId = opp.Id,
            WhoId = contact.Id,
            Subject = isNewUser
                ? 'A previous user has signed up for a new account. Sales opportunity? Kill trial?'
                : 'Opportunity was lost, user ' + contact.Name + ' has logged in',
            OwnerId = opp.OwnerId,
            Description = 'User ' + contact.Name + ' from previously lost opportunity has logged in',
            ActivityDate = Date.today()
        );
    }
}
