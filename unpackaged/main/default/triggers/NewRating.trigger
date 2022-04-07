trigger NewRating on Rating_Submitted__e (after insert) {
    RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
    
    List<Rating__c> ratingsToUpsert = converter.getItemsFromEvents(Trigger.new);
    upsert ratingsToUpsert Rating_Id__c;
}