trigger NewCaseTrigger on Case(before insert) {
    for (Case c : Trigger.New) {
        if (c.Stakeholder__c == null) {
            c.Stakeholder__c = UserInfo.getUserId();
        }
    }
}
