@isTest
private class RatingSubmittedEventConverterTests {
    @isTest
    public static void getItemsFromEventsWithNoEventsShouldReturnEmptyList() {
        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(0, objects.size());
    }

    @isTest
    public static void getItemsFromEventsWithEventsShouldReturnListOfObjects() {
        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 1',
                Team_Id__c = 'Team 1',
                Email__c = 'test1@test.com',
                Comment__c = 'Comment 1',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z'
            )
        );
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 2',
                Team_Id__c = 'Team 2',
                Email__c = 'test2@test.com',
                Comment__c = 'Comment 2',
                Score__c = 2,
                Date__c = '2021-01-18T18:11:09.256Z'
            )
        );
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 3',
                Team_Id__c = 'Team 1',
                Email__c = 'test3@test.com',
                Comment__c = 'Comment 3',
                Score__c = 10,
                Date__c = '2021-01-18T18:11:09.256Z'
            )
        );

        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(3, objects.size());
        System.AssertEquals('Rating 1', objects.get(0).Rating_Id__c);
        System.AssertEquals('Rating 2', objects.get(1).Rating_Id__c);
        System.AssertEquals('Rating 3', objects.get(2).Rating_Id__c);
    }

    @isTest
    public static void getItemsFromEventsWithValidTeamShouldLinkToTeam() {
        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 1',
                Team_Id__c = team.Gearset_Team_Id__c,
                Email__c = 'test1@test.com',
                Comment__c = 'Comment 1',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z'
            )
        );

        insert team;
        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(1, objects.size());
        System.AssertEquals(team.Id, objects.get(0).Gearset_Team__c);
    }

    @isTest
    public static void getItemsFromEventsWithValidContactAndAccountShouldLinkToContact() {
        User user = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert user;

        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            OwnerId = user.Id
        );
        insert acct;
        
        Contact contact = new Contact(Email = 'test@test.com', AccountId = acct.Id, LastName = 'Last', FirstName = 'First' );
        insert contact;
        
        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 1',
                Team_Id__c = 'Team 1',
                Email__c = contact.Email,
                Comment__c = 'Comment 1',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z'
            )
        );

        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(1, objects.size());
        System.AssertEquals(contact.Id, objects.get(0).Contact__c);
        System.AssertEquals(acct.Id, objects.get(0).Account__c);
    }
    
    @isTest
    public static void getItemsFromEventsWithValidAccountAndNoContactShouldCreateNewContact() {
        User user = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert user;

        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            OwnerId = user.Id
        );
        insert acct;

        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 1',
                Team_Id__c = 'Team 1',
                Email__c = 'NewlyCreatedContact@test.com',
                Comment__c = 'Comment 1',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z',
                FirstName__c = 'First',
                LastName__c = 'Name'
            )
        );
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 2',
                Team_Id__c = 'Team 1',
                Email__c = 'NewlyCreatedContactEmail@test.com',
                Comment__c = 'Comment 2',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z',
                FirstName__c = 'First',
                LastName__c = 'Name'
            )
        );

        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(2, objects.size());
        System.assertNotEquals(null, objects.get(0).Contact__c);
        System.AssertEquals(acct.Id, objects.get(0).Account__c);
    }
    
    @isTest
    public static void getItemsFromEventsWithNoAccountAndNoContactShouldReturnRatingWithoutContact() {
        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 1',
                Team_Id__c = 'Team 1',
                Email__c = 'NewlyCreatedContact@test.com',
                Comment__c = 'Comment 1',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z'
            )
        );

        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(1, objects.size());
        System.assertEquals('Rating 1', objects.get(0).Rating_Id__c);
        System.assert(objects.get(0).Contact__c == null);
    }

    @isTest
    public static void getItemsFromEventsWithValidAccountShouldLinkToAccount() {
        User user = TestUtils.createStandardUser('Bob', 'sales@gearset.com');
        insert user;

        Gearset_Team__c team = new Gearset_Team__c(Gearset_Team_Id__c = 'Team 1');
        insert team;

        Account acct = new Account(
            Name = 'My account',
            Gearset_Team__c = team.Id,
            OwnerId = user.Id
        );
        insert acct;

        List<Rating_Submitted__e> events = new List<Rating_Submitted__e>();
        events.add(
            new Rating_Submitted__e(
                Rating_Id__c = 'Rating 1',
                Team_Id__c = 'Team 1',
                Email__c = 'test@example.com',
                Comment__c = 'Comment 1',
                Score__c = 8,
                Date__c = '2021-01-18T18:11:09.256Z',
                FirstName__c = 'First',
                LastName__c = 'Last'
            )
        );

        RatingSubmittedEventConverter converter = new RatingSubmittedEventConverter();
        List<Rating__c> objects = converter.getItemsFromEvents(events);

        System.AssertEquals(1, objects.size());
        System.AssertEquals(acct.Id, objects.get(0).Account__c);
        System.AssertEquals(user.Id, objects.get(0).OwnerId);
    }
}