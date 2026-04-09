/**
* @Trigger Name      : PlacementTrigger
* @Description       : 
*   Disabled trigger — logic moved/merged into RD1_ClosingReportTrigger.
*   Previously called PlacementTriggerHandller.validateMinimumWage(Trigger.new) 
*   to ensure minimum wage requirements were met on Closing Report records 
*   before insert and update events.
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Last Modified On  : Aug 13, 2025
*/
trigger PlacementTrigger on TR1__Closing_Report__c (before insert, before update) {
     // Disabled trigger
 /*if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        PlacementTriggerHandller.validateMinimumWage(Trigger.new);
    }*/
}