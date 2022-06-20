trigger ContractTrigger on Contract(after update) {
    for (Contract contract : Trigger.new) {
        if (contract.Contract_Type__c != 'Standard Reseller Agreement') {
            continue;
        }

        if (contract.Status == 'Activated') {
            PartnerService.updateAccountPartnerAgreementEndDate(contract);
        }
    }
}
