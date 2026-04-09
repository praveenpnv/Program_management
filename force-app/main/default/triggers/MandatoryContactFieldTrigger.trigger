/**
 * Trigger Name: MandatoryContactFieldTrigger
 * 
 * Status: DISABLED
 * Reason: This trigger logic has been merged into another process(ContactTrigger) and is no longer needed.
 * Date Disabled: 20-Aug-2025
 * Author: Rizwan Ahmed
 */
trigger MandatoryContactFieldTrigger on Contact (before insert, before update) {
   /*  if (!TriggerBypassUtil.shouldBypass('TextkernelConvertedCandidates') && !TriggerBypassUtil.shouldBypass('SetFileCategoryOnContentVersionBeforeUpdate')) {
        MandatoryFieldValidatorByRecType.validateMandatoryFields('Contact', Trigger.new);
    }*/
}