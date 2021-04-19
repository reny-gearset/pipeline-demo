public class LicenseRenewalData {
    public String licenseId { get; private set; }
    public String licensePlanName { get; private set; }
    public Integer licenseQuantity { get; private set; }
    public String fastspringReference { get; private set; }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public LicenseRenewalData(String licenseId, String licensePlanName, Integer licenseQuantity, String fastspringReference) {
        this.licenseId = licenseId;
        this.licensePlanName = licensePlanName;
        this.licenseQuantity = licenseQuantity;
        this.fastspringReference = fastspringReference;
    }
}