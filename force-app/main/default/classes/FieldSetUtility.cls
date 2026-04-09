/**
* @File Name : FieldSetUtility.cls
* @Description :
* @Author :
* @Last Modified By : Rizwan
* @Last Modified On : November 6, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 17, 2024 |   | Initial Version
* 1.1 | November 6, 2024 | Rizwan | Updated to include all fields in unfilledMandatoryFields
* 1.2 | August 19, 2025 | Priyanka | Updated to include opportunity mandatory fieldset
**/
public with sharing class FieldSetUtility {
    public class ApplicantDataWrapper {
        @AuraEnabled public String applicantId;
        @AuraEnabled public List<String> unfilledMandatoryFields;
        @AuraEnabled public Boolean allFieldsFilled;
    }
    public class OpportunityDataWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public List<String> unfilledMandatoryFields;
        @AuraEnabled public Boolean allFieldsFilled;
    }

    @AuraEnabled(cacheable=true)
    public static ApplicantDataWrapper getApplicantData(String applicationId, String objectName, String fieldSetName) {
        ApplicantDataWrapper wrapper = new ApplicantDataWrapper();
        
        // Get applicantId
        TR1__Application_V2__c applicationRecord = [
            SELECT TR1__Applicant__c
            FROM TR1__Application_V2__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        wrapper.applicantId = (applicationRecord != null) ? applicationRecord.TR1__Applicant__c : null;
        
        // Retrieve all fields from field set
        wrapper.unfilledMandatoryFields = getUnfilledMandatoryFields(objectName, fieldSetName, wrapper.applicantId);
        
        // Set flag if all fields are filled
        wrapper.allFieldsFilled = wrapper.unfilledMandatoryFields.isEmpty();
        
        return wrapper;
    }

    private static List<String> getUnfilledMandatoryFields(String objectName, String fieldSetName, Id recordId) {
        List<String> allFieldNames = new List<String>();
        List<String> unfilledFields = new List<String>();
        
        // Describe the object dynamically
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjectType = gd.get(objectName);
        if (sobjectType == null) {
            return allFieldNames; // Handle error gracefully
        }
        Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();
        
        // Retrieve the FieldSet details
        Schema.FieldSet fieldSet = describeResult.FieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) {
            return allFieldNames; // Handle error gracefully
        }
        
        // Query the record to get the field values
        SObject record;
        try {
            String query = 'SELECT ';
            List<String> fieldPaths = new List<String>();
            
            // Collect all fields from the field set
            for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
                String fieldName = fsm.getFieldPath();
                fieldPaths.add(fieldName);
                allFieldNames.add(fieldName); // Add all field names to the list
            }
            
            // Build dynamic SOQL
            query += String.join(fieldPaths, ', ') + ' FROM ' + objectName + ' WHERE Id = :recordId';
            
            // Execute the query
            record = Database.query(query);
        } catch (Exception e) {
            return allFieldNames;
        }
        
        // Check for mandatory fields that are not filled in
        Boolean allFieldsHaveValues = true;
        for (String fieldName : allFieldNames) {
            Object fieldValue = record.get(fieldName);
            if (fieldValue == null) {
                unfilledFields.add(fieldName);
                allFieldsHaveValues = false;
            }
        }
        
        return allFieldsHaveValues ? new List<String>() : allFieldNames;
    }
    // Method for Opportunity data
    @AuraEnabled(cacheable=false)
    public static OpportunityDataWrapper getOpportunityMandatoryFields(String recordId, String objectName, String fieldSetName) {
        OpportunityDataWrapper wrapper = new OpportunityDataWrapper();
        wrapper.recordId = recordId;
        
        try {
            wrapper.unfilledMandatoryFields = getUnfilledMandatoryFields(objectName, fieldSetName, recordId);
            wrapper.allFieldsFilled = wrapper.unfilledMandatoryFields.isEmpty();
        } catch (Exception e) {
            System.debug('Error in getMandatoryFields: ' + e.getMessage());
            wrapper.unfilledMandatoryFields = new List<String>();
            wrapper.allFieldsFilled = false;
        }
        
        return wrapper;
    }
}