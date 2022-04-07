@isTest
public class AccountContractService_Test {
    @isTest
    public static void activatedContractShouldUpdateReferencedAccount() {
        Account newAccount = createTestAccount('TestAcc', 'c18aa7fc-0aea-4fba-aace-f003f722c7c7');
        insert newAccount;

        Contract newContract = new Contract();
        newContract.AccountId = newAccount.Id;
        newContract.StartDate = Date.today().addDays(-1);
        newContract.ContractTerm = 1;
        newContract.Contract_Type__c = 'Standard Reseller Agreement';
        newContract.Status = 'Draft';
        insert newContract;

        Contract contract = [SELECT Status, EndDate FROM Contract WHERE Id = :newContract.Id];
        contract.Status = 'Activated';
        update contract;

        Account account = [
            SELECT Activated_Partner_Agreement_End_Date__c, Activated_Partner_Agreement__c
            FROM Account
            WHERE Id = :newAccount.Id
        ];

        System.assertEquals(contract.EndDate, account.Activated_Partner_Agreement_End_Date__c);
        System.assertEquals(true, account.Activated_Partner_Agreement__c);
    }

    @isTest
    public static void draftContractShouldNotUpdateReferencedAccount() {
        Account newAccount = createTestAccount('TestAcc', 'c18aa7fc-0aea-4fba-aace-f003f722c7c7');
        insert newAccount;

        Contract newContract = new Contract();
        newContract.AccountId = newAccount.Id;
        newContract.StartDate = Date.today().addMonths(-5);
        newContract.ContractTerm = 1;
        newContract.Contract_Type__c = 'Standard Reseller Agreement';
        newContract.Status = 'Draft';
        insert newContract;

        Contract contract = [SELECT Status, EndDate FROM Contract WHERE Id = :newContract.Id];
        contract.Status = 'Activated';
        update contract;

        Account account = [
            SELECT Activated_Partner_Agreement_End_Date__c, Activated_Partner_Agreement__c
            FROM Account
            WHERE Id = :newAccount.Id
        ];

        System.assertEquals(contract.EndDate, account.Activated_Partner_Agreement_End_Date__c);
        System.assertEquals(false, account.Activated_Partner_Agreement__c);
    }

    @isTest
    public static void activatedPartnerAgreementShouldBeFalseIfContractHasExpired() {
        Account newAccount = createTestAccount('TestAcc', 'c18aa7fc-0aea-4fba-aace-f003f722c7c7');
        insert newAccount;

        Contract newContract = new Contract();
        newContract.AccountId = newAccount.Id;
        newContract.StartDate = Date.today().addDays(-1);
        newContract.ContractTerm = 1;
        newContract.Contract_Type__c = 'Standard Reseller Agreement';
        newContract.Status = 'Draft';
        insert newContract;

        Contract contract = [SELECT Status, EndDate FROM Contract WHERE Id = :newContract.Id];
        contract.ContractTerm = 2;
        update contract;

        Account account = [
            SELECT Activated_Partner_Agreement_End_Date__c, Activated_Partner_Agreement__c
            FROM Account
            WHERE Id = :newAccount.Id
        ];

        System.assertEquals(null, account.Activated_Partner_Agreement_End_Date__c);
        System.assertEquals(false, account.Activated_Partner_Agreement__c);
    }

    private static Account createTestAccount(String accountName, String teamId) {
        Gearset_Team__c gt = new Gearset_Team__c(Gearset_Team_Id__c = teamId);
        upsert gt;

        Account account = new Account();
        account.Name = accountName;
        account.Gearset_team__c = gt.Id;
        return account;
    }
}
