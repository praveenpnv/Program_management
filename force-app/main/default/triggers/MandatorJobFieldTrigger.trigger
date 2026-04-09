/**
 * Trigger Name: MandatorJobFieldTrigger
 * 
 * Status: DISABLED
 * Reason: This trigger logic has been merged into another process and is no longer needed.
 * Date Disabled: 14-Aug-2025
 * Author: Rizwan Ahmed
 */
trigger MandatorJobFieldTrigger on TR1__Job__c (before insert, before update) {
    // The below logic has been intentionally disabled as part of cleanup.
    // if (Test.isRunningTest()) { return; }
    // if (!TriggerBypassUtil.shouldBypass('JobPrefillHandler')) {
    //     MandatoryFieldValidatorByRecType.validateMandatoryFields('TR1__Job__c', Trigger.new);
    // }
}