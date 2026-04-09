/**
* @File Name : VideoCallParticipantHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 8, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 8, 2025 |   | Initial Version
**/

public class VideoCallParticipantHandler {

    public static void afterInsertOrUpdate(List<VideoCallParticipant> newList) {
        Set<Id> videoCallIds = new Set<Id>();
        Set<Id> personIds = new Set<Id>();

        for (VideoCallParticipant vcp : newList) {
            if (vcp.VideoCallId != null && vcp.RelatedPersonId != null) {
                videoCallIds.add(vcp.VideoCallId);
                personIds.add(vcp.RelatedPersonId);
            }
        }
        if (videoCallIds.isEmpty()) return;

        // Step 1: Get VideoCalls with timings
        Map<Id, VideoCall> videoCallMap = new Map<Id, VideoCall>(
            [SELECT Id, StartDateTime, EndDateTime FROM VideoCall WHERE Id IN :videoCallIds]
        );

        // Step 2: Build VideoCall -> Participants map
        Map<Id, Set<Id>> videoCallToPersonMap = new Map<Id, Set<Id>>();
        for (VideoCallParticipant vcp : [
            SELECT VideoCallId, RelatedPersonId
            FROM VideoCallParticipant
            WHERE VideoCallId IN :videoCallIds
        ]) {
            if (!videoCallToPersonMap.containsKey(vcp.VideoCallId)) {
                videoCallToPersonMap.put(vcp.VideoCallId, new Set<Id>());
            }
            videoCallToPersonMap.get(vcp.VideoCallId).add(vcp.RelatedPersonId);
        }

        // Step 3: Prepare SendOut updates
        Map<Id, TR1__Send_Out_Schedule_V2__c> sendoutMap = new Map<Id, TR1__Send_Out_Schedule_V2__c>();
        for (Id vcId : videoCallMap.keySet()) {
            VideoCall vc = videoCallMap.get(vcId);
            Set<Id> relatedPersons = videoCallToPersonMap.get(vcId);

            if (relatedPersons != null && !relatedPersons.isEmpty()) {
                List<EventRelation> eventRelations = [
                    SELECT Event.StartDateTime, Event.EndDateTime, Event.TR1__Send_Out_Schedule_V2__c, RelationId
                    FROM EventRelation
                    WHERE RelationId IN :relatedPersons
                    AND Event.StartDateTime <= :vc.EndDateTime
                    AND Event.EndDateTime >= :vc.StartDateTime
                ];

                for (EventRelation er : eventRelations) {
                    if (er.Event.TR1__Send_Out_Schedule_V2__c != null) {
                        sendoutMap.put(er.Event.TR1__Send_Out_Schedule_V2__c, new TR1__Send_Out_Schedule_V2__c(
                            Id = er.Event.TR1__Send_Out_Schedule_V2__c,
                            VideoCallid__c = vcId
                        ));
                    }
                }
            }
        }

        if (!sendoutMap.isEmpty()) {
            update sendoutMap.values();
        }

        // Step 4: Share VideoCall with Users
        Set<String> uniqueShares = new Set<String>();
        List<VideoCallShare> sharesToInsert = new List<VideoCallShare>();

        for (Id vcId : videoCallToPersonMap.keySet()) {
            for (Id pId : videoCallToPersonMap.get(vcId)) {
                if (pId.getSObjectType() == User.SObjectType) {
                    String key = vcId + '-' + pId;
                    if (!uniqueShares.contains(key)) {
                        uniqueShares.add(key);
                        sharesToInsert.add(new VideoCallShare(
                            ParentId = vcId,
                            UserOrGroupId = pId,
                            AccessLevel = 'Read'
                        ));
                    }
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            try {
                insert sharesToInsert;
            } catch (DmlException e) {
                System.debug('Error sharing VideoCalls: ' + e.getMessage());
            }
        }
    }
}