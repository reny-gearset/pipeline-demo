@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
private class TestAccountValidateGearsetTeam {
    
    private static Account createAccount() {
        return new Account
        (
            Name = TestUtils.generateRandomString(10)
        );
    }

    private static Account createAccount(Id teamId) {
        return new Account
        (
            Name = TestUtils.generateRandomString(10),
            Gearset_Team__c = teamId
        );
    }

    private static Gearset_Team__c createTeam(String teamId) {
        return new Gearset_Team__c
        (
            Gearset_Team_Id__c = teamId
        );
    }
	@isTest
    public static void onBeforeInsert_NoGearsetTeamAssigned_InsertSucceeds() {
        //arrange
        Account account = TestAccountValidateGearsetTeam.createAccount();

        //act
        Test.startTest();
        Database.SaveResult result = Database.insert(account, false);
        Test.stopTest();

        //assert
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
	@isTest
    public static void onBeforeInsert_GearsetTeamNeverUsed_AssignsTeam() {
        //arrange
        Gearset_Team__c team = TestAccountValidateGearsetTeam.createTeam('3ef02aaf-b010-428c-8350-e34beff33e8c');
        insert team;
        Account account = TestAccountValidateGearsetTeam.createAccount(team.Id);

        //act
        Test.startTest();
        Database.SaveResult result = Database.insert(account, false);
        Test.stopTest();

        //assert
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
	@isTest
    public static void onBeforeUpdate_GearsetTeamAssignedToCurrentAccount_AssignsTeam() {
        //arrange
        Gearset_Team__c team = TestAccountValidateGearsetTeam.createTeam('3ef02aaf-b010-428c-8350-e34beff33e8c');
        insert team;
        Account account = TestAccountValidateGearsetTeam.createAccount(team.Id);
        insert account;

        //act
        Test.startTest();
        Database.SaveResult result = Database.update(account, false);
        Test.stopTest();

        //assert
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
	@isTest
    public static void onBeforeInsert_GearsetTeamAssignedToAnotherAccount_AddsValidationError() {
        //arrange
        Gearset_Team__c team = TestAccountValidateGearsetTeam.createTeam('3ef02aaf-b010-428c-8350-e34beff33e8c');
        insert team;
        Account duplicateAccount = TestAccountValidateGearsetTeam.createAccount(team.Id);
        insert duplicateAccount;
        Account account = TestAccountValidateGearsetTeam.createAccount(team.Id);

        //act
        Test.startTest();
        Database.SaveResult result = Database.insert(account, false);
        Test.stopTest();

        //assert
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() == 1);
        Database.Error error = result.getErrors()[0];
        System.assert(error.getFields().size() == 1);
        String field = error.getFields()[0];
        System.assert(field == 'Gearset_Team__c');
    }
	@isTest
    public static void onBeforeUpdate_GearsetTeamAssignedToAnotherAccount_AddsValidationError() {
        //arrange
        List<Gearset_Team__c> teams = new List<Gearset_Team__c> {
            TestAccountValidateGearsetTeam.createTeam('3ef02aaf-b010-428c-8350-e34beff33e8c'),
            TestAccountValidateGearsetTeam.createTeam('5cf85ba5-4d21-4438-b95b-2ecbbd353785')
        };
        insert teams;
        List<Account> accounts = new List<Account> {
            TestAccountValidateGearsetTeam.createAccount(teams[0].Id),
            TestAccountValidateGearsetTeam.createAccount(teams[1].Id)
        };
        insert accounts;
        accounts[0].Gearset_Team__c = accounts[1].Gearset_Team__c;
        
        //act
        Test.startTest();
        Database.SaveResult result = Database.update(accounts[0], false);
        Test.stopTest();

        //assert
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() == 1);
        Database.Error error = result.getErrors()[0];
        System.assert(error.getFields().size() == 1);
        String field = error.getFields()[0];
        System.assert(field == 'Gearset_Team__c');
    }
}