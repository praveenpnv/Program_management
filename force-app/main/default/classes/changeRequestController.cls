/**
* @File Name : changeRequestController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 21, 2025 |   | Initial Version
**/

public class changeRequestController {


    @AuraEnabled(cacheable=true)
    public static String getRecordTypeId(String objectApiName, String recordTypeName) {   
    Map<String, Schema.RecordTypeInfo> recordTypes = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosByName();

    if (recordTypes.containsKey(recordTypeName)) {  
        return recordTypes.get(recordTypeName).getRecordTypeId();
    }
    return null;
    }
    
	@AuraEnabled
    public static TR1__Closing_Report__c cloneRecord(Id recordId, Id newRecordTypeId) {
        // Fetch original record

        
       try {

        String fieldSetName = 'Change_Request';
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get('TR1__Closing_Report__c').getDescribe();
            List<Schema.FieldSetMember> fieldSetMembers = describeResult.fieldSets.getMap().get(fieldSetName).getFields();

            List<String> fieldNames = new List<String>();
            for (Schema.FieldSetMember f : fieldSetMembers) {
                fieldNames.add(f.getFieldPath());
            }
            
             // Dynamically build SOQL query
            String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM TR1__Closing_Report__c WHERE Id = :recordId';
            
            // Query original record dynamically
            TR1__Closing_Report__c originalRecord = Database.query(query);

            // Clone the record
            TR1__Closing_Report__c clonedRecord = originalRecord.clone(false, false); 
            clonedRecord.ParentPlacementId__c=recordId;
            clonedRecord.Sales_CR__c   =clonedRecord.TR1__Job_Credit__c;
            clonedRecord.Sales_secondary_CR__c   =clonedRecord.TR1__Other_Credit__c;
            clonedRecord.Recruiting_CR__c   =clonedRecord.TR1__Candidate_Credit__c;
            clonedRecord.Recruiting_secondary_CR__c   =clonedRecord.TR1__Marketing_Credit__c;

            clonedRecord.TR1__Job_Credit__c= null;
            clonedRecord.TR1__Other_Credit__c= null;
            clonedRecord.TR1__Candidate_Credit__c= null;
            clonedRecord.TR1__Marketing_Credit__c= null;


            System.debug('clonedRecord'+clonedRecord);
            return clonedRecord;
        } catch (Exception e) {
            throw new AuraHandledException('Error cloning record: ' + e.getMessage());
        }
    }
}