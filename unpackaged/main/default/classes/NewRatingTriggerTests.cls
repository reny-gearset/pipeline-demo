@isTest
private class NewRatingTriggerTests {
	@isTest public static void ratingEventTriggerShouldPopulateDatabase() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = '13219ec0-3a81-44c5-a300-de14b7d0235f');
        Rating_Submitted__e event = new Rating_Submitted__e(Rating_Id__c = 'Rating 1', Team_Id__c = team.Gearset_Team_Id__c, Email__c = 'test1@test.com', Comment__c = 'Comment 1', Score__c = 8, Date__c = '2021-01-18T18:11:09.256Z');
        
        Test.startTest();
        
        insert team;
        Database.SaveResult sr = EventBus.publish(event);
            
        Test.stopTest();
                
        System.assertEquals(true, sr.isSuccess());
        
        List<Rating__c> ratings = [SELECT Id FROM Rating__c];

        System.assertEquals(1, ratings.size()); 
    }
}