@isTest
private class SalesRegionFormulaFieldTests {
    private static Account createAccountWithCountry(string country) {
        return new Account
        (
            Name = TestUtils.generateRandomString(10),
            Sign_In_Country__c = country
        );
    }
    
    private static Lead createLeadWithCountry(string country) {
        return new Lead
        (
            LastName = TestUtils.generateRandomString(10),
            Company = 'Gearset',
            Sign_In_Country__c = country
        );
    }
    
    @isTest 
    public static void shouldCorrectlyCalculateAmerRegion(){
        final string country = 'United States';
        Lead lead = createLeadWithCountry(country);
        insert lead;
        Account account = createAccountWithCountry(country);
        insert account;
        
        List<Lead> leads = [SELECT Id, Sales_Region__c FROM Lead];
        List<Account> accounts = [SELECT Id, Sales_Region__c FROM Account];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('AMER', leads.get(0).Sales_Region__c, 'The lead region field returned an unexpected value');
        System.assertEquals(1, accounts.size());
        System.assertEquals('AMER', accounts.get(0).Sales_Region__c, 'The account region field returned an unexpected value');
    }
    
    @isTest 
    public static void shouldCorrectlyCalculateEmeaRegion(){
        final string country = 'United Kingdom';
        Lead lead = createLeadWithCountry(country);
        insert lead;
        Account account = createAccountWithCountry(country);
        insert account;
        
        List<Lead> leads = [SELECT Id, Sales_Region__c FROM Lead];
        List<Account> accounts = [SELECT Id, Sales_Region__c FROM Account];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('EMEA', leads.get(0).Sales_Region__c, 'The lead region field returned an unexpected value');
        System.assertEquals(1, accounts.size());
        System.assertEquals('EMEA', accounts.get(0).Sales_Region__c, 'The account region field returned an unexpected value');
    }
    
    @isTest 
    public static void shouldCorrectlyCalculateApacRegion(){
        final string country = 'Australia';
        Lead lead = createLeadWithCountry(country);
        insert lead;
        Account account = createAccountWithCountry(country);
        insert account;
        
        List<Lead> leads = [SELECT Id, Sales_Region__c FROM Lead];
        List<Account> accounts = [SELECT Id, Sales_Region__c FROM Account];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('APAC', leads.get(0).Sales_Region__c, 'The lead region field returned an unexpected value');
        System.assertEquals(1, accounts.size());
        System.assertEquals('APAC', accounts.get(0).Sales_Region__c, 'The account region field returned an unexpected value');
    }
    
    @isTest 
    public static void shouldCorrectlyCalculateOtherRegion(){
        final string country = 'Brazil';
        Lead lead = createLeadWithCountry(country);
        insert lead;
        Account account = createAccountWithCountry(country);
        insert account;
        
        List<Lead> leads = [SELECT Id, Sales_Region__c FROM Lead];
        List<Account> accounts = [SELECT Id, Sales_Region__c FROM Account];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('Other', leads.get(0).Sales_Region__c, 'The lead region field returned an unexpected value');
        System.assertEquals(1, accounts.size());
        System.assertEquals('Other', accounts.get(0).Sales_Region__c, 'The account region field returned an unexpected value');
    }
    
    @isTest 
    public static void shouldReturnUnknownForUnknownCountry(){
        final string country = 'UnknownCountry';
        Lead lead = createLeadWithCountry(country);
        insert lead;
        Account account = createAccountWithCountry(country);
        insert account;
        
        List<Lead> leads = [SELECT Id, Sales_Region__c FROM Lead];
        List<Account> accounts = [SELECT Id, Sales_Region__c FROM Account];
        
        System.assertEquals(1, leads.size());
        System.assertEquals('Unknown', leads.get(0).Sales_Region__c, 'The lead region field returned an unexpected value');
        System.assertEquals(1, accounts.size());
        System.assertEquals('Unknown', accounts.get(0).Sales_Region__c, 'The account region field returned an unexpected value');
    }

    @isTest 
    public static void shouldReturnNullForBlankOrNull(){
        final string country = '';
        Lead lead = createLeadWithCountry(country);
        insert lead;
        Account account = createAccountWithCountry(country);
        insert account;
        
        List<Lead> leads = [SELECT Id, Sales_Region__c FROM Lead];
        List<Account> accounts = [SELECT Id, Sales_Region__c FROM Account];
        
        System.assertEquals(1, leads.size());
        System.assertEquals(null, leads.get(0).Sales_Region__c, 'The lead region field returned an unexpected value');
        System.assertEquals(1, accounts.size());
        System.assertEquals(null, accounts.get(0).Sales_Region__c, 'The account region field returned an unexpected value');
    }
}