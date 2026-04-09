trigger SetFileCategoryOnContentVersionBeforeUpdate on ContentVersion (after insert, after update) {
    List<ContentVersion> versionsToUpdate = new List<ContentVersion>();

    for (ContentVersion cv : Trigger.new) {
        Boolean needsUpdate = false;
        ContentVersion cvToUpdate = new ContentVersion(Id = cv.Id);

        if (cv.Is_Resume__c != null) {
            if (cv.Is_Resume__c == true && String.isBlank(cv.File_Category__c)) {
                cvToUpdate.File_Category__c = 'Resume';
                needsUpdate = true;
            }
        }

        if (cv.File_Category__c == 'Resume' && cv.Is_Resume__c == false) {
            cvToUpdate.Is_Resume__c = true;
            needsUpdate = true;
        }

        if (needsUpdate) {
            versionsToUpdate.add(cvToUpdate);
        }
    }

    if (!versionsToUpdate.isEmpty()) {
    TriggerBypassUtil.bypassedFlows.add('SetFileCategoryOnContentVersionBeforeUpdate');
        update versionsToUpdate;
    }
}