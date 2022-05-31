public without sharing class ContactReopenHandler {
    private static final string OPPORTUNITY_CLOSED_LOST_STATUS = 'Closed Lost';

    public static List<SignupObjectImpact> handleExistingContactLogin(Contact contact, Boolean isNewUser) {
        List<Task> tasks = new List<Task>();
        List<SignupObjectImpact> result = new List<SignupObjectImpact>();

        Account account = getAccountOrNull(contact.AccountId);

        if (isNewUser) {
            if (account != null) {
                tasks.add(
                    TaskFactory.createAccountTask(
                        account,
                        contact,
                        null,
                        TaskFactory.AccountTaskType.CONTACT_CREATED_ACCOUNT
                    )
                );

                result.add(
                    new SignupObjectImpact(account.Id, account.OwnerId, SignupObjectImpactStatus.REOPENED_OBJECT)
                );
            } else {
                tasks.add(TaskFactory.createContactTask(contact, TaskFactory.ContactTaskType.CONTACT_CREATED_ACCOUNT));

                result.add(
                    new SignupObjectImpact(contact.Id, contact.OwnerId, SignupObjectImpactStatus.REOPENED_OBJECT)
                );
            }
        } else if (account != null) {
            Opportunity opportunityEligibleForReopen = getOpportunityEligibleForReopenOrNull(account.Id);

            if (opportunityEligibleForReopen != null) {
                tasks.add(
                    TaskFactory.createAccountTask(
                        account,
                        contact,
                        opportunityEligibleForReopen,
                        TaskFactory.AccountTaskType.LOST_OPP_CONTACT_SIGNED_IN
                    )
                );

                result.add(
                    new SignupObjectImpact(account.Id, account.OwnerId, SignupObjectImpactStatus.REOPENED_OBJECT)
                );
            }
        }

        if (tasks.size() > 0) {
            insert tasks;
        }

        return result;
    }

    private static Opportunity getOpportunityEligibleForReopenOrNull(Id accountId) {
        List<Opportunity> opportunitiesEligibleForReopen = [
            SELECT Id, Name
            FROM Opportunity
            WHERE
                AccountId = :accountId
                AND Notify_if_logs_in__c = TRUE
                AND StageName = :OPPORTUNITY_CLOSED_LOST_STATUS
            ORDER BY CloseDate DESC NULLS LAST
            LIMIT 1
        ];

        if (opportunitiesEligibleForReopen.size() == 1) {
            return opportunitiesEligibleForReopen[0];
        }

        return null;
    }

    private static Account getAccountOrNull(Id accountId) {
        Account[] accounts = [SELECT Id, OwnerId FROM Account WHERE Id = :accountId LIMIT 1];
        if (accounts.size() > 0) {
            return accounts[0];
        }

        return null;
    }
}
