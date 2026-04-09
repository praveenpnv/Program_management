trigger VideoCallParticipantShare on VideoCallParticipant (after insert, after update) {
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        VideoCallParticipantHandler.afterInsertOrUpdate(Trigger.new);
    }
}