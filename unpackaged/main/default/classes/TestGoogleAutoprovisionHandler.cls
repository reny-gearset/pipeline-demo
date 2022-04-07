@isTest
private class TestGoogleAutoprovisionHandler {
    @isTest
    public static void createsUserWithCorrectValues() {
        Map<String, String> userAttributes = attributesForUser('Gwilym', 'Kuiper', 'gwilym@gearset.com');

        GoogleAutoprovisionHandler sut = new GoogleAutoprovisionHandler();

        User createdUser = sut.createUser(null, null, null, 'federationId@gearset.com', userAttributes, 'assertion');

        System.assertEquals('gwilym@gearset.com', createdUser.Email);
        System.assertEquals('Gwilym', createdUser.FirstName);
        System.assertEquals('Kuiper', createdUser.LastName);
        System.assertEquals('federationId@gearset.com.production', createdUser.Username);
        System.assertEquals('GwilymK', createdUser.Alias);

        Profile p = [SELECT Name FROM Profile WHERE Id = :createdUser.ProfileId];
        System.assertEquals('Sales User (Admin)', p.Name);
    }

    @isTest
    public static void updatesUserToNewValues() {
        User u = TestUtils.createStandardUser('TestFace', 'testymctestface@example.com');
        insert u;
        Id profileId = [SELECT ProfileId FROM User WHERE Id = :u.Id].ProfileId;

        Map<String, String> userAttributes = attributesForUser('Testy', 'McTestFace', 'testymctestface+2@example.com');

        GoogleAutoprovisionHandler sut = new GoogleAutoprovisionHandler();

        sut.updateUser(u.Id, null, null, null, 'testymctestface+2@example.com', userAttributes, 'assertion');

        User updatedUser = [SELECT FirstName, LastName, Email, ProfileId FROM User WHERE Id = :u.Id];

        System.assertEquals(profileId, updatedUser.ProfileId);
        System.assertEquals('Testy', updatedUser.FirstName);
        System.assertEquals('McTestFace', updatedUser.LastName);
        System.assertEquals('testymctestface+2@example.com', updatedUser.Email);
    }

    private static Map<String, String> attributesForUser(String firstName, String lastName, String email) {
        return new Map<String, String> {
            'emails.value' => email,
            'name.givenName' => firstName,
            'name.familyName' => lastName
        };
    }
}