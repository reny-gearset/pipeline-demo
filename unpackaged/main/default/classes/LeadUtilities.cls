public class LeadUtilities {
    public static String stakeholderSummary(Lead l) {
        return 
            howTheyCurrentlyUseSalesforce(l) +
            processesAndEnvironments(l) +
            teamStructure(l) +
            painsAndAims(l) +
            discoveryNotes(l);
    }
    
    private static String howTheyCurrentlyUseSalesforce(Lead l) {
        String currentSalesforceUse = l.How_they_currently_use_Salesforce__c;
        if (currentSalesforceUse == null) {
            return 'No notes about current Salesforce use\n';
        }
        
        return header('How they currently use Salesforce') + currentSalesforceUse + '\n';
    }
    
    private static String processesAndEnvironments(Lead l) {
        String processesAndEnvironmentsNotes = l.Processes_and_environments__c;
        if (processesAndEnvironmentsNotes == null) {
            return 'No notes about current processes and environments\n';
        }
        
        return header('Current processes and environments') + processesAndEnvironmentsNotes + '\n';
    }
    
    private static String teamStructure(Lead l) {
        String currentTeamStructure = l.Team_Structure__c;
        if (currentTeamStructure == null) {
            return 'No notes about current team structure\n';
        }
        
        return header('Current team structure') + currentTeamStructure + '\n';
    }
    
    private static String painsAndAims(Lead l) {
        String currentPainsAndAims = l.Pains_and_aims__c;
        if (currentPainsAndAims == null) {
            return 'No notes about current pains and aims\n';
        }
        
        return header('Current pains and aims') + currentPainsAndAims + '\n';
    }
    
    private static String discoveryNotes(Lead l) {
        String discoveryCallNotes = l.Discovery_notes__c;
        if (discoveryCallNotes == null) {
            return 'No extra discovery notes\n';
        }
        
        return header('Extra discovery notes') + discoveryCallNotes + '\n';
    }
    
    private static String header(String message) {
        return message + '\n' + '='.repeat(message.length()) + '\n\n';
    }
}