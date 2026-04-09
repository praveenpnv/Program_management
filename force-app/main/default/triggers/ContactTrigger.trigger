trigger ContactTrigger on Contact (before insert, before update) {
    
    // Fetch custom setting to control trigger execution
    Active_Trigger_Flow_VR__c settings = Active_Trigger_Flow_VR__c.getInstance();

    // Fetch current user (for bypass and profile check)
    User runningUser = [SELECT Id, ProfileId, Bypass_VR__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];

    // Skip entire trigger if user bypass is true OR Contact trigger flag is disabled
    if (runningUser.Bypass_VR__c == TRUE || (settings != null && settings.Contact_Trigger__c == FALSE)) {
        return; // Early exit
    }

    // Logic 1: Lock candidate record if DO_NOT_USE__c is checked
    // Get System Administrator Profile Id (cached once per trigger run)
    Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
	
    if (Trigger.isUpdate) {
	if(Test.isRunningTest()) { return; }
        for (Contact c : Trigger.new) {
            Contact oldRecord = Trigger.oldMap.get(c.Id);

            if (oldRecord.DO_NOT_USE__c == TRUE) {
                if (runningUser.ProfileId != sysAdminProfile.Id) {
                    c.addError('Please Contact HR support at hrsupport@randstadusa.com to unlock this profile');
                }
            }
        }
    }

    // Logic 2: Mandatory field validation
     if (Trigger.isBefore) {
            if (!TriggerBypassUtil.shouldBypass('TextkernelConvertedCandidates') && 
                !TriggerBypassUtil.shouldBypass('SetFileCategoryOnContentVersionBeforeUpdate')) {
                
                MandatoryFieldValidatorByRecType.validateMandatoryFields('Contact', Trigger.new);
            }
     }
}