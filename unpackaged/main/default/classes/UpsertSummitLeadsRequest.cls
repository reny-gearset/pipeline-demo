@SuppressWarnings('PMD.AvoidGlobalModifier') // seems this is required by Salesforce
global class UpsertSummitLeadsRequest {
    global SummitLead[] leads;
    global Id campaignId;
}
