public with sharing class TaskController {
    @AuraEnabled
    public static Task getTasksByCriteria(Id applicationId, String subject, String recordTypeName) {
        if (applicationId == null) {
            throw new AuraHandledException('Application ID cannot be null');
        }

        // Fetch record type ID based on the record type developer name
        Id recordTypeId;
        try {
            recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving record type ID: ' + e.getMessage());
        }

        // Construct the SOQL query with dynamic conditions
        String query = 'SELECT Id, Description, Subject, Status, Priority, WhatId FROM Task WHERE TR1__Application_V2__c = :applicationId';
        
        if (subject != null && subject != '') {
            query += ' AND Subject = :subject';
        }
        if (recordTypeId != null) {
            query += ' AND RecordTypeId = :recordTypeId';
        }

        // Execute the query
        List<Task> tasks = Database.query(query + ' LIMIT 1');
        return tasks.isEmpty() ? null : tasks[0];
    }

    @AuraEnabled
    public static void upsertTaskDescription(Id taskId, String description, Id applicationId, String subject, String recordTypeName) {
        Task task;
        if (taskId != null) {
            try {
                task = [SELECT Id, Description FROM Task WHERE Id = :taskId LIMIT 1];
            } catch (Exception e) {
                throw new AuraHandledException('Error retrieving task: ' + e.getMessage());
            }
        } else {
            task = new Task();
        }

        task.Description = description;
        if (applicationId != null) {
            task.put('TR1__Application_V2__c', applicationId);
        }
        if (subject != null && subject != '') {
            task.Subject = subject;
        }
        if (recordTypeName != null && recordTypeName != '') {
            try {
                task.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
            } catch (Exception e) {
                throw new AuraHandledException('Error retrieving record type ID: ' + e.getMessage());
            }
        }

        try {
            upsert task;
        } catch (Exception e) {
            throw new AuraHandledException('Error upserting task description: ' + e.getMessage());
        }
    }
}