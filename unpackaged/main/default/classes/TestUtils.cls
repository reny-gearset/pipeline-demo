@isTest
public class TestUtils {
    public static User createSystemAdminUser(String lastName, String email) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        return createUser(lastName, email, profile);
    }

    public static User createStandardUser(String lastName, String email) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        return createUser(lastName, email, profile);
    }

    private static User createUser(String lastName, String email, Profile profile) {
        return new User(
            UserName = email + '.' + generateRandomString(20),
            LastName = lastName,
            Email = email,
            Alias = lastName,
            TimeZoneSidKey = 'GMT',
            LocaleSidkey = 'en_US',
            EmailEncodingKEy = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }
}
