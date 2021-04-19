public with sharing class TeamRoutes {
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public class TeamMemberStats {
        @AuraEnabled
        public String user_id { public get; public set; }
        
        @AuraEnabled
        public Integer number_of_logins { public get; public set; }
        
        @AuraEnabled
        public DateTime latest_login { public get; public set; }
        
        @AuraEnabled
        public String display_name { public get; public set; }
        
        public Boolean equals(Object o) {
            if (!(o instanceof TeamMemberStats)) {
                return false;
            }
            
            TeamMemberStats other = (TeamMemberStats) o;
            return (user_id != null ? user_id.equals(other.user_id) : other.user_id == null) &&
                (number_of_logins == other.number_of_logins) &&
                (latest_login == other.latest_login) &&
                (display_name != null ? display_name.equals(other.display_name) : other.display_name == null);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<TeamMemberStats> getTeamMemberLoginStats(String teamId) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(String.format('callout:Gearset_Admin/api/teams/{0}/user-login-stats', new List<Object> {teamId}));
        req.setMethod('GET');
        req.setHeader('Authorization', '{!$Credential.Password}'); // NOPMD
        req.setHeader('X-Salesforce-Callout-Email', UserInfo.getUserEmail());
        req.setHeader('X-Salesforce-Callout-DisplayName', UserInfo.getName());
        req.setHeader('X-Salesforce-Callout-UserId', UserInfo.getUserId());
        req.setHeader('CF-Access-Client-Id', '{!$Credential.UserName}');
        req.setHeader('CF-Access-Client-Secret', '{!$Credential.Password}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Failed to retrieve team login stats from admin site for teamId: ' + teamId + ', statusCode=' + res.getStatusCode());
        }
        
        return (List<TeamMemberStats>) JSON.deserialize(res.getBody(), List<TeamMemberStats>.class);
    }
}