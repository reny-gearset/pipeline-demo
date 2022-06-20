@isTest
public class CaseTest {
    private static User gearbot = [SELECT Id FROM User WHERE Username LIKE 'gearbot@gearset.com%'];

    @isTest
    static void shouldAssignCurrentUserAsStakeholderIfNewCaseHasNoStakeholder() {
        Case newCase = getTestCase();

        insert newCase;

        Case insertedCase = [SELECT Stakeholder__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(UserInfo.getUserId(), insertedCase.Stakeholder__c);
    }

    @isTest
    static void shouldNotAssignCurrentUserAsStakeholderIfNewCaseHasStakeholder() {
        Case newCase = getTestCase();
        newCase.Stakeholder__c = gearbot.Id;

        insert newCase;

        Case insertedCase = [SELECT Stakeholder__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(gearbot.Id, insertedCase.Stakeholder__c);
    }

    private static Case getTestCase() {
        Case newCase = new Case();
        newCase.Gearset_Team__c = 'Sales';
        newCase.Type = 'Problem';
        newCase.What_is_the_problem__c = 'n/a';
        newCase.Current_Workaround__c = 'n/a';
        newCase.Subject = 'n/a';
        newCase.Description = 'n/a';

        return newCase;
    }
}
