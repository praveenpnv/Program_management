trigger MandatoryOpportunityFieldTrigger on Opportunity (before insert, before update) {
    MandatoryFieldValidator.validateMandatoryFields('Opportunity', Trigger.new);
}