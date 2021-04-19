@RestResource(urlMapping='/Contact/OrgConnection')
global without sharing class ContactInformationController {
    @HttpPost
    global static void addOrgConnection(OrgConnectionRequest info) {
        List<Contact> contacts = [SELECT Id, Phone FROM Contact WHERE Email = :info.email];
        if (contacts.size() > 0) {
            addOrgConnectionToContact(contacts.get(0), info);
            return;
        }

        List<Lead> leads = [SELECT Id, Phone FROM Lead WHERE Email = :info.email];
        if (leads.size() > 0) {
            addOrgConnectionToLead(leads.get(0), info);
            return;
        }
    }

    private static void addOrgConnectionToContact(Contact c, OrgConnectionRequest info) {
        if (info.source == 'UserSubmitted' && String.isBlank(c.Phone)) {
            c.Phone = info.phoneNumber;
            update c;
        } else {
            // check if it already exists
            List<Org_Connection__c> orgConnections = [
                SELECT Id
                FROM Org_Connection__c
                WHERE Contact__c = :c.Id AND Org_Username__c = :info.orgName AND Phone__c = :info.phoneNumber
            ];
            if (orgConnections.size() > 0) {
                return;
            }

            insert new Org_Connection__c(
                Contact__c = c.Id,
                Org_Username__c = info.orgName,
                Phone__c = info.phoneNumber
            );
        }
    }

    private static void addOrgConnectionToLead(Lead l, OrgConnectionRequest info) {
        if (info.source == 'UserSubmitted' && String.isBlank(l.phone)) {
            l.Phone = info.phoneNumber;
            update l;
        } else {
            // check if it already exists
            List<Org_Connection__c> orgConnections = [
                SELECT Id
                FROM Org_Connection__c
                WHERE Lead__c = :l.Id AND Org_Username__c = :info.orgName AND Phone__c = :info.phoneNumber
            ];
            if (orgConnections.size() > 0) {
                return;
            }

            insert new Org_Connection__c(Lead__c = l.Id, Org_Username__c = info.orgName, Phone__c = info.phoneNumber);
        }
    }

    global class OrgConnectionRequest {
        global string email { get; set; }
        global string orgName { get; set; }
        global string phoneNumber { get; set; }
        global string source { get; set; }
    }
}
