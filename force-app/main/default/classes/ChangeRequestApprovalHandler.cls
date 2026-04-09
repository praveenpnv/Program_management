/**
* @File Name         : ChangeRequestApprovalHandler.cls
* @Description       : Provides server-side logic for retrieving paginated Change Request Closing Reports 
*                      with Request_Status__c = 'Submitted', using field set mappings to sync to parent records.
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Created On        : Jun 16, 2025
* @Last Modified On  : Jul 25, 2025
*/
public with sharing class ChangeRequestApprovalHandler {
    
    /* Fetch paginated Change Request Closing Reports where Status_US__c = 'Ready for Back Office' */
    @AuraEnabled()
    public static List<TR1__Closing_Report__c> getFilteredReports(Integer pageSize, Integer pageNumber) {
        List<Id> recordTypeIds = new List<Id>();
        for (RecordType rt : [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'TR1__Closing_Report__c' 
              AND Name IN ('Change Request', 'Change Request Permanent')
        ]) {
            recordTypeIds.add(rt.Id);
        }

        return [
            SELECT Id, Name, Request_Status__c, Status_US__c, CreatedDate, TR1__Job__r.Name, Request_Type__c, Requested_by__c,LastModifiedBy.Name, ParentPlacementId__r.Candidate_Name__c, TR1__Account__r.Name
            FROM TR1__Closing_Report__c
            WHERE RecordTypeId IN :recordTypeIds
              AND Request_Status__c = 'Submitted'
            ORDER BY Name DESC
            LIMIT :pageSize
            OFFSET :((pageNumber - 1) * pageSize)
        ];
    }

    /* Return total count of Change Request Closing Reports ready for back office */
    @AuraEnabled()
    public static Integer getTotalCount() {
        List<Id> recordTypeIds = new List<Id>();
        for (RecordType rt : [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'TR1__Closing_Report__c' 
              AND Name IN ('Change Request', 'Change Request Permanent')
        ]) {
            recordTypeIds.add(rt.Id);
        }

        return [
            SELECT COUNT()
            FROM TR1__Closing_Report__c
            WHERE RecordTypeId IN :recordTypeIds
              AND Request_Status__c = 'Submitted'
        ];
    }
}