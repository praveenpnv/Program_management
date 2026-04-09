@IsTest
private class JobAdGeneratorControllerTest {

    /**
     * Mock Class to simulate HTTP Responses
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            res.setStatus(statusCode == 200 ? 'OK' : 'Error');
            return res;
        }
    }

    /**
     * Setup test data specifically for Custom Settings and Job Records
     */
    @TestSetup
    static void makeData() {
        //Create Custom Settings (Required for getApiKeyFromSettings & getEndpointPath)
        JobAdGeneratorSettings__c settings = new JobAdGeneratorSettings__c();
        settings.Api_Key__c = 'TEST_API_KEY_123';
        settings.Endpoint_Path__c = '/v1/generate';
        insert settings;

        //Create a dummy TR1__Job__c record
      Account testAccount = RD1TestDataFactory.createTestAccount();
        Contact client = RD1TestDataFactory.createTestContact(testAccount.Id, 'Client');
        TR1__Job__c testJob = RD1TestDataFactory.createTestJob(testAccount.Id, client.Id);

    }

    /**
     * TEST 1: Happy Path
     * Verifies API callout success and Job record update.
     */
    @IsTest
    static void testGenerateJobAdSuccess() {
        TR1__Job__c job = [SELECT Id FROM TR1__Job__c LIMIT 1];

        Map<String, Object> requestData = new Map<String, Object>{
            'jobRecordId' => job.Id,
            'intake_notes' => 'Looking for a strong Java developer.',
            'language' => 'English',
            'country' => 'USA',
            'brand' => 'TechCorp'
        };

        // Mock a successful JSON response
        String jsonResponse = '{"content": {"job_ad": "This is a generated job ad."}, "status": "success"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, jsonResponse));

        Test.startTest();
        Map<String, Object> result = JobAdGeneratorController.generateJobAdFromJob(requestData);
        Test.stopTest();

        // Assert response map
        System.assertNotEquals(null, result, 'Result map should not be null');
        
        // Assert Database Update
        TR1__Job__c updatedJob = [SELECT Generated_Job_Ad__c FROM TR1__Job__c WHERE Id = :job.Id];
        System.assertEquals('This is a generated job ad.', updatedJob.Generated_Job_Ad__c, 'Job record should be updated with ad text');
    }

    /**
     * TEST 2: API Error Handling
     * Verifies that API errors (400/500) throw an AuraHandledException.
     */
    @IsTest
    static void testGenerateJobAdApiError() {
        TR1__Job__c job = [SELECT Id FROM TR1__Job__c LIMIT 1];
        Map<String, Object> requestData = new Map<String, Object>{ 'jobRecordId' => job.Id };

        // Mock an error response
        String jsonResponse = '{"detail": "Invalid parameters provided"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, jsonResponse));

        Test.startTest();
        try {
            JobAdGeneratorController.generateJobAdFromJob(requestData);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    /**
     * TEST 3: Missing Custom Settings
     * Verifies that missing API Key/Endpoint throws an error.
     */
    @IsTest
    static void testMissingSettings() {
        // Delete settings to simulate missing config
        delete [SELECT Id FROM JobAdGeneratorSettings__c];

        Map<String, Object> requestData = new Map<String, Object>{ 'jobRecordId' => 'dummy' };

        Test.startTest();
        try {
            JobAdGeneratorController.generateJobAdFromJob(requestData);
            System.assert(false, 'Should have thrown exception for missing settings');
        } catch (Exception e) {
            // Verify exception is caught
            System.assert(true); 
        }
        Test.stopTest();
    }

    /**
     * TEST 4: Empty Request
     * Verifies validation for empty request data.
     */
    @IsTest
    static void testEmptyRequest() {
        Test.startTest();
        try {
            JobAdGeneratorController.generateJobAdFromJob(new Map<String, Object>());
            System.assert(false, 'Should have thrown exception for empty request');
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    /**
     * TEST 5: Metadata / Config Retrieval
     * Verifies retrieval of UI fields.
     */
    @IsTest
    static void testGetIncludeFieldsConfig() {
        Test.startTest();
        List<Map<String, Object>> fields = JobAdGeneratorController.getIncludeFieldsConfig();
        Test.stopTest();

        System.assertNotEquals(null, fields, 'Fields list should not be null');
        System.assert(fields.size() > 0, 'Should return fields (either from MDT or defaults)');
        
        Map<String, Object> firstField = fields[0];
        System.assert(firstField.containsKey('label'), 'Field map must contain label');
        System.assert(firstField.containsKey('apiName'), 'Field map must contain apiName');
    }

    /**
     * TEST 6: Update Failure (Soft Fail)
     * Verifies that update failures (e.g., bad ID) are caught and logged without crashing the return.
     */
    @IsTest
    static void testUpdateJobFail() {
        // Use a Fake ID to force an update error
        Map<String, Object> requestData = new Map<String, Object>{
            'jobRecordId' => 'a00000000000000FAKE', 
            'intake_notes' => 'Notes'
        };

        String jsonResponse = '{"content": {"job_ad": "Ad Content"}, "status": "success"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, jsonResponse));

        Test.startTest();
        // Should succeed returning map, even though DB update failed
        Map<String, Object> result = JobAdGeneratorController.generateJobAdFromJob(requestData);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('Ad Content', ((Map<String,Object>)result.get('content')).get('job_ad'));
    }
    @IsTest
static void testGetJobAddress_WithAddress() {
   
    //Create a dummy TR1__Job__c record
      Account testAccount = RD1TestDataFactory.createTestAccount();
        Contact client = RD1TestDataFactory.createTestContact(testAccount.Id, 'Client');
        TR1__Job__c testJob = RD1TestDataFactory.createTestJob(testAccount.Id, client.Id);
 // ✅ Proper compound address population
    testJob.Worksite_Address__City__s        = 'Unison';
    testJob.Worksite_Address__Street__s       = '123 Main St';
    testJob.Worksite_Address__StateCode__s   = 'VA';
    testJob.Worksite_Address__PostalCode__s  = '78701';
  //  testJob.Worksite_Address__Country__s     = 'United States';
    testJob.Worksite_Address__CountryCode__s = 'US';

    update testJob;

    // Act
    Test.startTest();
    Map<String, String> addressMap =
        JobAdGeneratorController.getJobAddress(testJob.Id);
    Test.stopTest();

    // Assert
    System.assertEquals('123 Main St', addressMap.get('street'));
    System.assertEquals('Unison', addressMap.get('city'));
    System.assertEquals('Virginia', addressMap.get('state'));
    System.assertEquals('78701', addressMap.get('postalCode'));
    System.assertEquals('United States', addressMap.get('country'));
}

}