@IsTest
public class TeamRoutesTest {
    private static final String TEAM_ID_WITH_NO_MEMBERS = '7110c9e6-3ce2-450f-aca3-03013112677e';
    private static final String MALFORMED_TEAM_ID = 'dfsajkfldjsakfd';
    private static final String TEAM_ID_WITH_LOGIN_STATS = '7110c9e6-aca3-450f-3ce2-03013112677e';
    
    @isTest static void testGetTeamMemberLoginStatsReturnsEmptyListIfTeamHasNoMember() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TeamRoutesCalloutMock());
        
        List<TeamRoutes.TeamMemberStats> teamMemberStats = TeamRoutes.getTeamMemberLoginStats(TEAM_ID_WITH_NO_MEMBERS);
        
        Test.stopTest();
        
        System.assertEquals(new List<TeamRoutes.TeamMemberStats>(), teamMemberStats);
    }
    
    @isTest static void testGetTeamMemberLoginStatsErrorsOnMalformedTeamId() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new TeamRoutesCalloutMock());
        
        try {
            TeamRoutes.getTeamMemberLoginStats(MALFORMED_TEAM_ID);
            System.assert(false);
        } catch (CalloutException ex) {
            System.debug(ex);
        } finally {
            Test.stopTest();
        }
    }
    
    @isTest static void testGetTeamMemberLoginStatsOnNormalTeam() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TeamRoutesCalloutMock());
        
        List<TeamRoutes.TeamMemberStats> teamMemberStats = TeamRoutes.getTeamMemberLoginStats(TEAM_ID_WITH_LOGIN_STATS);
        
        Test.stopTest();
        
        List<TeamRoutes.TeamMemberStats> expected = new List<TeamRoutes.TeamMemberStats>();
        
        TeamRoutes.TeamMemberStats stats1 = new TeamRoutes.TeamMemberStats();
        stats1.user_id = 'linkedinVmxYLWpPVnpSNA==';
        stats1.number_of_logins = 1;
        stats1.latest_login = (Datetime) JSON.deserialize('"2019-09-26T14:36:12.164Z"', Datetime.class);
        stats1.display_name = 'Calvin Childs';
        
        TeamRoutes.TeamMemberStats stats2 = new TeamRoutes.TeamMemberStats();
        stats2.user_id = 'linkedinVmxYLWpPVnpSNC==';
        stats2.number_of_logins = 0;
        stats2.latest_login = null;
        stats2.display_name = 'Yankai Ren';
        
        expected.add(stats1);
        expected.add(stats2);
        System.assertEquals(expected, teamMemberStats);
    }
    
    private class TeamRoutesCalloutMock implements HttpCalloutMock {
        
        public HttpResponse respond(HttpRequest req) {
            System.debug('In TeamRoutesCalloutMock.respond() method.');
            System.debug('Endpoint: ' + req.getEndpoint());
            
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().Contains(TEAM_ID_WITH_NO_MEMBERS)) {
                res.setStatusCode(200);
                res.setBody('[]');
            } else if (req.getEndpoint().Contains(MALFORMED_TEAM_ID)) {
                res.setStatusCode(400);
                res.setBody('{"message": "Failed to retrieve team member login stats for ID dfhaskjdhfjkshadjf"}');
            } else if (req.getEndpoint().Contains(TEAM_ID_WITH_LOGIN_STATS)) {
                res.setStatusCode(200);
                res.setBody('[{"user_id": "linkedinVmxYLWpPVnpSNA==", "number_of_logins": "1", "latest_login": "2019-09-26T14:36:12.164Z", "display_name": "Calvin Childs"}, {"user_id": "linkedinVmxYLWpPVnpSNC==", "display_name": "Yankai Ren", "number_of_logins": "0", "latest_login": null}]');
            }
            
            return res;
        }
    }
}