/**
* @Trigger Name      : MandatoryEngagementFieldTrigger
* @Description       : 
*   Disabled trigger — logic moved/merged into RD1_ClosingReportTrigger.
*   Previously used to validate mandatory fields on Closing Report records 
*   based on record type before insert and update events.
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Last Modified On  : Aug 13, 2025
*/
trigger MandatoryEngagementFieldTrigger on TR1__Closing_Report__c (before insert, before update) {
     // Disabled trigger
    /*MandatoryFieldValidatorByRecType.validateMandatoryFields('TR1__Closing_Report__c', Trigger.new);*/
}