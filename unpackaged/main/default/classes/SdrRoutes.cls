public with sharing class SdrRoutes {
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public class Org {
        @AuraEnabled
        public String orgid { public get; public set; }
        
        @AuraEnabled
        public String orgtype { public get; public set; }
        
        @AuraEnabled
        public String username { public get; public set; }

        @AuraEnabled
        public DateTime first_authorized { public get; public set; }
                
        public Boolean equals(Object o) {
            if (!(o instanceof Org)) {
                return false;
            }
            
            Org other = (Org) o;
            return (orgid != null ? orgid.equals(other.orgid) : other.orgid == null) &&
                (orgtype != null ? orgtype.equals(other.orgtype) : other.orgtype == null) &&
                (username != null ? username.equals(other.username) : other.username == null) &&
                (first_authorized == other.first_authorized);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Org> getUserOrgs(String userEmail) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(String.format('callout:Gearset_Admin/api/sdr/events/orgs?email={0}', new List<Object> { userEmail }));
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
            throw new CalloutException('Failed to retrieve user orgs from admin site for userEmail: ' + userEmail + ', statusCode=' + res.getStatusCode());
        }
        
        return (List<Org>) JSON.deserialize(res.getBody(), List<Org>.class);
    }
}