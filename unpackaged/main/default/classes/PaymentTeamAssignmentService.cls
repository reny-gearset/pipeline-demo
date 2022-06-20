public without sharing class PaymentTeamAssignmentService {
    private static final Logger LOGGER = LogFactory.create(PaymentTeamAssignmentService.class);

    private static final Id[] PAYMENT_TEAM_USER_IDS = getPaymentTeamUserIds();

    private static Id[] getPaymentTeamUserIds() {
        User[] users = [
            SELECT Id
            FROM User
            WHERE UserName LIKE 'katharine@gearset.com.production%' OR UserName LIKE 'joey.fereday@gearset.com.production%'
        ];
        Id[] ids = new List<Id>(users.size());

        for (Integer i = 0; i < users.size(); i++) {
            ids[i] = users.get(i).Id;
        }

        return ids;
    }

    public static void onOpportunityReachInvoiceStageOrBeyond(Opportunity opp) {
        LOGGER.info(
            'Opportunity of ID {0} has reached \'Invoice issued\' stage or later. Creating sales task...',
            opp.Id
        );

        if (opp.AP_Contact__c == null || opp.Invoice_Number__c == '') {
            LOGGER.info(
                'An opportunity of ID {0} does not have \'AP Contact\' or \'Invoice Number\' specified. Ignoring...',
                opp.Id
            );
            return;
        }

        if (opp.Payment_Stage__c == 'Paid') {
            LOGGER.info('An opportunity of ID {0} already has been paid for. Ignoring...', opp.Id);
            return;
        }

        if (checkIfTaskAlreadyExists(opp)) {
            LOGGER.info('Sales task for Opportunity of ID {0} already exists. Skipping...', opp.Id);
            return;
        }

        createAndAssignInvoiceTask(opp);

        LOGGER.info('Opportunity of ID {0} has reached \'Invoice issued\' stage. Creating sales task...DONE', opp.Id);
    }

    private static Boolean checkIfTaskAlreadyExists(Opportunity opp) {
        List<Task> oppTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Invoice ready to be sent'
        ];

        return oppTasks.size() > 0;
    }

    private static void createAndAssignInvoiceTask(Opportunity opp) {
        LOGGER.info('Creating a task for Opportunity of ID {0}...', opp.Id);

        String teamId = [SELECT Gearset_Team__c FROM Account WHERE Id = :opp.AccountId LIMIT 1].Gearset_Team__c;
        String gearsetTeamId = '???';
        if (teamId != null) {
            gearsetTeamId = [
                SELECT Gearset_Team_Id__c
                FROM Gearset_Team__c
                WHERE Id IN (SELECT Gearset_Team__c FROM Account WHERE Id = :opp.AccountId)
                LIMIT 1
            ]
            .Gearset_Team_Id__c;
        }

        Task task = new Task(
            Subject = 'Invoice ready to be sent',
            Description = 'Team id: ' + gearsetTeamId,
            Status = 'Open',
            Priority = 'Normal',
            WhatId = opp.Id,
            OwnerId = getNextPaymentTeamUserId(),
            ActivityDate = Date.today()
        );

        insert task;

        LOGGER.info('Creating a task for Opportunity of ID {0}...DONE', opp.Id);
    }

    public static Id getNextPaymentTeamUserId() {
        integer tasksOwned = [SELECT COUNT() FROM Task WHERE Id = :PAYMENT_TEAM_USER_IDS];
        return PAYMENT_TEAM_USER_IDS[Math.mod(tasksOwned, PAYMENT_TEAM_USER_IDS.size())];
    }
}
