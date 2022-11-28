@isTest
private class TestPartnerActivityController {
    @isTest
    public static void shouldCreatePartnerAccountOwnerTask() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        User bobbins = [SELECT Id FROM User WHERE Name = 'Gearbot Bobbins' ];
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            Type = 'Implementation Partner - Free',
            OwnerId = bobbins.Id,
            Show_Partner_Portal__c = true
        );
        insert acct;
        
        PartnerActivityController.PartnerActivityInfo info = new PartnerActivityController.PartnerActivityInfo();
        info.summary = 'downloaded something';
        info.teamId = 'Team 1';
        
        Boolean success = PartnerActivityController.partnerPortalActivity(info);
        
        System.assert(success);

        List<Task> tasks = 
            [SELECT Subject, Status, Priority, WhatId, OwnerId, Description
             FROM Task];
        
        System.assertEquals('Your partner has visited the partner portal. Is this a good opportunity to interact with them?', tasks[0].Subject);
        System.assertEquals('Open', tasks[0].Status);
        System.assertEquals('Normal', tasks[0].Priority);
        System.assertEquals(acct.Id, tasks[0].WhatId);
        System.assertEquals(bobbins.Id, tasks[0].OwnerId);
        System.assertEquals('Partner activity ' + info.summary + ' needs reviewing', tasks[0].Description);
    }
}