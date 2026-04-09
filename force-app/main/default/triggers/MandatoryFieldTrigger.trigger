/**
* @File Name          : MandatoryFieldTrigger.trigger
* @Description        : Trigger to enforce mandatory field validation on Account records.
*                       Skips execution if current user has Bypass_VR__c enabled 
*                       or if the corresponding custom setting flag (Account_Trigger__c) is disabled.
* @Author             : Rizwan
* @Last Modified By   : Rizwan
* @Last Modified On   : August 19, 2025
* @Modification Log   :
*==============================================================================
* Ver   | Date          | Author   | Modification
*==============================================================================
* 1.0   | November 6, 2024 | Rizwan    | Initial Version
* 1.1   | August 19, 2025 | Rizwan    | Added custom setting & user bypass checks
**/
trigger MandatoryFieldTrigger on Account (before insert, before update) {
    
    // Fetch custom setting to control trigger execution
    Active_Trigger_Flow_VR__c settings = Active_Trigger_Flow_VR__c.getInstance();

    // Fetch current user
    User currentUser = [SELECT Bypass_VR__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Skip trigger if user bypass is true OR Account trigger flag is disabled
    if (currentUser.Bypass_VR__c == TRUE || (settings != null && settings.Account_Trigger__c == FALSE)) {
        return; // Early exit
    }

    // If not bypassed, run mandatory field validation
    MandatoryFieldValidator.validateMandatoryFields('Account', Trigger.new);
}