/**
* @File Name         : ChangeRequestHandler.cls
* @Description       : Handles logic for Change Request Closing Reports, checking for approved records and triggering parent sync based on specific field set mappings.			   
* @Author            : Rizwan Ahmed
* @Last Modified By  : Priyanka S.
* @Created On		 : Jun 16, 2025
* @Last Modified On  : Sep 09, 2025
* @Modification 	 : Sep 09, 2025 - close parent placement once the CR is finished
*/
public class ChangeRequestHandler {
    public static void afterUpdate(List<TR1__Closing_Report__c> newplacementList, Map<Id, TR1__Closing_Report__c> oldMap) {
        List<Id> eligibleRecordIds = new List<Id>();
        List<Id> parentPlacementId = new List<Id>();

        // Get RecordTypeId → DeveloperName map
        Map<Id, String> recordTypeIdToDevName = new Map<Id, String>();
        for (Schema.RecordTypeInfo rtInfo : TR1__Closing_Report__c.SObjectType.getDescribe().getRecordTypeInfos()) {
            if (rtInfo.isAvailable()) {
                recordTypeIdToDevName.put(rtInfo.getRecordTypeId(), rtInfo.getDeveloperName());
            }
        }
        for (TR1__Closing_Report__c rec : newplacementList) {
            TR1__Closing_Report__c oldRec = oldMap.get(rec.Id);
            String devName = recordTypeIdToDevName.get(rec.RecordTypeId);

            if (
                (devName == 'Change_Request' || devName == 'Change_Request_Permanent') &&
                (rec.Request_Status__c == 'Approved' || rec.Request_Status__c == 'Back Office Completed') &&
                oldRec.Request_Status__c != rec.Request_Status__c &&
                rec.ParentPlacementId__c != null
            ) {
                eligibleRecordIds.add(rec.Id);
            }
            //close parent placement once the CR is finished
            System.debug('rec.Request_Status__c='+rec.Request_Status__c);
            System.debug('oldRec.Request_Status__c'+oldRec.Request_Status__c);
            System.debug('rec.Request_Type__c'+rec.Request_Type__c);
            if (
                (devName == 'Change_Request' || devName == 'Change_Request_Permanent') &&
                rec.Request_Type__c == 'Finish' &&
                (rec.Request_Status__c == 'Approved' || rec.Request_Status__c == 'Back Office Completed') &&
                oldRec.Request_Status__c != rec.Request_Status__c
            ) {
				system.debug('inside CR finish logic');
                parentPlacementId.add(rec.ParentPlacementId__c);
            }
             
        }

        if (!eligibleRecordIds.isEmpty()) {
            ChangeRequestSyncToParent.syncToParent(eligibleRecordIds);
        }
        
         if (!parentPlacementId.isEmpty()) {
             system.debug('inside if parentPlacementId');
            ChangeRequestSyncToParent.updateRelatedPlacements(parentPlacementId);
        }
             
    }
}