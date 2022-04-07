trigger SetCloseDateToTodayWhenMarkingOpportunityAsWon on Opportunity (before update) {
    for (Opportunity o : Trigger.new) {
        Opportunity oldOp = Trigger.oldMap.get(o.Id);
        if (
            (oldOp.StageName != 'Closed Won' && o.StageName == 'Closed Won') ||
            (oldOp.StageName != 'Closed Lost' && o.StageName == 'Closed Lost')
        ) {
            o.CloseDate = Date.today();
        }
    }
}