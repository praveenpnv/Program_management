@isTest(isParallel = false)
public class EmailsenderNotifyADPTest {

    @testSetup 
    static void setupTestData() {
        // Generate a unique username
        String uniqueUsername = 'testuser' + DateTime.now().getTime() + '@example.com';
        // Create a system admin user
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser67 = new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = 'TestAdmin',
            Email = 'adminuser@example.com',
            Username = uniqueUsername,
            Alias = 'aduser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Opco__c = 'India',
            Bypass_VR__c = true
        );
        insert adminUser67;

        // Run all test setup data creation in the context of the admin user
        System.runAs(adminUser67) {
            // Create test Account
            Account testAccount = new Account(
                Name = 'Test Account45',
                AUSY_Changepoint_ID__c = 'CHPID525',
                BillingStreet = 'Test Street',
                BillingCity = 'Bangalore',
                BillingCountry = 'India',
                BillingState = 'Karnataka',
                BillingPostalCode = '12345',
                BH_VAT_Number__c = '29GGGGG1314R9Z9'
            );
            insert testAccount;
            //System.debug('testAccount: ' + testAccount);

            // Create test Contact
            Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                RecordTypeId = '0127S000000Tmi2QAC',
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607'
            );
            insert testPerson;
            //System.debug('testPerson: ' + testPerson);

            // Create TalentRoverProperties record
            TR1__TalentRoverProperties__c trp = new TR1__TalentRoverProperties__c(
                TR1__Enable_New_ATS_Data_model__c = true
            );
            insert trp;

            // Create test Job
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Test Job',
                Business_unit__c = 'Common set',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                RecordTypeId = '0127S000000Tmi4QAC'
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
           // System.debug('application: ' + application);

            // Create test Closing Report
            TR1__Closing_Report__c testClosingReport = new TR1__Closing_Report__c(
                TR1__Person_Placed__c = testPerson.Id,
                TR1__Account__c = testAccount.Id,
                TR1__Job__c = testJob.Id,
                Assignment_Type__c = 'T&M',
                Business_unit__c = 'Common set',
                TR1__Start_Date__c = Date.today().addDays(-30),
                Billing_Entity__c = 'RSD Belgium',
                TR1__Other_Percentage__c = 100,
                RecordTypeId = '0127S000000TmiUQAS'
            );
            insert testClosingReport;
           // System.debug('testClosingReport: ' + testClosingReport);
        }
    }

    @isTest   
    static void testSendEmail() {
        // Generate a unique username
        String uniqueUsername567 = 'testuser' + DateTime.now().getTime() + '@example.com';        
        // Create a system admin user to run the test as admin
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser98 = new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = 'TestAdmin',
            Email = 'adminuser@example.com',
            Username = uniqueUsername567,
            Alias = 'aduser2',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true
        );
        insert adminUser98;

        // Run the test method in the admin context
        System.runAs(adminUser98) {
            // Retrieve the test data
            TR1__Closing_Report__c testClosingReport = [SELECT Id FROM TR1__Closing_Report__c WHERE Assignment_Type__c = 'T&M' LIMIT 1];
            System.debug('testClosingReport: ' + testClosingReport);
            List<Id> closingReportIds = new List<Id>{testClosingReport.Id};

            // Call the method
            Test.startTest();
            EmailsenderNotifyADP.sendEmail(closingReportIds);
            Test.stopTest();

            System.assert(true, 'Method executed without errors');
        }
    }
}