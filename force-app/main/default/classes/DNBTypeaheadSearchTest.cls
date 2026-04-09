@isTest
public class DNBTypeaheadSearchTest {
    
    private static final String TEST_ACCESS_TOKEN = 'mock-access-token-12345';
    private static final String TEST_SEARCH_TERM = 'Test Company';
    private static final Decimal TEST_DUNS_NUMBER = 123456789;
    
    /**
     * For testing purposes - controls mock token behavior
     */
    @TestVisible
    private static Boolean returnValidToken = true;
    
    /**
     * Test setup method to create test data
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts for parent account testing
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 1; i <= 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Parent Account ' + i,
                D_U_N_S_Number__c = 100000000 + i
            ));
        }
        
        // Create an account with a specific DUNS number for update testing
        testAccounts.add(new Account(
            Name = 'Existing DNB Company',
            D_U_N_S_Number__c = TEST_DUNS_NUMBER,
            BillingCity = 'Old City',
            Industry = 'Old Industry'
        ));
        
        insert testAccounts;
    }
    
    /**
     * Test searchDNB method with successful API response
     */
    @isTest
    static void testSearchDNB_Success() {
        // Set up successful mock response
        Test.setMock(HttpCalloutMock.class, new DNBTypeaheadMockHttpResponse(
            200,
            getSuccessfulSearchResponse(),
            true
        ));
        
        // Set mock token to return valid token
        returnValidToken = true;
        
        Test.startTest();
        String result = DNBTypeaheadSearch.searchDNB(TEST_SEARCH_TERM);
        Test.stopTest();
        
        // Verify successful response
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.contains('error'), 'Result should not contain error');
        System.assert(result.contains('searchResultsCount'), 'Result should contain search results');
    }
    
    /**
     * Test searchDNB method with API error response
     */
    @isTest
    static void testSearchDNB_APIError() {
        // Set up error mock response
        Test.setMock(HttpCalloutMock.class, new DNBTypeaheadMockHttpResponse(
            400,
            '{"error": "Bad Request"}',
            true
        ));
        
        // Set mock token to return valid token
        returnValidToken = true;
        
        Test.startTest();
        String result = DNBTypeaheadSearch.searchDNB(TEST_SEARCH_TERM);
        Test.stopTest();
        
        // Verify error response
        System.assert(result.contains('error'), 'Result should contain error message');
        System.assert(result.contains('API Call Failed'), 'Result should indicate API call failed');
        System.assert(result.contains('400'), 'Result should contain status code');
    }
    
    /**
     * Test searchDNB method with no token available
     */
    @isTest
    static void testSearchDNB_NoToken() {
        // Don't set up mock response as it shouldn't be called
        
        // Set mock token to return null
        returnValidToken = false;
        
        Test.startTest();
        String result = DNBTypeaheadSearch.searchDNB(TEST_SEARCH_TERM);
        Test.stopTest();
        
        // Verify error response due to no token
        System.assert(result.contains('error'), 'Result should contain error message');
    }
    
    /**
     * Test searchDNB method with empty search term
     */
    @isTest
    static void testSearchDNB_EmptySearchTerm() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new DNBTypeaheadMockHttpResponse(
            200,
            '{"searchResultsCount": 0, "searchResults": []}',
            true
        ));
        
        // Set mock token to return valid token
        returnValidToken = true;
        
        Test.startTest();
        String result = DNBTypeaheadSearch.searchDNB('');
        Test.stopTest();
        
        // Verify response handles empty search term
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
   
    /**
     * Test importOrUpdateAccount method with different AnnualRevenue data types
     */
    @isTest
    static void testImportOrUpdateAccount_StringRevenue() {
        // Test with String revenue
        Map<String, Object> accountDataString = new Map<String, Object>{
            'Name' => 'String Revenue Company',
            'D_U_N_S_Number__c' => Decimal.valueOf(777777777),
            'AnnualRevenue' => '1500000'
        };
        
        Test.startTest();
        Map<String, Object> result1 = DNBTypeaheadSearch.importOrUpdateAccount(accountDataString);
        Test.stopTest();
        
        // Verify string revenue was processed
        System.assertNotEquals(null, result1.get('id'), 'Account ID should be returned');
        
        Account createdAccount = [SELECT AnnualRevenue FROM Account WHERE D_U_N_S_Number__c = 777777777];
        System.assertEquals(1500000, createdAccount.AnnualRevenue, 'String revenue should be converted to Decimal');
    }
    
    /**
     * Test importOrUpdateAccount method with Double revenue
     */
    @isTest
    static void testImportOrUpdateAccount_DoubleRevenue() {
        // Test with Double revenue
        Map<String, Object> accountDataDouble = new Map<String, Object>{
            'Name' => 'Double Revenue Company',
            'D_U_N_S_Number__c' => Decimal.valueOf(666666666),
            'AnnualRevenue' => Double.valueOf(2500000)
        };
        
        Test.startTest();
        Map<String, Object> result2 = DNBTypeaheadSearch.importOrUpdateAccount(accountDataDouble);
        Test.stopTest();
        
        // Verify double revenue was processed
        System.assertNotEquals(null, result2.get('id'), 'Account ID should be returned');
        
        Account createdAccount2 = [SELECT AnnualRevenue FROM Account WHERE D_U_N_S_Number__c = 666666666];
        System.assertEquals(2500000, createdAccount2.AnnualRevenue, 'Double revenue should be converted to Decimal');
    }
    
    /**
     * Test getParentAccounts method
     */
    @isTest
    static void testGetParentAccounts_Success() {
        Test.startTest();
        List<Account> parentAccounts = DNBTypeaheadSearch.getParentAccounts();
        Test.stopTest();
        
        // Verify parent accounts are returned
        System.assertNotEquals(null, parentAccounts, 'Parent accounts list should not be null');
        System.assert(parentAccounts.size() > 0, 'Should return some parent accounts');
        System.assert(parentAccounts.size() <= 100, 'Should not return more than 100 accounts');
        
        // Verify accounts are ordered by name
        for (Integer i = 1; i < parentAccounts.size(); i++) {
            System.assert(parentAccounts[i-1].Name <= parentAccounts[i].Name, 'Accounts should be ordered by name');
        }
    }
    
    /**
     * Test getRecordTypes method with valid object
     */
    @isTest
    static void testGetRecordTypes_ValidObject() {
        Test.startTest();
        List<Map<String, String>> recordTypes = DNBTypeaheadSearch.getRecordTypes('Account');
        Test.stopTest();
        
        // Verify record types are returned
        System.assertNotEquals(null, recordTypes, 'Record types list should not be null');
        
        // Verify structure of returned data
        if (recordTypes.size() > 0) {
            Map<String, String> firstRecordType = recordTypes[0];
            System.assert(firstRecordType.containsKey('Id'), 'Record type should contain Id');
            System.assert(firstRecordType.containsKey('Name'), 'Record type should contain Name');
            System.assertNotEquals(null, firstRecordType.get('Id'), 'Record type Id should not be null');
            System.assertNotEquals(null, firstRecordType.get('Name'), 'Record type Name should not be null');
        }
        
        // Verify no master record types are included
        for (Map<String, String> recordType : recordTypes) {
            String rtName = recordType.get('Name').toLowerCase();
            System.assert(!rtName.contains('master'), 'Master record types should be filtered out');
        }
    }   
    /**
     * Helper method to generate successful search response
     */
    private static String getSuccessfulSearchResponse() {
        return '{' +
            '"searchResultsCount": 2,' +
            '"searchResults": [' +
                '{' +
                    '"organization": {' +
                        '"duns": "123456789",' +
                        '"primaryName": "Test Company Inc",' +
                        '"primaryAddress": {' +
                            '"streetAddress": "123 Test St",' +
                            '"addressLocality": "Test City",' +
                            '"addressCountry": "US"' +
                        '}' +
                    '}' +
                '},' +
                '{' +
                    '"organization": {' +
                        '"duns": "987654321",' +
                        '"primaryName": "Another Test Company",' +
                        '"primaryAddress": {' +
                            '"streetAddress": "456 Another St",' +
                            '"addressLocality": "Another City",' +
                            '"addressCountry": "US"' +
                        '}' +
                    '}' +
                '}' +
            ']' +
        '}';
    }
    
    /**
     * Mock HTTP Response class for testing
     */
    private class DNBTypeaheadMockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean tokenSuccess;
        
        public DNBTypeaheadMockHttpResponse(Integer statusCode, String responseBody, Boolean tokenSuccess) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.tokenSuccess = tokenSuccess;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            
            // Check if this is a token request
            if (request.getEndpoint().contains('/v3/token')) {
                if (tokenSuccess) {
                    response.setStatusCode(200);
                    response.setBody('{"access_token":"' + TEST_ACCESS_TOKEN + '","expires_in":43200,"token_type":"Bearer"}');
                } else {
                    response.setStatusCode(401);
                    response.setBody('{"error":"unauthorized"}');
                }
                return response;
            }
            
            // For the typeahead search API request
            // Verify request format
            String expectedEndpointPrefix = 'https://plus.dnb.com/v1/search/typeahead?searchTerm=';
            System.assert(request.getEndpoint().startsWith(expectedEndpointPrefix), 
                         'Endpoint should start with ' + expectedEndpointPrefix);
            System.assertEquals('GET', request.getMethod(), 'Method should be GET');
            
            // Check if Authorization header is set with the token
            if (tokenSuccess) {
                System.assert(request.getHeader('Authorization') != null, 'Authorization header should be set');
                System.assert(request.getHeader('Authorization').contains(TEST_ACCESS_TOKEN), 
                             'Authorization header should contain the token');
            }
            
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }
}