public with sharing class InterviewListController {
    @AuraEnabled(cacheable=true)
    public static List<TR1__Send_Out_Schedule_V2__c> getInterviewSchedules(Id recordId, String recordTypeId) {
        return [
            SELECT Id, Interview_Level__c, TR1__Interview_Date_Time__c, Interview_Feedback__c, TR1__Application_V2__c, RecordTypeId,VideoCallid__c
            FROM TR1__Send_Out_Schedule_V2__c
            WHERE TR1__Application_V2__c = :recordId
            AND RecordTypeId = :recordTypeId
        ];
    }

    @AuraEnabled(cacheable=true)
public static Map<Id, String> getRSVPStatusesBySendOut(List<Id> sendOutIds) {
        Map<Id, String> result = new Map<Id, String>();

        if (sendOutIds != null && !sendOutIds.isEmpty()) {
            for (TR1__Interview_Attendee__c att : [
                SELECT Id, RSVP_Status__c, TR1__Send_Out_Schedule_V2__c
                FROM TR1__Interview_Attendee__c
                WHERE TR1__Send_Out_Schedule_V2__c IN :sendOutIds AND TR1__Contact__c != Null
            ]) {
                // Picks the first RSVP status per Send Out Schedule
                if (!result.containsKey(att.TR1__Send_Out_Schedule_V2__c)) {
                    result.put(att.TR1__Send_Out_Schedule_V2__c, att.RSVP_Status__c);
                }
            }
        }
        system.debug('result'+result);
        return result;
    }
}