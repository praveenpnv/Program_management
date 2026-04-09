public with sharing class PortalActionController {

    public class SaveResult {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public Id jobId;

        public SaveResult(Id contactId, String status, String message, Id jobId) {
            this.contactId = contactId;
            this.status = status;
            this.message = message;
            this.jobId = jobId;
        }
    }

    @AuraEnabled
    public static List<SaveResult> saveApplications(List<Id> contactIds, List<Id> jobIds) {
        return saveRecords(contactIds, jobIds, 'Application');
    }

    @AuraEnabled
    public static List<SaveResult> saveLonglistRecords(List<Id> contactIds, List<Id> jobIds) {
        return saveRecords(contactIds, jobIds, 'Longlist');
    }

    private static List<SaveResult> saveRecords(List<Id> contactIds, List<Id> jobIds, String action) {
        System.debug('Action: ' + action);
        System.debug('Received contactIds: ' + contactIds);
        System.debug('Received jobIds: ' + jobIds);

        if (contactIds.isEmpty() || jobIds.isEmpty()) {
            throw new AuraHandledException('Invalid data provided. Contact IDs or Job IDs are missing.');
        }

        List<SObject> records = new List<SObject>();
        List<SaveResult> results = new List<SaveResult>();

        if (action == 'Application') {
            Map<Id, String> jobRecordTypeMap = getJobRecordTypes(jobIds);
            Map<String, Id> appRecordTypeMap = getApplicationRecordTypes(jobRecordTypeMap.values());

            for (Id contactId : contactIds) {
                for (Id jobId : jobIds) {
                    Id appRecordTypeId = jobRecordTypeMap.containsKey(jobId) ? appRecordTypeMap.get(jobRecordTypeMap.get(jobId)) : null;
                    if (appRecordTypeId == null) {
                        results.add(new SaveResult(contactId, 'Error', 'No matching application record type found.', jobId));
                        continue;
                    }

                    records.add(new TR1__Application_V2__c(
                        TR1__Applicant__c = contactId,
                        TR1__Job__c = jobId,
                        TR1__Stage__c = 'Application',
                        RecordTypeId = appRecordTypeId
                    ));
                }
            }
        } 
        else if (action == 'Longlist') {
            for (Id contactId : contactIds) {
                for (Id jobId : jobIds) {
                    records.add(new TR1__Opportunity_Discussed__c(
                        TR1__Candidate__c	 = contactId,
                        TR1__Job__c = jobId
                    ));
                }
            }
        } 
        else {
            throw new AuraHandledException('Invalid action: ' + action);
        }

        return insertRecords(records, results,action);
    }

    private static Map<Id, String> getJobRecordTypes(List<Id> jobIds) {
        Map<Id, String> jobRecordTypeMap = new Map<Id, String>();
        for (TR1__Job__c job : [SELECT Id, RecordType.DeveloperName FROM TR1__Job__c WHERE Id IN :jobIds]) {
            jobRecordTypeMap.put(job.Id, job.RecordType.DeveloperName);
        }
        return jobRecordTypeMap;
    }

    private static Map<String, Id> getApplicationRecordTypes(List<String> jobRecordTypes) {
        Map<String, Id> appRecordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'TR1__Application_V2__c' AND DeveloperName IN :jobRecordTypes]) {
            appRecordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        return appRecordTypeMap;
    }

    private static List<SaveResult> insertRecords(List<SObject> records, List<SaveResult> results,string action) {
        if (records.isEmpty()) return results;

        try {
            Database.SaveResult[] saveResults = Database.insert(records, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                SObject record = records[i];
                Id contactId = action=='Longlist'?(Id) record.get('TR1__Candidate__c'):(Id) record.get('TR1__Applicant__c');
                Id jobId = (Id) record.get('TR1__Job__c');

                if (saveResults[i].isSuccess()) {
                    results.add(new SaveResult(contactId, 'Success', 'Record inserted successfully.', jobId));
                } else {
                    // Corrected error handling
                List<String> errorMessages = new List<String>();
                for (Database.Error err : saveResults[i].getErrors()) {
                    errorMessages.add(err.getMessage());
                }
                String errorMessage = String.join(errorMessages, ' ');

                results.add(new SaveResult(contactId, 'Error', errorMessage, jobId));
                }
            }
        } catch (DmlException e) {
            for (SObject record : records) {
                results.add(new SaveResult((Id) record.get('TR1__Applicant__c'), 'Error', 'DML Exception: ' + e.getMessage(), (Id) record.get('TR1__Job__c')));
            }
        }

        return results;
    }
}