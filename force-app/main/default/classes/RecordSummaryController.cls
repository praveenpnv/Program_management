public with sharing class RecordSummaryController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFilterIdsByPicklistValues(List<String> picklistValues) {
        Map<String, String> filterIdMap = new Map<String, String>();
        if (picklistValues == null || picklistValues.isEmpty()) {
            return filterIdMap;
        }

        List<TR1__Filter__c> filters = [SELECT Id, Name, TR1__Filter_Logic__c 
                                        FROM TR1__Filter__c 
                                        WHERE Name IN :picklistValues
            and TR1__Object_Name__c ='TR1__Application_V2__c' and TR1__Is_Private__c = false];

        for (TR1__Filter__c filter : filters) {
            filterIdMap.put(filter.Name, filter.Id);
        }

        return filterIdMap;

    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getSummaryByPicklistAndField(String sObjectName, String picklistField, String fieldName, String fieldValue) {
        Map<String, Integer> summaryMap = new Map<String, Integer>();

        // Query to get the count of records grouped by the picklist field
        String query = 'SELECT ' + picklistField + ', COUNT(Id) cnt FROM ' + sObjectName +
                       ' WHERE ' + fieldName + ' = :fieldValue GROUP BY ' + picklistField;
        List<AggregateResult> results = Database.query(query);

        for (AggregateResult ar : results) {
            String picklistValue = (String)ar.get(picklistField);
            Integer count = (Integer)ar.get('cnt');
            summaryMap.put(picklistValue, count);
        }

        return summaryMap;
    }

    @AuraEnabled(cacheable=true)
    public static Id getRecordTypeId(String sObjectName, String fieldName, String fieldValue) {
        String query = 'SELECT RecordTypeId FROM ' + sObjectName + ' WHERE ' + fieldName + ' = :fieldValue LIMIT 1';
        List<SObject> results = Database.query(query);
        
        if (!results.isEmpty()) {
            return (Id)results[0].get('RecordTypeId');
        }
        return null;
    }
}