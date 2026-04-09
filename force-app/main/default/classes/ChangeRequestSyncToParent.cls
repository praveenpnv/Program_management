/**
* @File Name         : ChangeRequestSyncToParent.cls
* @Description       : Syncs approved Change Request fields to the parent Placement record using field sets, enabling flexible field mapping and centralized updates.				   
* @Author            : Rizwan Ahmed
* @Last Modified By  : Priyanka S.
* @Created On		 : Jun 16, 2025
* @Last Modified On  : Sep 9, 2025
* @Modification 	 : Sep 09, 2025 - close parent placement once the CR is finished- updateRelatedPlacement()
*/
public class ChangeRequestSyncToParent {

    public static void syncToParent(List<Id> recordIds) {
        // Define object API name and field set name
        final String OBJECT_API = 'TR1__Closing_Report__c';
        final String FIELD_SET_NAME = 'Change_Request_Sync_to_Parent'; // Define this field set in Setup

        // Get field tokens from field set
        Map<String, Schema.SObjectField> allFields = Schema.getGlobalDescribe().get(OBJECT_API).getDescribe().fields.getMap();
        List<Schema.FieldSetMember> fieldSetMembers = SObjectType.TR1__Closing_Report__c.FieldSets.Change_Request_Sync_to_Parent.getFields();

        // Query records with dynamic fields
        String fieldList = 'ParentPlacementId__r.Id, RecordType.DeveloperName';
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            fieldList += ', ' + fsm.getFieldPath();
        }

        List<TR1__Closing_Report__c> changeRequests = Database.query('SELECT ' + fieldList + ' FROM TR1__Closing_Report__c WHERE Id IN :recordIds');

        List<TR1__Closing_Report__c> updates = new List<TR1__Closing_Report__c>();

        for (TR1__Closing_Report__c cr : changeRequests) {
            String devName = cr.RecordType.DeveloperName;

            if (
                (devName != 'Change_Request' && devName != 'Change_Request_Permanent') ||
                (cr.Request_Status__c != 'Approved' && cr.Request_Status__c != 'Back Office Completed') ||
                cr.ParentPlacementId__c == null
            ) {
                continue;
            }
            
            TR1__Closing_Report__c parent = new TR1__Closing_Report__c(Id = cr.ParentPlacementId__c);
            for (Schema.FieldSetMember fsm : fieldSetMembers) {
                String fieldAPI = fsm.getFieldPath();
                // Skip 'Id', relationship fields, and circular Parent assignment
    			if (fieldAPI == 'Id' || fieldAPI.contains('.')) continue;
                
                Object value = cr.get(fieldAPI);
                
                if (fieldAPI == 'ParentPlacementId__c' && String.valueOf(value) == String.valueOf(cr.ParentPlacementId__c)) {
                    continue; // Avoid circular dependency
                }
                
                // Skip original managed package credit fields to prevent them from overwriting the mapped values.
                // The custom fields (e.g., Sales_CR__c) are the source of truth from the Change Request.
                if (fieldAPI == 'TR1__Job_Credit__c' || 
                    fieldAPI == 'TR1__Other_Credit__c' || 
                    fieldAPI == 'TR1__Candidate_Credit__c' || 
                    fieldAPI == 'TR1__Marketing_Credit__c') {
                    continue;
                }

                // Handle special mapping for credit fields from Change Request back to Parent Placement
                // This logic now correctly handles null values, allowing fields to be cleared on the parent.
                if (fieldAPI == 'Sales_CR__c') {
                    parent.put('TR1__Job_Credit__c', value);
                } else if (fieldAPI == 'Sales_secondary_CR__c') {
                    parent.put('TR1__Other_Credit__c', value);
                } else if (fieldAPI == 'Recruiting_CR__c') {
                    parent.put('TR1__Candidate_Credit__c', value);
                } else if (fieldAPI == 'Recruiting_secondary_CR__c') {
                    parent.put('TR1__Marketing_Credit__c', value);
                } else {
                    // For all other fields in the field set, use direct mapping
                    parent.put(fieldAPI, value);
                }
            }

            updates.add(parent);
        }

        if (!updates.isEmpty()) {
            System.debug('Debug updates->'+updates);
            update updates;
        }
    }
    
     public static void updateRelatedPlacements(List<Id> parentPlacementId) {
        if (parentPlacementId.isEmpty()) {
            return; // No placements to update
        }
        List<TR1__Closing_Report__c> placementsToUpdate = [
            SELECT Id, Status_US__c 
            FROM TR1__Closing_Report__c 
            WHERE Id IN :parentPlacementId
            AND Status_US__c != 'Closed' // Only update if not already closed
        ];
        for (TR1__Closing_Report__c placement : placementsToUpdate) {
            placement.Status_US__c = 'Closed';
        }
        // Bulk DML operation
        if (!placementsToUpdate.isEmpty()) {
            try {
                update placementsToUpdate;
            } catch (DmlException e) {
                
                    System.debug('Failed to close parent Placement: ' + e.getMessage());
                
            }
        }
    }

}