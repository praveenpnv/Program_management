/**
* @File Name : EventTriggerHandler.cls
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

public with sharing class EventTriggerHandler {

    public void beforeInsert(List<Event> newEvents) {
        EventTriggerHelper.setDescriptionAndOwner(newEvents);
    }

    public void afterInsertOrUpdate(List<Event> newEvents) {
        Set<Id> eventIds = new Map<Id, Event>(newEvents).keySet();
        if (eventIds.isEmpty()) return;

        EventTriggerHelper.manageEventRelations(eventIds);
        EventTriggerHelper.updateIsInvitee(eventIds);
        EventTriggerHelper.syncRSVPStatus(eventIds);
    }
}