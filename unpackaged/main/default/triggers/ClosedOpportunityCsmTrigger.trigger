trigger ClosedOpportunityCsmTrigger on Opportunity (after update) {
    if (Trigger.new.size() > 1) {
        return; // we don't want to handle bulk updates, only updates through the UI
    }
    
    Opportunity newOp = Trigger.new[0];
    if (Trigger.old[0].StageName != 'Closed Won' && newOp.StageName == 'Closed Won') {
        CsmAssignment.handleWonOpportunity(newOp);
    }
}