// these need to be suppressed because following these rules cause compile error
global class PrepareSandbox implements SandboxPostCopy // NOPMD
{
    global void runApexClass(SandboxContext context)
    {
        cleanUpSystemAdminUserEmails();
    }

    private void cleanUpSystemAdminUserEmails()
    {
        System.debug('Cleaning up System Administrators\' emails...');

        try {
            List<User> users = [SELECT Email FROM User WHERE profile.Name = 'System Administrator' AND Email LIKE '%.invalid'];
            
            if (users.size() == 0) {
                System.debug('No emails require a clean-up. Skipping...');
                return;
            }
            
            System.debug('Total emails to clean-up: ' + users.size());
            
            for (User user : users) {
                user.Email = user.Email.remove('.invalid');
            }
            
            update users;
        }
        catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

        System.debug('Done cleaning up System Administrators\' emails!');
    }
}