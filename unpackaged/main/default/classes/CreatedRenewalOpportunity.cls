public class CreatedRenewalOpportunity {
    public CreatedRenewalOpportunity(Opportunity opportunity, List<LicenseRenewalData> licenseRenewalDatas) {
        this.opportunityId = opportunity.Id;
        
        this.licenseIds = new List<String>();
        for (LicenseRenewalData licenseRenewalData : licenseRenewalDatas) {
            this.licenseIds.add(licenseRenewalData.licenseId);
        }
    }
    
    public Id opportunityId { get; private set; }
    public List<String> licenseIds { get; private set; }
}