//This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.
@SuppressWarnings('PMD.AvoidGlobalModifier') // seems this is required by Salesforce
global without sharing class GoogleAutoprovisionHandler implements Auth.SamlJitHandler {
    @SuppressWarnings('PMD.ExcessiveParameterList') // part of the interface
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {

        UserAttributes parsedAttributes = fromGoogleAttributes(attributes);

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales User (Admin)'];

        User u = new User(
            FirstName = parsedAttributes.firstName,
            LastName = parsedAttributes.lastName,
            Email = parsedAttributes.email,

            Username = federationIdentifier + '.production',
            FederationIdentifier = federationIdentifier,
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'GMT',
            EmailEncodingKey = 'UTF-8',
            IsActive = true,
            Alias = parsedAttributes.getAlias(),
            ProfileId = p.Id
        );

        return u;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList') // part of the interface
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
        User u = [SELECT Id, FirstName, ContactId FROM User WHERE Id=:userId];

        UserAttributes parsedAttributes = fromGoogleAttributes(attributes);

        u.FirstName = parsedAttributes.firstName;
        u.LastName = parsedAttributes.lastName;
        u.Email = parsedAttributes.email;

        update u;
    }

    private UserAttributes fromGoogleAttributes(Map<string, string> attributes) {
        String firstName = attributes.get('name.givenName');
        String lastName = attributes.get('name.familyName');
        String email = attributes.get('emails.value');

        return new UserAttributes(firstName, lastName, email);
    }

    private class UserAttributes {
        public String firstName { get; private set; }
        public String lastName { get; private set; }
        public String email { get; private set; }

        public UserAttributes(String firstName, String lastName, String email) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
        }

        public String getAlias() {
            // maximum alias length is 8 characters
            if (firstName == null) {
                return safeTruncateString(lastName, 8);
            } else {
                return safeTruncateString(firstName, 7) + safeTruncateString(lastName, 1);
            }
        }

        // .substring throws if you give it a string with fewer characters than the length you ask for
        private String safeTruncateString(String input, Integer length) {
            if (input.length() < length) {
                return input;
            }

            return input.substring(0, length);
        }
    }
}