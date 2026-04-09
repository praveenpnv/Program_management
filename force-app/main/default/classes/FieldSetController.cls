public with sharing class FieldSetController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getFieldSetFields(String objectName, String fieldSetName) {
        List<Map<String, Object>> fieldNames = new List<Map<String, Object>>();

        // Describe the object dynamically
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjectType = gd.get(objectName);
        if (sobjectType == null) {
            return fieldNames; // Handle gracefully
        }

        Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();

        // Retrieve the FieldSet details
        Schema.FieldSet fieldSet = describeResult.FieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) {
            return fieldNames; // Handle gracefully
        }

        // Iterate through fields in the FieldSet
        for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
            Map<String, Object> fieldInfo = new Map<String, Object>();

            // Get describe for each field to check requiredness
            Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fsm.getFieldPath()).getDescribe();
            Boolean isRequired = fsm.getRequired();

            // Put values in map
            fieldInfo.put('fieldPath', fsm.getFieldPath());
            fieldInfo.put('required', isRequired);

            fieldNames.add(fieldInfo);
        }

        return fieldNames;
    }
}