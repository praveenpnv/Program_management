/**
* @File Name         : OpportunityLineItemTableController.cls
* @Description        : Controller to build a nested structure of OpportunityLineItems and their related Jobs.
* @Author             : Milan Prasad
* @Last Modified By   : Rizwan Ahmed
* @Last Modified On   : Jul 14, 2025
* @Modification Log   :
*===============================================================================
* Ver   | Date        | Author         | Modification
*===============================================================================
* 1.0   | May 26, 2025| Milan Prasad   | Initial Version
* 2.0   | Jul 14, 2025| Rizwan Ahmed   | Converted datatable to tree structure showing Opportunity Line Items with related Jobs, including URL links and job count.
*/

public with sharing class OpportunityLineItemTableController {

    @AuraEnabled
    public static List<Map<String, Object>> getLineItems(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('OpportunityId cannot be null.');
        }

        // --- Step 1: Build dynamic query using field set for OpportunityLineItem ---
        String oliFieldSet = 'LineItemDataTable_Field'; // Name of the field set
        List<String> oliFields = getFieldSetFields('OpportunityLineItem', oliFieldSet);
        String oliQuery = 'SELECT Id';
        for (String field : oliFields) {
            oliQuery += ', ' + field;
        }
        oliQuery += ' FROM OpportunityLineItem WHERE OpportunityId = :opportunityId';
        List<OpportunityLineItem> lineItems = Database.query(oliQuery);

        Set<Id> oliIds = new Set<Id>();
        for (OpportunityLineItem oli : lineItems) {
            oliIds.add(oli.Id);
        }

        // --- Step 2: Get Jobs related to OpportunityLineItem ---
        List<TR1__Job__c> allJobs = [
            SELECT Id, Name, OpportunityLineItem__c, TR1__Status__c, Job_Type__c
            FROM TR1__Job__c
            WHERE OpportunityLineItem__c IN :oliIds
        ];

        // --- Step 3: Get job count per OpportunityLineItem ---
        Map<Id, Integer> jobCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OpportunityLineItem__c, COUNT(Id) jobCount
            FROM TR1__Job__c
            WHERE OpportunityLineItem__c IN :oliIds
            GROUP BY OpportunityLineItem__c
        ]) {
            jobCountMap.put((Id) ar.get('OpportunityLineItem__c'), (Integer) ar.get('jobCount'));
        }

        // --- Step 4: Group jobs by OpportunityLineItem__c ---
        Map<Id, List<TR1__Job__c>> jobsByLineItem = new Map<Id, List<TR1__Job__c>>();
        for (TR1__Job__c job : allJobs) {
            if (!jobsByLineItem.containsKey(job.OpportunityLineItem__c)) {
                jobsByLineItem.put(job.OpportunityLineItem__c, new List<TR1__Job__c>());
            }
            jobsByLineItem.get(job.OpportunityLineItem__c).add(job);
        }

        // --- Step 5: Build nested tree structure ---
        List<Map<String, Object>> treeGridData = new List<Map<String, Object>>();
        for (OpportunityLineItem oli : lineItems) {
            Map<String, Object> oliRow = new Map<String, Object>();
            oliRow.put('name', oli.Id);
            oliRow.put('LineItem_Name__c', oli.Name);
            oliRow.put('LineItem_Url__c', '/' + oli.Id);
            for (String field : oliFields) {
                oliRow.put(field, oli.get(field));
            }
            oliRow.put('Job_Count__c', jobCountMap.containsKey(oli.Id) ? jobCountMap.get(oli.Id) : 0);

            List<Map<String, Object>> jobChildren = new List<Map<String, Object>>();
            if (jobsByLineItem.containsKey(oli.Id)) {
                for (TR1__Job__c job : jobsByLineItem.get(oli.Id)) {
                    Map<String, Object> jobRow = new Map<String, Object>();
                    jobRow.put('name', job.Id);
                    jobRow.put('Job_Name__c', job.Name);
                    jobRow.put('Job_Url__c', '/' + job.Id);
                    jobRow.put('Job_Status__c', job.TR1__Status__c);
                    jobRow.put('Job_Type__c', job.Job_Type__c);
                    jobChildren.add(jobRow);
                }
            }

            if (!jobChildren.isEmpty()) {
                oliRow.put('_children', jobChildren);
            }

            treeGridData.add(oliRow);
        }

        return treeGridData;
    }

    /**
     * Utility to fetch field API names from a field set
     */
    private static List<String> getFieldSetFields(String objectName, String fieldSetName) {
        List<String> fields = new List<String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        Schema.FieldSet fieldSet = objDescribe.fieldSets.getMap().get(fieldSetName);

        for (Schema.FieldSetMember f : fieldSet.getFields()) {
            if (fieldMap.containsKey(f.getFieldPath())) {
                fields.add(f.getFieldPath());
            }
        }

        return fields;
    }
}