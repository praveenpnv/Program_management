@isTest(isParallel = false)
private class EngagementPrefillHandlerTest {

    @testSetup
    static void setupTestData() {
        String uniqueUsername = 'testuser' + DateTime.now().getTime() + '@example.com';        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];

        User testUser = new User(
            Username = uniqueUsername,
            Email = 'testuser@example.com',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Opco__c = 'Belux'
        );
        insert testUser;

        System.runAs(testUser) {
            Account testAccount = new Account(
                Name = 'Test Account',
                AUSY_Changepoint_ID__c = 'CHPID999',
                BillingStreet = 'RT Nagar',
                BillingCity = 'Bangalore',
                BillingCountry = 'India',
                BillingState = 'Karnataka',
                BillingPostalCode = '12345',
                BH_VAT_Number__c = '29GGGGG1314R9Z9'
            );
            insert testAccount;

            Contact testContact = new Contact(
                FirstName = 'Jane',
                LastName = 'Doe',
                Unit__c = '5201 Delivery IT operations',
                RecordTypeId = '0127S000000Tmi2QAC',
                Email = 'jane.doe@example.com',
                Mpleo_Id__c = '1001234',
                Sourcer_Secondary_Recruiter__c=testUser.Id
            );
            insert testContact;

            insert new TR1__TalentRoverProperties__c(TR1__Enable_New_ATS_Data_model__c = true);

            RecordType jobRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TR1__Job__c' AND DeveloperName = 'Consulting' LIMIT 1];

            TR1__Job__c job = new TR1__Job__c(
                Name = 'Test Job',
                Business_unit__c = '5201 Delivery IT operations',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                Line_of_Business__c = 'CR',
                RecordTypeId = jobRT.Id,
                Job_Type__c = 'Contract'
            );
            insert job;

            TR1__Application_V2__c application = new TR1__Application_V2__c(
                TR1__Stage__c = 'Closing Report',
                TR1__Applicant__c = testContact.Id,
                TR1__Job__c = job.Id,
                CreatedById = testUser.Id,
                RecordTypeId = '0127S000000TmiHQAS'
            );
            insert application;

            // Simulate Custom Metadata records (no DML here, just mocks)
            simulateMetadataRecords();
        }
    }

    @isTest
    static void testGetClosingReportPrefillMaps() {
        TR1__Application_V2__c application = [SELECT Id FROM TR1__Application_V2__c LIMIT 1];

        // Proceed with the actual test after simulating metadata
        Test.startTest();
        List<Map<String, String>> result = EngagementPrefillHandler.getClosingReportPrefillMaps(application.Id);
        Test.stopTest();

        // Asserts to check the results
        System.assertNotEquals(null, result);
        System.assert(result.size() > 0, 'Expected at least one mapping entry to be returned.');
        
        Boolean hasRecordType = false;
        for (Map<String, String> entry : result) {
            if (entry.get('closingField') == 'RecordTypeId') {
                hasRecordType = true;
                break;
            }
        }
        System.assert(hasRecordType, 'RecordTypeId mapping must be included.');
    }

    // Helper method to simulate the presence of Custom Metadata Records for testing
private static void simulateMetadataRecords() {
    // Mock the Custom Metadata behavior by creating mock data
    // You can assume these mappings are already present in your test environment
    System.debug('Simulating Custom Metadata Records...');
    
    // Example of mocked metadata records:
    List<TR1__Closing_Report_Mapping__mdt> mockMetadataRecords = new List<TR1__Closing_Report_Mapping__mdt>{
        new TR1__Closing_Report_Mapping__mdt(
            DeveloperName = 'TR1__Candidate_Credit__c_12345',
            MasterLabel = 'TR1__Candidate_Credit__c',
            TR1__Closing_Report_Field__c = 'TR1__Candidate_Credit__c',
            TR1__Job_Field__c = 'CreatedById',
            TR1__Application_V2_Field__c = 'CreatedById',
            TR1__Default_Value__c = null
        ),
        new TR1__Closing_Report_Mapping__mdt(
            DeveloperName = 'TR1__Marketing_Credit__c_12345',
            MasterLabel = 'TR1__Marketing_Credit__c',
            TR1__Closing_Report_Field__c = 'TR1__Marketing_Credit__c',
            TR1__Job_Field__c = 'CreatedById',
            TR1__Application_V2_Field__c = null,
            TR1__Default_Value__c = null
        )
    };

    // Simulate a scenario where these metadata records exist in the system
    // These records are not actually created, but we are assuming they exist during testing
    // You can mock the response for methods that retrieve this data, such as in your handler class.

    // For example, in your handler class, you might have a method that queries these records,
    // and you can mock that response here instead of querying the real database.

    // You would then assert that the handler behaves correctly as if these records were real.
}

}