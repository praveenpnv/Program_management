/**
 * Trigger Name: JobStatusChangeTrigger
 * 
 * Status: DISABLED
 * Reason: Logic merged into another process and no longer needed as of 13-Aug-2025.
 * Date Disabled: 13-Aug-2025
 * Author: Rizwan Ahmed
 */
trigger JobStatusChangeTrigger on TR1__Job__c (before insert, before update) {
    // The original logic has been intentionally disabled as part of cleanup.
    
    // if (Trigger.isBefore && Trigger.isUpdate) {
    //     JobStatusChangeHandler.updateHoldFields(Trigger.new, Trigger.oldMap);
    // }
    
    // if (Trigger.isInsert) {
    //     JobStatusChangeHandler.setOpenStatus(Trigger.new);
    // }
    
    // if (Trigger.isUpdate) {
    //     JobStatusChangeHandler.updateOpenClosedFlag(Trigger.new, Trigger.oldMap);
    // }
}