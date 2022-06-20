public with sharing class Defines {
    public static final Id INTERNAL_DEV_USER_ID = [SELECT Id FROM User WHERE UserName LIKE 'jacques.peacock@gearset.com.production%'].Id;
}
