public class TeamLicenseRenewal {
    public TeamLicenseRenewal(String teamId, List<LicenseRenewalData> licenseRenewalData) {
        this.teamId = teamId;
        this.licenseRenewalData = licenseRenewalData;
    }
        
    public String teamId { get; private set; }
    public List<LicenseRenewalData> licenseRenewalData { get; private set; }    
}