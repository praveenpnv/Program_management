trigger EventTriggerStatuswithAttendies on Event (before insert, after insert, after update) {
    System.debug('----------Enter in Event Trigger---------------------');
EventTriggerHandler handler = new EventTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            handler.afterInsertOrUpdate(Trigger.new);
        }
    }
    }