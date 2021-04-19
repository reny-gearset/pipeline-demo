@isTest
public class TestUtils {
    public static User createStandardUser(String lastName, String email) {
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        
        return new User(
            UserName = email + '.' + generateRandomString(20),
            LastName = lastName,
            Email = email,
            Alias = lastName,
            TimeZoneSidKey = 'GMT',
            LocaleSidkey = 'en_US',
            EmailEncodingKEy = 'UTF-8',
            ProfileId = profileId.Id,
            LanguageLocaleKey = 'en_US'
        );
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
    	return randStr; 
	}
}