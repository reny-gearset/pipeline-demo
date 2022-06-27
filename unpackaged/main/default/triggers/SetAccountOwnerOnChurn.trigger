trigger SetAccountOwnerOnChurn on SubscriptionChurnEvent__c (before insert) {
    public static final Logger LOGGER = LogFactory.create(RatingSubmittedEventConverter.class);
    
    Set<ID> accountIds = new Set<ID>();
    for(SubscriptionChurnEvent__c churn : trigger.new) {
        accountIds.add(churn.Account__c);
    }
    LOGGER.info('Setting account owner for % new churn event(s)', accountIds.size());
    
    Map<ID, Account> churnMap = new Map<ID, Account>([Select OwnerId from Account where ID IN :accountIds]);
    for(SubscriptionChurnEvent__c churn : trigger.new){
       churn.Account_Owner__c = churnMap.get(churn.Account__c).OwnerID;
    }
}