/**
* @File Name : EventTriggerHelper.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 2, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 2, 2025 |   | Initial Version
**/

public with sharing class EventTriggerHelper {


    // -------- BEFORE INSERT --------
    public static void setDescriptionAndOwner(List<Event> newEvents) {
        Set<Id> sendOutIds = new Set<Id>();
        for (Event ev : newEvents) {
            if (ev.TR1__Send_Out_Schedule_V2__c != null) {
                sendOutIds.add(ev.TR1__Send_Out_Schedule_V2__c);
            }
        }
        if (sendOutIds.isEmpty()) return;

        Map<Id, TR1__Send_Out_Schedule_V2__c> sendOuts = new Map<Id, TR1__Send_Out_Schedule_V2__c>(
            [SELECT Id, Email_Message__c
             FROM TR1__Send_Out_Schedule_V2__c
             WHERE Id IN :sendOutIds]
        );

        for (Event ev : newEvents) {
            if (ev.TR1__Send_Out_Schedule_V2__c != null && sendOuts.containsKey(ev.TR1__Send_Out_Schedule_V2__c)) {
                TR1__Send_Out_Schedule_V2__c so = sendOuts.get(ev.TR1__Send_Out_Schedule_V2__c);
                ev.Description = so.Email_Message__c;
            }
        }
    }

    // -------- AFTER INSERT / UPDATE --------
    public static void manageEventRelations(Set<Id> eventIds) {
        if (eventIds.isEmpty()) return;

        Map<Id, Event> events = new Map<Id, Event>(
            [SELECT Id, OwnerId,TR1__Send_Out_Schedule_V2__c FROM Event WHERE Id IN :eventIds]
        );

        // Collect all SendOut IDs
        Set<Id> sendOutIds = new Set<Id>();
        for (Event ev : events.values()) {
            if (ev.TR1__Send_Out_Schedule_V2__c != null) sendOutIds.add(ev.TR1__Send_Out_Schedule_V2__c);
        }

        Map<Id, TR1__Send_Out_Schedule_V2__c> sendOuts = new Map<Id, TR1__Send_Out_Schedule_V2__c>(
            [SELECT Id, TR1__Interviewers_Ids__c, TR1__Interviewee__c 
             FROM TR1__Send_Out_Schedule_V2__c
             WHERE Id IN :sendOutIds]
        );

        // Collect all existing relations in one query
        Map<Id, Set<Id>> eventToExistingRelations = new Map<Id, Set<Id>>();
        for (EventRelation er : [
            SELECT EventId, RelationId
            FROM EventRelation
            WHERE EventId IN :eventIds
        ]) {
            if (!eventToExistingRelations.containsKey(er.EventId)) {
                eventToExistingRelations.put(er.EventId, new Set<Id>());
            }
            eventToExistingRelations.get(er.EventId).add(er.RelationId);
        }

        List<EventRelation> toInsert = new List<EventRelation>();

        for (Event ev : events.values()) {
            TR1__Send_Out_Schedule_V2__c so = sendOuts.get(ev.TR1__Send_Out_Schedule_V2__c);
            if (so == null) continue;

            Set<Id> participants = new Set<Id>();

            if (so.TR1__Interviewee__c != null && so.TR1__Interviewee__c != ev.OwnerId) {
                participants.add(so.TR1__Interviewee__c);
            }

            if (String.isNotBlank(so.TR1__Interviewers_Ids__c)) {
                for (String uid : so.TR1__Interviewers_Ids__c.split(';')) {
                    Id userId = (Id)uid;
                    if (userId != ev.OwnerId) participants.add(userId);
                }
            }

            Set<Id> existing = eventToExistingRelations.containsKey(ev.Id)
                ? eventToExistingRelations.get(ev.Id)
                : new Set<Id>();

             system.debug('participants'+participants);
             system.debug('existing'+existing);

            for (Id pid : participants) {
                if (!existing.contains(pid)) {
                    toInsert.add(new EventRelation(
                        EventId = ev.Id,
                        RelationId = pid,
                        IsInvitee = true
                    ));
                }
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
    }

    public static void updateIsInvitee(Set<Id> eventIds) {
        List<EventRelation> toUpdate = [
            SELECT Id, IsInvitee, IsWhat
            FROM EventRelation
            WHERE EventId IN :eventIds
              AND (IsInvitee = false OR IsInvitee = null)
              AND IsWhat = false
        ];
        for (EventRelation er : toUpdate) {
            er.IsInvitee = true;
        }
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    public static void syncRSVPStatus(Set<Id> eventIds) {
        if (eventIds.isEmpty()) return;

        Map<Id, Id> eventToSendOut = new Map<Id, Id>();
        for (Event ev : [SELECT Id, TR1__Send_Out_Schedule_V2__c FROM Event WHERE Id IN :eventIds]) {
            eventToSendOut.put(ev.Id, ev.TR1__Send_Out_Schedule_V2__c);
        }

        Map<Id, String> personToStatus = new Map<Id, String>();
        Map<Id, Id> personToEvent = new Map<Id, Id>();

        for (EventRelation er : [
            SELECT EventId, RelationId, Status
            FROM EventRelation
            WHERE EventId IN :eventIds AND Status != null
        ]) {
            if (er.RelationId != null) {
                personToStatus.put(er.RelationId, er.Status);
                personToEvent.put(er.RelationId, er.EventId);
            }
        }

        if (personToStatus.isEmpty()) return;

        List<TR1__Interview_Attendee__c> attendees = [
            SELECT Id, TR1__Contact__c, TR1__User__c, TR1__Send_Out_Schedule_V2__c
            FROM TR1__Interview_Attendee__c
            WHERE TR1__Contact__c IN :personToStatus.keySet()
               OR TR1__User__c IN :personToStatus.keySet()
        ];

        List<TR1__Interview_Attendee__c> updates = new List<TR1__Interview_Attendee__c>();
        for (TR1__Interview_Attendee__c att : attendees) {
            Id personId = att.TR1__Contact__c != null ? att.TR1__Contact__c : att.TR1__User__c;
            Id eventId = personToEvent.get(personId);
            if (eventId == null) continue;

            Id sendOutId = eventToSendOut.get(eventId);
            String status = personToStatus.get(personId);

            if (sendOutId == att.TR1__Send_Out_Schedule_V2__c && status != null) {
                att.RSVP_Status__c = status;
                updates.add(att);
            }
        }

        if (!updates.isEmpty()) update updates;
    }
    
}