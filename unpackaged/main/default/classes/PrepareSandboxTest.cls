@isTest
public class PrepareSandboxTest {

    @isTest
    private static void prepareSandboxShouldCleanUpUserEmails() {

        User u = TestUtils.createSystemAdminUser('SysAdmin', 'system.admin.test.user@gearset.com.invalid');
        insert u;

        Test.startTest();

        Test.testSandboxPostCopyScript(
            new PrepareSandbox(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationName()
        );

        Test.stopTest();

        User updatedUser = [SELECT Email FROM User WHERE Email = 'system.admin.test.user@gearset.com'];
        System.assertEquals('system.admin.test.user@gearset.com', updatedUser.Email);
    }
}