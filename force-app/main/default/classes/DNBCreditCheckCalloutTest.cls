@isTest
public class DNBCreditCheckCalloutTest {
    
    private static final Decimal TEST_DUNS_NUMBER = 123456789;
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test DNB Company', D_U_N_S_Number__c = TEST_DUNS_NUMBER);
        insert testAccount;
        Account testAccountNoDUNS = new Account(Name = 'Test Company Without DUNS');
        insert testAccountNoDUNS;
    }
    
    @isTest
    static void testFetchAndUpdateAccount_Success() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test DNB Company' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new DNBCreditCheckMockHttpResponse(200, getSuccessfulResponseBody(), true));
 
        Test.startTest();
        DNBCreditCheckCallout.fetchAndUpdateAccount(testAccount.Id);
        Test.stopTest();
        
        Account updatedAccount = [
            SELECT Name, Phone, Sic, SicDesc, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   DnB_Failure_Score_Class__c, DnB_Failure_Score_Description__c,
                   DnB_Delinquency_Score_Class__c, DnB_Delinquency_Score_Description__c,
                   DnB_Standard_Rating__c, DnB_Financial_Strength__c, DnB_Risk_Segment__c
            FROM Account WHERE Id = :testAccount.Id
        ];
        
        // Assertions for all fields
        System.assertEquals('Mock Company Name', updatedAccount.Name);
        System.assertEquals('555-555-5555', updatedAccount.Phone);
        System.assertEquals('7372', updatedAccount.Sic);
        System.assertEquals('Prepackaged Software', updatedAccount.SicDesc);
        System.assertEquals('123 Mock St', updatedAccount.BillingStreet);
        System.assertEquals('Mock City', updatedAccount.BillingCity);
        System.assertEquals('94105', updatedAccount.BillingPostalCode);
        System.assertEquals('United States', updatedAccount.BillingCountry);
        System.assertEquals('1', updatedAccount.DnB_Failure_Score_Class__c);
        System.assertEquals('Low risk of financial stress', updatedAccount.DnB_Failure_Score_Description__c);
        System.assertEquals('1A', updatedAccount.DnB_Standard_Rating__c);
        System.assertEquals('Good', updatedAccount.DnB_Financial_Strength__c);
        System.assertEquals('Low', updatedAccount.DnB_Risk_Segment__c);
    }

    @isTest
    static void testPerformAndCheckStatus() {
        Account accWithDuns = [SELECT Id FROM Account WHERE D_U_N_S_Number__c != null LIMIT 1];
        Map<String, Object> resultWithDuns = DNBCreditCheckCallout.performCreditCheck(accWithDuns.Id);
        System.assertEquals(true, resultWithDuns.get('success'));

        Account accWithoutDuns = [SELECT Id, Name FROM Account WHERE D_U_N_S_Number__c = null LIMIT 1];
        Map<String, Object> resultWithoutDuns = DNBCreditCheckCallout.performCreditCheck(accWithoutDuns.Id);
        System.assertEquals(false, resultWithoutDuns.get('directCreditCheck'));
        
        Map<String, Object> statusResult = DNBCreditCheckCallout.checkCreditDataStatus(accWithoutDuns.Id);
        System.assertEquals(false, statusResult.get('hasCreditData'));
    }

    @isTest
    static void testSearchAndUpdate() {
        Account accWithoutDuns = [SELECT Id FROM Account WHERE D_U_N_S_Number__c = null LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new DNBCreditCheckMockHttpResponse(200, 
            '{"searchCandidates": [{"organization": {"duns": "987654321", "primaryName": "Searched Co", "primaryAddress": {"streetAddress": {"line1": "456 Search St"}}}}]}', true));

        Test.startTest();
        List<Map<String, Object>> searchResults = DNBCreditCheckCallout.searchCompaniesByName('Test');
        String updateResult = DNBCreditCheckCallout.updateAccountWithDUNSAndFetchCredit(accWithoutDuns.Id, '987654321');
        Test.stopTest();

        System.assertEquals(1, searchResults.size());
        System.assert(searchResults[0].get('address').toString().contains('456 Search St'), 'Address should be built.');
        System.assert(updateResult.contains('Success'));
        
        Account updatedAccount = [SELECT D_U_N_S_Number__c FROM Account WHERE Id = :accWithoutDuns.Id];
        System.assertEquals(987654321, updatedAccount.D_U_N_S_Number__c);
    }
    @isTest
    static void testExceptionHandling() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new DNBCreditCheckMockHttpResponse(200, 'this is not valid json', true));
        Test.startTest();
        DNBCreditCheckCallout.fetchAndUpdateAccount(testAccount.Id);
        Test.setMock(HttpCalloutMock.class, new DNBCreditCheckMockHttpResponse(500, 'Server Error', true));
        try {
            DNBCreditCheckCallout.searchCompaniesByName('Error Test');
            System.assert(false, 'An AuraHandledException should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }

        // Test updateAccountWithDUNSAndFetchCredit with invalid DUNS to cover catch block
        try {
            DNBCreditCheckCallout.updateAccountWithDUNSAndFetchCredit(testAccount.Id, 'not-a-number');
            System.assert(false, 'An AuraHandledException should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }

    @isTest
    static void testCatchBlocksForNullIds() {
        Test.startTest();
        Map<String, Object> performResult = DNBCreditCheckCallout.performCreditCheck(null);
        System.assertEquals(false, performResult.get('success'));
        Map<String, Object> statusResult = DNBCreditCheckCallout.checkCreditDataStatus(null);
        System.assertEquals(false, statusResult.get('success'));
        Test.stopTest();
    }
   private static String getSuccessfulResponseBody() {
          return '{' +
            '"organization": {' +
                '"primaryName": "Mock Company Name",' +
                '"telephone": [{"telephoneNumber": "555-555-5555"}],' +
                '"primaryIndustryCode": {"usSicV4": "7372", "usSicV4Description": "Prepackaged Software"},' +
                '"primaryAddress": {' +
                    '"streetAddress": {"line1": "123 Mock St"},' +
                    '"addressLocality": {"name": "Mock City"},' +
                    '"addressRegion": {"name": "California"},' +
                    '"postalCode": "94105",' +
                    '"addressCountry": {"name": "United States"}' +
                '},' +
                '"dnbAssessment": {' +
                    '"failureScore": {' +
                        '"classScore": "1",' +
                        '"classScoreDescription": "Low risk of financial stress"' +
                    '},' +
                    '"delinquencyScore": {' +
                        '"classScore": "1",' +
                        '"classScoreDescription": "Low risk of delinquency"' +
                    '},' +
                    '"standardRating": {' +
                        '"rating": "1A",' +
                        '"financialStrength": "Good",' +
                        '"riskSegment": "Low"' +
                    '}' +
                '}' +
            '}' +
        '}';
    }
    
    private class DNBCreditCheckMockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean tokenSuccess;
        
        public DNBCreditCheckMockHttpResponse(Integer statusCode, String responseBody, Boolean tokenSuccess) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.tokenSuccess = tokenSuccess;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            
            if (request.getEndpoint().contains('/v3/token')) {
                response.setStatusCode(tokenSuccess ? 200 : 401);
                response.setBody(tokenSuccess ? '{"access_token":"mock-test-token"}' : '{"error":"unauthorized"}');
                return response;
            }
            
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }
}