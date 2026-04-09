/**
 * @File Name: CheckJobFieldChangesTest.cls
 * @Description: Unit tests for CheckJobFieldChanges
 * @Author: Priyanka Singh
 * @Created On: Jul 30, 2025
 * @Modified On: Jul 30, 2025
 */
@isTest
private class CheckJobFieldChangesTest {
    
    @TestSetup
    static void setupTestData() {
        User testUser =  RD1TestDataFactory.createUser('JobUser','Test','US'); insert testUser;
        System.runAs(testUser) {
            TR1__Job__c Job = RD1TestDataFactory.buildJob(); insert Job;
        }
    }
    
    @isTest
    static void testFieldChangeDetected() {
        try {
            User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
            System.runAs(testUser) {
                TR1__Job__c job = [SELECT Id, Name FROM TR1__Job__c LIMIT 1];
                job.Published_Title__c = 'Java Developer';
                job.Published_Summary__c = 'Old Summary';
                update job;
                TR1__Job__c priorJob = [SELECT Id, Published_Title__c, Published_Summary__c FROM TR1__Job__c WHERE Id = :job.Id];
                
                job.Published_Title__c = 'SF Developer'; //changing a tracked field
                update job;      
                CheckJobFieldChanges.Request req = new CheckJobFieldChanges.Request();
                req.recordId = job.Id;
                req.priorRecord = priorJob;
                
                Test.startTest();
                List<CheckJobFieldChanges.Response> results = CheckJobFieldChanges.checkChanges(new List<CheckJobFieldChanges.Request>{req});
                Test.stopTest();
                
                System.assertEquals(1, results.size(), 'Should return one result.');
                }}catch (Exception e) {
                System.assert(false, 'An unexpected exception occurred: ' + e.getMessage());
            }
    }
    
    @isTest
    static void testNoFieldChangeDetected() {
        try {
            User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
            System.runAs(testUser) {
                TR1__Job__c job = [SELECT Id, Name FROM TR1__Job__c LIMIT 1];
                TR1__Job__c priorJob = [
                    SELECT Id, Published_Title__c, TR1__Job_Number__c, Open_Closed__c, TR1__Status__c, Remote_Work_Allowed__c,Published_Summary__c
                    FROM TR1__Job__c 
                    WHERE Id = :job.Id
                ];               
                job.Job_priority__c = 'P1'; //Update a non-tracked field
                update job;
                CheckJobFieldChanges.Request req = new CheckJobFieldChanges.Request();
                req.recordId = job.Id;
                req.priorRecord = priorJob;                
               
                Test.startTest();
                List<CheckJobFieldChanges.Response> results = CheckJobFieldChanges.checkChanges(new List<CheckJobFieldChanges.Request>{req});
                Test.stopTest();
                
                System.assertEquals(false, results[0].hasChanges, 'Should not detect changes for untracked fields.');                
            }}catch (Exception e) {
                System.assert(false, 'An unexpected exception occurred: ' + e.getMessage());
            }
    }
    
    @isTest
    static void testInvalidOrEmptyFieldSet() {        
        try {
            User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
            System.runAs(testUser) {
                TR1__Job__c job = [SELECT Id, Name FROM TR1__Job__c LIMIT 1];
                TR1__Job__c priorJob = job.clone();
                job.Published_Title__c = 'Project Manager';
                update job;                
                CheckJobFieldChanges.Request req = new CheckJobFieldChanges.Request();
                req.recordId = job.Id;
                req.priorRecord = priorJob;
                req.fieldSetName = 'Non_Existent_Field_Set';
                
                Test.startTest();
                List<CheckJobFieldChanges.Response> results = CheckJobFieldChanges.checkChanges(new List<CheckJobFieldChanges.Request>{req});
                Test.stopTest();
                
                System.assertEquals(false, results[0].hasChanges, 'Should return false when field set is not found.');
            }}catch (Exception e) {
                System.assert(false, 'An unexpected exception occurred: ' + e.getMessage());
            }
    }
    
    @isTest
    static void testNullAndEmptyInputs() {
        List<CheckJobFieldChanges.Response> nullResults = CheckJobFieldChanges.checkChanges(null);
        System.assertEquals(false, nullResults[0].hasChanges, 'Should handle null input.');
        
        List<CheckJobFieldChanges.Response> emptyResults = CheckJobFieldChanges.checkChanges(new List<CheckJobFieldChanges.Request>());
        System.assertEquals(false, emptyResults[0].hasChanges, 'Should handle an empty list.');
        
        CheckJobFieldChanges.Request req = new CheckJobFieldChanges.Request();
        req.recordId = 'a00000000000001AAA'; // Dummy Id
        req.priorRecord = null; // Set prior record to null
        List<CheckJobFieldChanges.Response> nullPriorRecordResults = CheckJobFieldChanges.checkChanges(new List<CheckJobFieldChanges.Request>{req});
        System.assertEquals(false, nullPriorRecordResults[0].hasChanges, 'Should handle a null priorRecord.');
    }
}