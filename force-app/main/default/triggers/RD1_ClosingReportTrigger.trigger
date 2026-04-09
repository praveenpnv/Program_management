/**
* @Trigger Name      : RD1_ClosingReportTrigger
* @Description       : 
*   1. Calculates fee percentage on Closing Report records during insert and update.
*   2. Ensures Placement_Fee_Flat__c and TR1__Salary__c values are used to compute TR1__Fee_Percentage__c.
*   3. Trigger to sync approved Change Requests to their parent Placement records upon update.
*	4. Minimum wage requirements were met on Closing Report records
*	5. Validate mandatory fields on Closing Report records
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Last Modified On  : Jul 23, 2025
*/
trigger RD1_ClosingReportTrigger on TR1__Closing_Report__c (before insert,  After insert, before update, after update) {

    // Fetch the hierarchy custom setting for the org
    Active_Trigger_Flow_VR__c settings = Active_Trigger_Flow_VR__c.getInstance();
	if (settings != null && settings.Placement_Trigger__c == false) {
    	return; //Early exit
    }
    // Proceed only if Placement_Trigger__c is TRUE
    if (settings != null && settings.Placement_Trigger__c == true) {
        // ===== BEFORE INSERT / UPDATE =====
        if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) {
            // From original PlacementFeeCalculator trigger
            PlacementFeeCalculator.beforeInsertOrUpdate(
                Trigger.new,
                Trigger.isInsert ? null : Trigger.oldMap
            );

            // From original MandatoryEngagementFieldTrigger
            MandatoryFieldValidatorByRecType.validateMandatoryFields(
                'TR1__Closing_Report__c',
                Trigger.new
            );

            // From original PlacementTrigger
            PlacementTriggerHandller.validateMinimumWage(Trigger.new);
        }
        
        if (Trigger.isAfter && Trigger.isInsert) {
            system.debug('Compare Parent Placement vs Change Request');
            // 🔹 Compare Parent Placement vs Change Request
           CustomClosingReportHandler.SendEmail(Trigger.new);
        }

        // ===== AFTER UPDATE =====
        if (Trigger.isAfter && Trigger.isUpdate) {
            // From original ChangeRequestHandler trigger
            ChangeRequestHandler.afterUpdate(Trigger.new, Trigger.oldMap);
            
            //CustomClosingReportHandler.SendEmail(Trigger.new);

        }
    }
}