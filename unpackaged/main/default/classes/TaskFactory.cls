public without sharing class TaskFactory {
    public static final Logger LOGGER = LogFactory.create(TaskFactory.class);

    private static final string COMPLETED_STATUS = 'Completed';
    private static final string OPEN_STATUS = 'Open';
    private static final string NORMAL_PRIORITY = 'Normal';

    public enum LeadTaskType {
        LOST_LEAD_CREATED_ACCOUNT,
        LOST_LEAD_SIGNED_IN,
        NEW_LEAD_FOR_GEARBOT,
        NEW_LEAD_FOR_SDR
    }

    public static Task createLeadTask(Lead lead, LeadTaskType taskType) {
        Task task = createTask();
        task.WhoId = lead.Id;
        task.OwnerId = lead.OwnerId;

        switch on taskType {
            when LOST_LEAD_CREATED_ACCOUNT {
                task.Subject = 'Existing lead created new account: Sales opportunity? Kill trial?';
                task.Description =
                    'Original lost reason was: ' +
                    lead.Lost_Reason__c +
                    '\nAdditional notes were: ' +
                    lead.Lost_Reason_Notes__c;
            }
            when LOST_LEAD_SIGNED_IN {
                task.Subject = 'Existing lead signed in: Lead was lost, but has since logged in';
                task.Description =
                    'Original lost reason was: ' +
                    lead.Lost_Reason__c +
                    '\nAdditional notes were: ' +
                    lead.Lost_Reason_Notes__c;
            }
            when NEW_LEAD_FOR_GEARBOT {
                task.Subject = 'New lead: Not worthy of human attention';
                task.Status = COMPLETED_STATUS;
                task.Description = 'Lead ' + lead.Email + ' needs no attention';
            }
            when NEW_LEAD_FOR_SDR {
                task.Subject = 'New lead: Can we get this lead to be an opp?';
                task.Description = 'Lead ' + lead.Email + ' needs triaging';
            }
            when else {
                // We don't recognise the type, but we still want to create a task so it can be reported.
                LOGGER.info('Lead task type {0} is not supported.', taskType);
                task.Subject = 'UNKNOWN LEAD TASK SUBJECT';
                task.Description = 'This task has been created, but we don\'t have a description for it. Please report this to internal platforms team';
            }
        }

        return task;
    }

    public enum RenewalOpportunityTaskType {
        CONTACT_ABOUT_UPCOMING_RENEWAL,
        UPDATE_RENEWAL_INFO
    }

    public static Task createRenewalOpportunityTask(Opportunity opportunity, RenewalOpportunityTaskType taskType) {
        Task task = createTask();
        task.WhatId = opportunity.Id;

        switch on taskType {
            when CONTACT_ABOUT_UPCOMING_RENEWAL {
                task.Subject = 'Contact about upcoming renewal';
                task.ActivityDate = task.ActivityDate.addDays(30);
                task.OwnerId = opportunity.OwnerId;
            }
            when UPDATE_RENEWAL_INFO {
                task.Subject = 'Update renewal information';
                task.Description = 'Add products, quantity, MRR and seats at renewal...';
                task.OwnerId = PaymentTeamAssignmentService.getNextPaymentTeamUserId();
            }
            when else {
                // We don't recognise the type, but we still want to create a task so it can be reported.
                LOGGER.info('Renewal opportunity task type {0} is not supported.', taskType);
                task.Subject = 'UNKNOWN RENEWAL OPPORTUNITY TASK SUBJECT';
                task.Description = 'This task has been created, but we don\'t have a description for it. Please report this to internal platforms team';
            }
        }

        return task;
    }

    public enum AccountTaskType {
        CONTACT_CREATED_ACCOUNT,
        LOST_OPP_CONTACT_SIGNED_IN
    }

    public static Task createAccountTask(
        Account account,
        Contact contact,
        Opportunity opportunity,
        AccountTaskType taskType
    ) {
        Task task = createTask();
        task.WhatId = account.Id;
        task.OwnerId = account.OwnerId;

        switch on taskType {
            when CONTACT_CREATED_ACCOUNT {
                task.WhoId = contact.Id;
                task.Subject = 'Existing contact created new account: Sales opportunity? Kill trial?';
                task.Description = 'User ' + contact.Name + ' created an account';
            }
            when LOST_OPP_CONTACT_SIGNED_IN {
                task.WhoId = contact.Id;
                task.Subject = 'Existing contact signed in: An opp for this account was lost, but user has since logged in';
                task.Description =
                    'User ' +
                    contact.Name +
                    ' from a previously lost opportunity ' +
                    opportunity.Name +
                    ' has created an account';
            }
            when else {
                // We don't recognise the type, but we still want to create a task so it can be reported.
                LOGGER.info('Account task type {0} is not supported.', taskType);
                task.Subject = 'UNKNOWN ACCOUNT TASK SUBJECT';
                task.Description = 'This task has been created, but we don\'t have a description for it. Please report this to internal platforms team';
            }
        }

        return task;
    }

    public enum SummitTaskType {
        ATTENDED_SUMMIT,
        DID_NOT_ATTEND_SUMMIT
    }

    public class SummitTaskInfo {
        public Id personId;
        public Id ownerId;
        public String campaignName;
        public String email;
        public String notes;
    }

    public static Task createSummitTask(SummitTaskInfo info, SummitTaskType taskType) {
        Task task = createTask();
        task.WhoId = info.personId;
        task.OwnerId = info.ownerId;

        switch on taskType {
            when ATTENDED_SUMMIT {
                task.Subject = info.campaignName + ' - Attended';
                task.Description = info.email + ' attended the' + info.campaignName + 'summit';
            }
            when DID_NOT_ATTEND_SUMMIT {
                task.Subject = info.campaignName + ' - No Show';
                task.Description =  info.email + ' signed up for the' + info.campaignName + 'summit, but did not attend';
            }
            when else {
                // We don't recognise the type, but we still want to create a task so it can be reported.
                LOGGER.info('Summit opportunity task type {0} is not supported.', taskType);
                task.Subject = 'UNKNOWN SUMMIT TASK SUBJECT';
                task.Description = 'This task has been created, but we don\'t have a description for it. Please report this to internal platforms team';
            }
        }

        if (info.notes != null) {
            task.Description += '\n' + info.notes;
        }

        return task;
    }

    public enum ContactTaskType {
        CONTACT_CREATED_ACCOUNT
    }

    public static Task createContactTask(
        Contact contact,
        ContactTaskType taskType
    ) {
        Task task = createTask();
        task.WhoId = contact.Id;
        task.OwnerId = contact.OwnerId;

        switch on taskType {
            when CONTACT_CREATED_ACCOUNT {
                task.Subject = 'Existing contact created new account: Sales opportunity? Kill trial?';
                task.Description = 'User ' + contact.Name + ' created an account';
            }
            when else {
                // We don't recognise the type, but we still want to create a task so it can be reported.
                LOGGER.info('Contact task type {0} is not supported.', taskType);
                task.Subject = 'UNKNOWN CONTACT  TASK SUBJECT';
                task.Description = 'This task has been created, but we don\'t have a description for it. Please report this to internal platforms team';
            }
        }

        return task;
    }

    private static Task createTask() {
        return new Task(Priority = NORMAL_PRIORITY, ActivityDate = date.today(), Status = OPEN_STATUS);
    }
}
