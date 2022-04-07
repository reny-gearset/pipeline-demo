// See SalesforceMarketingLead.cs in gearset-website-api for caller definition
@SuppressWarnings('PMD.AvoidGlobalModifier') // seems this is required by Salesforce
global class SalesforceMarketingLead {
    global String firstName;
    global String surname;
    global String email;
    global String company;
    global String phoneNumber;
    global String industry;
    global Boolean marketingConsent;
    global String source;
    global Integer companySize;
    global String discoveryNotes;
}