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
        User maritina = getOrNull('maritina.tsembelis@gearset.com');
        User jacques = getOrNull('jacques.peacock@gearset.com');
        
        keyAccountReps = new Map<String, User>();
        
        // Maritina gets all the Salesforce leads
        keyAccountReps.put('salesforce.com', maritina);
        
        // Managed accounts go to the account manager
        keyAccountReps.put('amazon.com', frank);
        keyAccountReps.put('mckesson.com', frank);
        keyAccountReps.put('comcast.com', frank);
        keyAccountReps.put('nbcuni.com', frank);
        keyAccountReps.put('email.disney.com', frank);
        keyAccountReps.put('fox.com', frank);
        keyAccountReps.put('coca-cola.com', frank);
        keyAccountReps.put('cisco.com', frank);

        // Test accounts get assigned to the Internal Platforms dev
        keyAccountReps.put('gearset.com', jacques);
        
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