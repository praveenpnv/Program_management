/**
* @Trigger Name      : JobTrigger
* @Description       : 
*   1. Concatenates client job description and responsibilities.
*   2. Handles job status changes (set open status, update hold fields, open/closed flag).
*   3. Creates an Opportunity for VMS Jobs if criteria is met.
*   4. Validates minimum wage logic.
*   5. Validates mandatory fields by record type.
*   6. Controlled by custom setting Placement_Flow__c.
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Last Modified On  : Aug 14, 2025
* @Modification Log  :
*===============================================================================
* Ver   | Date        | Author         | Modification
*===============================================================================
* 1.0   | Jul 14, 2025| Rizwan Ahmed   | Initial trigger creation with VMS Opportunity and wage validation.
* 2.0   | Aug 14, 2025| Rizwan Ahmed    | Combined multiple job triggers into one and added Job_Trigger__c check.
*/
trigger JobTrigger on TR1__Job__c (before insert, before update) {
    
    // Fetch custom setting to control trigger execution
    Active_Trigger_Flow_VR__c settings = Active_Trigger_Flow_VR__c.getInstance();
    if (settings != null && settings.Job_Trigger__c == false) {
        return; // Early exit if Placement Flow is disabled
    }
    
    if (Trigger.isBefore) {
        
        // =====================================
        // 1. Concatenate Rich Text Fields logic
        // =====================================
        for (TR1__Job__c obj : Trigger.new) {
            if (Trigger.isUpdate) {
                if (obj.Job_Descripition_and_Responsibilities__c != Trigger.oldMap.get(obj.Id).TR1__Client_Job_Description__c) {
                    obj.Job_Descripition_and_Responsibilities__c = 
                        obj.TR1__Client_Job_Description__c + 'Job Responsibilities<br/>' + obj.TR1__Responsibilities__c;
                }
            } else if (Trigger.isInsert) {
                obj.Job_Descripition_and_Responsibilities__c = 
                    obj.TR1__Client_Job_Description__c + ' ' + obj.TR1__Responsibilities__c;
            }
        }
        
        // =====================================
        // 2. Job Status Change logic
        // =====================================
        if (Trigger.isUpdate) {
            JobStatusChangeHandler.updateHoldFields(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isInsert) {
            JobStatusChangeHandler.setOpenStatus(Trigger.new);
        }
        if (Trigger.isUpdate) {
            JobStatusChangeHandler.updateOpenClosedFlag(Trigger.new, Trigger.oldMap);
        }
        
        // =====================================
        // 3. Create Opportunity for VMS Jobs
        // =====================================
        if (Trigger.isInsert) {
            VMSJobOpportunityHandler.handle(Trigger.new);
        }
        
        // =====================================
        // 4. Validate Minimum Wage Logic
        // =====================================
        // if (Trigger.isInsert || Trigger.isUpdate) {
        //     JobTriggerHandler.validateMinimumWage(Trigger.new); //Business Asked to Remove this logic.
        // }
        
        // =====================================
        // 5. Mandatory Fields Validation
        // =====================================
        if (!Test.isRunningTest()) {
            if (!TriggerBypassUtil.shouldBypass('JobPrefillHandler')&& !TriggerBypassUtil.shouldBypass('TextkernelConvertedJobs')) {
                MandatoryFieldValidatorByRecType.validateMandatoryFields('TR1__Job__c', Trigger.new);
            }
        }
    }
}