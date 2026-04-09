@IsTest(isParallel = false)
public class FieldSetUtilityTest {

    @TestSetup
    static void setupTestData() {

        User testUser = RD1TestDataFactory.createUser('setUser', 'test', 'US');

 System.runAs(testUser) {

            // Create test Account
            Account testAccount = new Account(
                Name = 'Test Account1',
                AUSY_Changepoint_ID__c = 'CHPID525',
                BillingStreet = 'Test Street',
                BillingCity = 'Bangalore',
                BillingCountry = 'India',
                BillingState = 'Karnataka',
                BillingPostalCode = '12345',
                BH_VAT_Number__c = '29GGGGG1314R9Z9'
            );
            insert testAccount;
            system.debug('testAccount: ' + testAccount);

            // Create test Contact
            Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                RecordTypeId = '0127S000000Tmi2QAC',
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607'
            );
            insert testPerson;
            system.debug('testPerson: ' + testPerson);

            // Create TalentRoverProperties record
            TR1__TalentRoverProperties__c trp = new TR1__TalentRoverProperties__c(
                TR1__Enable_New_ATS_Data_model__c = true
            );
            insert trp;

            // Create test Job
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Test Job',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                Job_Type__c='contract',
               RecordTypeId = '0127S000000Tmi4QAC'
            );
            insert testJob;
            system.debug('testJob: ' + testJob);

            // Create test Application
            TR1__Application_V2__c application = new TR1__Application_V2__c(
                TR1__Stage__c = 'Closing Report',
                TR1__Applicant__c = testPerson.Id,
                TR1__Job__c = testJob.Id,
                RecordTypeId = '0127S000000TmiHQAS'
            );
            insert application;
            system.debug('application: ' + application);
            //RD1TestDataFactory.setupAll();
     		RD1TestDataFactory.createCleanOpportunity();
        }
    }

    @IsTest
    static void testGetApplicantData() {
        User testUser1 = RD1TestDataFactory.createUser('username1', 'test1', 'US');
 System.runAs(testUser1) {
            Test.startTest();
            // Query the test Application record
            List<TR1__Application_V2__c> appRecords = [SELECT Id FROM TR1__Application_V2__c LIMIT 1];
            
            // Ensure the list is not empty before accessing the first element
            System.assert(!appRecords.isEmpty(), 'The application record list should not be empty.');

            // Mock data to call the method
            String applicationId = appRecords[0].Id;
            String objectName = 'Contact';
            String fieldSetName = 'Mandatory_Interview_Fields'; // Change this to a valid field set name
            
            // Call the method
            FieldSetUtility.ApplicantDataWrapper result = FieldSetUtility.getApplicantData(applicationId, objectName, fieldSetName);
            System.debug('result: ' + result);
            Test.stopTest();
            
            // Assert that results are not null
            System.assertNotEquals(null, result, 'The result should not be null.');
            System.assertNotEquals(null, result.applicantId, 'The applicant ID should not be null.');
            System.assertNotEquals(null, result.unfilledMandatoryFields, 'The unfilled mandatory fields list should not be null.');
        }
    }
    @IsTest
    static void testGetOpportunityMandatoryFields() {
        // Generate a unique username
        String uniqueUsername888 = 'testuser888' + DateTime.now().getTime() + '@example.com';        
        // Create a test user
        Profile p888 = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser888 = new User(
             ProfileId = p888.Id,
            Username = uniqueUsername888,
            Email = 'testuser888@example.com',
            LastName = 'User',
            Alias = 'aduser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true
        );
       INSERT testUser888;
       System.runAs(testUser888) {
            Test.startTest();
            // Query a test record (using Opportunity as it's likely available from setup)
            List<Opportunity> opportunityRecords = [SELECT Id FROM Opportunity LIMIT 1];
            
            // Ensure the list is not empty before accessing the first element
            System.assert(!opportunityRecords.isEmpty(), 'The opportunity records list should not be empty.');

            // Mock data to call the method
            String recordId = opportunityRecords[0].Id;
            String objectName = 'Opportunity';
            String fieldSetName = 'Mandatory_Opp_Fields'; 
            
            // Call the method
            FieldSetUtility.OpportunityDataWrapper result = FieldSetUtility.getOpportunityMandatoryFields(recordId, objectName, fieldSetName);
            System.debug('result: ' + result);
            Test.stopTest();
            
            // Assert that results are not null
            System.assertNotEquals(null, result, 'The result should not be null.');
            System.assertNotEquals(null, result.recordId, 'The record ID should not be null.');
            System.assertNotEquals(null, result.unfilledMandatoryFields, 'The unfilled mandatory fields list should not be null.');
            System.assertEquals(recordId, result.recordId, 'The record ID should match the input.');
        }
    }
}