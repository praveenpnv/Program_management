/**
 * @File Name: CheckJobFieldChangesTest.cls
 * @Description: Unit tests for CheckJobFieldChanges
 * @Author: Priyanka Singh
 * @Created On: Jul 30, 2025
 * @Modified On: Jul 30, 2025
 */
public with sharing class CheckJobFieldChanges {

    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
        @InvocableVariable(required=true)
        public SObject priorRecord;
        @InvocableVariable
        public String fieldSetName = 'Logic_Melon_Flow_Field_Set';
    }

    public class Response {
        @InvocableVariable
        public Boolean hasChanges;
        @InvocableVariable
        public String changedFields;
    }

    @InvocableMethod(label='Check Job Field Changes' description='Checks if tracked fields in a Job record have changed using a Field Set')
    public static List<Response> checkChanges(List<Request> input) {
        List<Response> results = new List<Response>();
        Response res = new Response();
        if (input == null || input.isEmpty() || input[0].priorRecord == null) {
            res.hasChanges = false;
            results.add(res);
            return results;
        }

        Request req = input[0];
        Id jobId = req.recordId;
        SObject priorRecord = req.priorRecord;
        String fieldSetName = String.isNotBlank(req.fieldSetName) ? req.fieldSetName : 'Logic_Melon_Flow_Field_Set';
        try {
            Set<String> trackedFields = getFieldSetFields('TR1__Job__c', fieldSetName);
            if (trackedFields.isEmpty()) {
                res.hasChanges = false;
                results.add(res);
                return results;
            }
            
            String soqlQuery = 'SELECT ' + String.join(new List<String>(trackedFields), ', ') +
                             ' FROM TR1__Job__c WHERE Id = :jobId LIMIT 1';            
            TR1__Job__c currentRecord = (TR1__Job__c) Database.query(soqlQuery);
            Boolean hasAnyChanges = false;
            List<String> changedFieldsList = new List<String>();
            for (String fieldName : trackedFields) {
                if (!valuesAreEqual(currentRecord.get(fieldName), priorRecord.get(fieldName))) {
                    hasAnyChanges = true;
                    changedFieldsList.add(fieldName);                    
                    System.debug('*** CHANGE DETECTED ***');
                }
            }           
            res.hasChanges = hasAnyChanges;
            res.changedFields = String.join(changedFieldsList, ',');
            results.add(res);
        } catch (Exception e) {
            res.hasChanges = false;
            res.changedFields = 'Error: ' + e.getMessage();
            results.add(res);
        }
        return results;
    }

    //Get field API names from a field set
    private static Set<String> getFieldSetFields(String objectName, String fieldSetName) {
        Set<String> fieldNames = new Set<String>();
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType != null) {
                Schema.FieldSet fieldSet = objectType.getDescribe().fieldSets.getMap().get(fieldSetName);
                if (fieldSet != null) {
                    for (Schema.FieldSetMember field : fieldSet.getFields()) {
                        fieldNames.add(field.getFieldPath());
                    }
                }
            }
        } catch (Exception e) {
            // Fails silently and returns an empty set
        }
        return fieldNames;
    }

    //Compare two values handling nulls
    private static Boolean valuesAreEqual(Object value1, Object value2) {
        if (value1 == null && value2 == null) {
            return true;
        }
        if (value1 == null || value2 == null) {
            return false;
        }
        return String.valueOf(value1).equals(String.valueOf(value2));
    }
}