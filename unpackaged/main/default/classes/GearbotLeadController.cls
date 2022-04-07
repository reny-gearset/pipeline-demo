@RestResource(urlMapping='/ReassignGearbotLeads')
global without sharing class GearbotLeadController {
    public static final Logger LOGGER = LogFactory.create(GearbotLeadController.class);

    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];
    private static Id sdrLeadTrackerId = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'].get(0).Id;

    @HttpPost
    global static void reassignGearbotLeads() {

        LOGGER.info('Starting to re-assign Gearbot leads...');

        RestRequest restRequest = RestContext.request;
        ReassignGearbotLeadsRequest request = (ReassignGearbotLeadsRequest) JSON.deserialize(restRequest.requestbody.tostring(), ReassignGearbotLeadsRequest.class);

        List<Lead> userLeads = [SELECT Id, Status FROM Lead WHERE OwnerId = :gearbot.Id AND IsConverted = false AND Email IN :request.userEmails];
        
        if (userLeads.size() == 0) {
            LOGGER.info('No leads to re-assign from Gearbot. Skipping...');
            return;
        }

        List<Id> updatedLeadIds = reassignAndUpdateLeads(userLeads);
        createAndInsertTasksForLeads(updatedLeadIds);
    }

    private static List<Id> reassignAndUpdateLeads(List<Lead> userLeads) {

        LOGGER.info('Updating {0} leads...', userLeads.size());

        List<Id> updatedLeadIds = new List<Id>();

        for (Lead userLead : userLeads) {
            setupLead(userLead);
        }

        Database.SaveResult[] dbUpdateResults = Database.update(userLeads, false);

        for (Integer i = 0; i < dbUpdateResults.size(); i++) {
            Database.SaveResult dbUpdateResult = dbUpdateResults.get(i);
            Lead userLead = userLeads.get(i);

            if (dbUpdateResult.isSuccess()) {
                LOGGER.info('Successfully updated Lead of ID {0}!', userLead.Id);
                updatedLeadIds.Add(userLead.Id);
            }
            else {
                for (Database.Error error : dbUpdateResult.getErrors()) {
                    LOGGER.info('Failed to update a Lead of ID {0}. Status code {1}. Error message: {2}', userLead.Id, error.getStatusCode(), error.getMessage());
                }
            }
        }

        LOGGER.info('Updated {0}/{1} leads!', updatedLeadIds.size(), userLeads.size());

        return updatedLeadIds;
    }

    private static void createAndInsertTasksForLeads(List<Id> leadIds) {

        LOGGER.info('Starting to create tasks for updated leads...');

        List<Task> tasksToInsert = new List<Task>();
        List<Lead> leads = [SELECT Id, Email, OwnerId FROM Lead WHERE Id IN :leadIds];

        for (Lead lead : leads) {
            try {
                LOGGER.info('Creating a task for Lead of ID {0}', lead.Id);

                Task leadTask = new Task(
                    Subject = 'Can we get this lead to be an opp?',
                    Status = 'Open',
                    Priority = 'Normal',
                    WhoId = lead.Id,
                    OwnerId = lead.OwnerId,
                    Description = 'Lead ' + lead.Email + ' needs triaging',
                    ActivityDate = date.today()
                );

                tasksToInsert.Add(leadTask);

                LOGGER.info('Successfully created a task for Lead of ID {0}', lead.Id);
            }
            catch (Exception ex) {
                LOGGER.info('Failed to create a task a Lead of ID {0}. Error message: {1}', lead.Id, ex.getMessage());
            }
        }

        Database.SaveResult[] dbInsertResults = Database.insert(tasksToInsert, false);

        List<Task> insertedTasks = new List<Task>();

        for (Integer i = 0; i < dbInsertResults.size(); i++) {
            Database.SaveResult dbInsertResult = dbInsertResults.get(i);
            Task leadTask = tasksToInsert.get(i);

            if (dbInsertResult.isSuccess()) {
                LOGGER.info('Successfully inserted Task of ID {0}!', leadTask.Id);
                insertedTasks.Add(leadTask);
            }
            else {
                for (Database.Error error : dbInsertResult.getErrors()) {
                    LOGGER.info('Failed to insert a Task for Lead of ID {0}. Status code {1}. Error message: {2}', leadTask.WhoId, error.getStatusCode(), error.getMessage());
                }
            }
        }

        LOGGER.info('Created {0}/{1} tasks for updated leads!', insertedTasks.size(), tasksToInsert.size());
    }

    private static void setupLead(Lead lead) {

        LOGGER.info('Re-assigning the owner of the Lead of ID {0}', lead.Id);

        lead.OwnerId = sdrLeadTrackerId;

        if (lead.Status == 'New') {
            LOGGER.info('Lead has \'New\' status. Setting status to \'Ready for SDR\'');
            lead.Status = 'Ready for SDR';
        }

        LOGGER.info('Done changing the Lead of ID {0}', lead.Id);
    }

    global class ReassignGearbotLeadsRequest {
        global List<String> userEmails { get; set; }
    }
}