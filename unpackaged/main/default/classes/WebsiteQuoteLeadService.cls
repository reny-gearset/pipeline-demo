public without sharing class WebsiteQuoteLeadService {
    private class WebsiteQuoteLeadException extends Exception {
    }
    private static Id sdrLeadTrackerId = [SELECT Id FROM Group WHERE Name = 'SDR Lead Distribution Queue'].get(0).Id;

    public static final Logger LOGGER = LogFactory.create(WebsiteQuoteLeadService.class);

    public void handleCreatedQuote(String prospectEmail, String quoteReference, String quoteUrl) {
        LOGGER.info('Beginning to handle a created quote for a prospect email {0}...', prospectEmail);

        Lead lead = getOrCreateLead(prospectEmail);
        createTaskForLead(lead, quoteReference, quoteUrl);

        LOGGER.info('Done handling the created quote for email {0}!', prospectEmail);
    }

    private Lead getOrCreateLead(String email) {
        List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Email = :email];
        Lead lead = null;

        if (leads.size() == 0) {
            LOGGER.info('Couldn find a Lead that matches the prospect email {0}. Going to create a Lead.', email);
            lead = createLeadAndAssignToSdrRoundRobin(email);
        } else {
            lead = leads.get(0);
        }

        return lead;
    }

    private Lead createLeadAndAssignToSdrRoundRobin(String email) {
        try {
            LOGGER.info('Creating a new lead for email {0}...', email);

            Lead newLead = new Lead(
                LastName = 'Web quote generated for ' + email,
                Email = email,
                OwnerId = sdrLeadTrackerId,
                Status = 'Ready for SDR',
                LeadSource = 'Direct',
                Company = 'n/a'
            );

            if (LeadUtilities.isGearsetTestlead(newLead)) {
                newLead.OwnerId = Defines.INTERNAL_DEV_USER_ID;
            }

            insert newLead;

            LOGGER.info('Successfully created a new lead for email {0}!', email);

            Lead insertedLead = [SELECT Id, OwnerId FROM Lead WHERE Email = :email];
            return insertedLead;
        } catch (Exception ex) {
            LOGGER.info('Failed to create a lead for email {0}. Error message: {1}', email, ex.getMessage());
            throw new WebsiteQuoteLeadException(
                'Failed to create a lead for email ' +
                email +
                '\nError message: ' +
                ex.getMessage(),
                ex
            );
        }
    }

    private void createTaskForLead(Lead lead, String quoteReference, String quoteUrl) {
        try {
            LOGGER.info('Creating a task for lead of ID {0}...', lead.Id);

            Task leadTask = new Task(
                Subject = 'Created quote on website',
                Description = 'Quote reference: ' + quoteReference + '\nQuote URL: ' + quoteUrl,
                Status = 'Open',
                Priority = 'Normal',
                WhoId = lead.Id,
                OwnerId = lead.OwnerId,
                ActivityDate = date.today()
            );

            insert leadTask;

            LOGGER.info('Successfully assigned a task for lead of ID {0}!', lead.Id);
        } catch (Exception ex) {
            LOGGER.info('Failed to create a task for lead of ID {0}. Error message: {1}', lead.Id, ex.getMessage());
            throw new WebsiteQuoteLeadException(
                'Failed to create a task for lead of ID ' +
                lead.Id +
                '\nError message: ' +
                ex.getMessage(),
                ex
            );
        }
    }
}
