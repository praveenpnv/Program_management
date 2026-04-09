/**
 * Trigger Name: ConcatenateRichTextFields
 * 
 * Status: DISABLED
 * Reason: Logic merged into another process and no longer needed as of 14-Aug-2025.
 * Date Disabled: 14-Aug-2025
 * Author: Rizwan Ahmed
 */
trigger ConcatenateRichTextFields on TR1__Job__c (before insert, before update) {
    /*for (TR1__Job__c obj : Trigger.new) {
         Check if it's an update operation
        if (Trigger.isUpdate) {
            Compare the current value with the old value to see if it changed
           if (obj.Job_Descripition_and_Responsibilities__c != Trigger.oldMap.get(obj.Id).TR1__Client_Job_Description__c) {
               obj.Job_Descripition_and_Responsibilities__c = obj.TR1__Client_Job_Description__c + 'Job Responsibilities<br/>' + obj.TR1__Responsibilities__c;
        }
   } else if (Trigger.isInsert) {
            For insert, just concatenate without the "Job Responsibilities" text
          obj.Job_Descripition_and_Responsibilities__c = obj.TR1__Client_Job_Description__c + ' ' + obj.TR1__Responsibilities__c;
     }
    }*/
}