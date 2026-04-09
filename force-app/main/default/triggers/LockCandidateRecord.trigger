/**
 * Trigger Name: LockCandidateRecord
 * 
 * Status: DISABLED
 * Reason: This trigger logic has been merged into another process(ContactTrigger) and is no longer needed.
 * Date Disabled: 19-Aug-2025
 * Author: Rizwan Ahmed
 */
trigger LockCandidateRecord on Contact (before update) {
    // Get the System Administrator Profile ID
   /* Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    
    for (Contact c : Trigger.new) {
        Contact oldRecord = Trigger.oldMap.get(c.Id);

        // If DO_NOT_USE__c is checked and record is being modified
        if (oldRecord.DO_NOT_USE__c == true) {
            // Get the running user's profile
            User runningUser = [SELECT ProfileId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            // If the user is NOT a System Admin, prevent edits
            if (runningUser.ProfileId != sysAdminProfile.Id) {
                c.addError('Please Contact HR support at hrsupport@randstadusa.com to unlock this profile');
            }
        }
    }*/
}