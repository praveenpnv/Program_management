trigger StoryStatusTrigger on Story__c (after insert, after update) {

    
    Map<Id, String> fromStatusMap = new Map<Id, String>();

    for (Story__c newStory : Trigger.new) {
        String oldStatus = Trigger.isInsert ? null : Trigger.oldMap.get(newStory.Id)?.Status__c;
        String newStatus = newStory.Status__c;

        
        if (String.isNotBlank(newStatus) && newStatus != oldStatus) {
            fromStatusMap.put(newStory.Id, oldStatus);
        }
    }

    if (fromStatusMap.isEmpty()) return;

    
    for (Id storyId : fromStatusMap.keySet()) {
        String fromStatus = fromStatusMap.get(storyId);
        String toStatus   = Trigger.newMap.get(storyId).Status__c;
        StoryStatusService.process(storyId, fromStatus, toStatus);
    }
}