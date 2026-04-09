@isTest(isParallel = false)
public class TetrisClosingReportSyncTest {

    @testSetup
    static void setupTestData() {
           // Generate a unique username
        String uniqueUsername55 = 'testuser55' + DateTime.now().getTime() + '@example.com';        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser46 = new User(
            Username = uniqueUsername55,
            Email = 'testuser55@example.com',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Opco__c = 'Belux'
        );
        insert testUser46;
 System.runAs(testUser46) {
            // Create test Account
            Account testAccount = new Account(
                Name = 'Test Account11',
                AUSY_Changepoint_ID__c = 'CHPID525',
                BillingStreet = 'Test Street',
                BillingCity = 'Bangalore',
                BillingCountry = 'India',
                BillingState = 'Karnataka',
                BillingPostalCode = '12345',
                BH_VAT_Number__c = '29GGGGG1314R9Z9'
            );
            insert testAccount;
            System.debug('testAccount: ' + testAccount);

            // Create test Contact
            Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Unit__c = '5201 Delivery IT operations',
                RecordTypeId = '0127S000000Tmi2QAC',
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607'
            );
            insert testPerson;
            System.debug('testPerson: ' + testPerson);

            // Create TalentRoverProperties record
            TR1__TalentRoverProperties__c trp = new TR1__TalentRoverProperties__c(
                TR1__Enable_New_ATS_Data_model__c = true
            );
            insert trp;

            // Create test Job
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Test Job',
                Business_unit__c = '5201 Delivery IT operations',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                RecordTypeId = '0127S000000Tmi4QAC',
                Job_Type__c='contract'
            );
            insert testJob;
            System.debug('testJob: ' + testJob);

            // Create test Application
            TR1__Application_V2__c application = new TR1__Application_V2__c(
                TR1__Stage__c = 'Closing Report',
                TR1__Applicant__c = testPerson.Id,
                TR1__Job__c = testJob.Id,
                RecordTypeId = '0127S000000TmiHQAS'
            );
            insert application;
            System.debug('application: ' + application);

            // Create test Closing Report
            TR1__Closing_Report__c testClosingReport = new TR1__Closing_Report__c(
                TR1__Person_Placed__c = testPerson.Id,
                TR1__Account__c = testAccount.Id,
                TR1__Job__c = testJob.Id,
                Assignment_Type__c = 'T&M',
                Business_unit__c = '5201 Delivery IT operations',
                TR1__Start_Date__c = Date.today().addDays(-30),
                Billing_Entity__c = 'RSD Belgium',
                TR1__Other_Percentage__c = 100,                
                RecordTypeId = '0127S000000TmiUQAS'
            );
            insert testClosingReport;
            System.debug('testClosingReport: ' + testClosingReport);
        }
    }

    @isTest
    static void testSyncClosingReport() {
              // Generate a unique username
        String uniqueUsername56 = 'testuser56' + DateTime.now().getTime() + '@example.com';        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser65 = new User(
            Username = uniqueUsername56,
            Email = 'testuser56@example.com',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
       insert testUser65;
 System.runAs(testUser65) {
            // Retrieve the inserted Closing Report
            TR1__Closing_Report__c testClosingReport = [SELECT Id FROM TR1__Closing_Report__c LIMIT 1];
            System.debug('testClosingReport: ' + testClosingReport);

            // Create a list of report IDs to pass to the method
            List<Id> reportIds = new List<Id>{testClosingReport.Id};

            Test.startTest();

            // Mock the Queueable class to prevent real external callouts
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            // Call the Invocable method
            List<ID> jobIDs = TetrisClosingReportSync.syncClosingReport(reportIds);

            Test.stopTest();

            // Assert that the job was successfully enqueued
            //System.assertNotEquals(0, jobIDs.size(), 'Job ID list should not be empty');
        }
    }

    // Mock class to simulate HTTP callout response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}