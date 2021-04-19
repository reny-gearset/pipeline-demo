public without sharing class LeadAssignmentRules {
    private static User getOrNull(String email) {
        List<User> users = [SELECT Id FROM User WHERE Email = :email];
        return users.size() > 0 ? users.get(0) : null;
    }
    
    private static Map<String, User> keyAccountReps;
    
    private static Map<String, User> getKeyAccountReps() {
        if (keyAccountReps != null) {
            return keyAccountReps;
        }
        
        User frank = getOrNull('frank@gearset.com');
        User kevin = getOrNull('kevin@gearset.com');
    
        User grant = getOrNull('grant@gearset.com');
        User lisa = getOrNull('lisa@gearset.com');
        User sandra = getOrNull('sandra@gearset.com');
        User nathan = getOrNull('nathan@gearset.com');
        
        keyAccountReps = new Map<String, User>();
        // Kevin gets all the Salesforce leads
        keyAccountReps.put('salesforce.com', kevin);
        
        // Managed accounts go to the account manager
        keyAccountReps.put('amazon.com', frank);
        keyAccountReps.put('mckesson.com', frank);
        keyAccountReps.put('comcast.com', frank);
        keyAccountReps.put('nbcuni.com', frank);
        keyAccountReps.put('email.disney.com', frank);
        keyAccountReps.put('fox.com', frank);
        keyAccountReps.put('coca-cola.com', frank);
        keyAccountReps.put('cisco.com', frank);
        
        // We want to group leads from a single consultancy to a single SDR
        keyAccountReps.put('accenture.com', grant);
        keyAccountReps.put('pwc.com', lisa);
        keyAccountReps.put('persistent.co.in', lisa);
        keyAccountReps.put('deloitte.ca', sandra);
        keyAccountReps.put('cognizant.com', sandra);
        keyAccountReps.put('silevrlinecrm.com', nathan);
        
        return keyAccountReps;
    }
    
	/**
	 * Check if a lead needs to be assigned to anyone in particular.
	 * 
	 * @return The user the lead should be assigned to or null if it should get no special treatment
	 */
    public static User getRepForLead(String email) {
        if (email == null) {
            return null;
        }

        String emailDomain = email.split('@')[1]; // salesforce requires a valid email, so this split will work
        
        return getKeyAccountReps().get(emailDomain);
    }
}