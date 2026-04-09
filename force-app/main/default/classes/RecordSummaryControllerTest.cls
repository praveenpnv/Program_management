@isTest
public class RecordSummaryControllerTest {

    // Helper method to create test data for TR1__Filter__c
    private static void createTestFilters() {
        List<TR1__Filter__c> filters = new List<TR1__Filter__c>{
            new TR1__Filter__c(
                Name = 'Filter 1',
                TR1__Object_Name__c = 'TR1__Application_V2__c',
                TR1__Is_Private__c = false,
                TR1__Filter_Logic__c = 'Logic 1'
            ),
            new TR1__Filter__c(
                Name = 'Filter 2',
                TR1__Object_Name__c = 'TR1__Application_V2__c',
                TR1__Is_Private__c = false,
                TR1__Filter_Logic__c = 'Logic 2'
            )
        };
        insert filters;
    }

    // Helper method to create test data for the sObject (replace 'Account' with the actual sObject)
    private static void createTestSObjectData() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Account 1', Industry = 'Technology'),
            new Account(Name = 'Account 2', Industry = 'Healthcare'),
            new Account(Name = 'Account 3', Industry = 'Technology')
        };
        insert accounts;
    }

    @isTest
    public static void testGetFilterIdsByPicklistValues() {
        // Step 1: Create test data
        createTestFilters();

        // Step 2: Test with a valid list of picklist values
        List<String> picklistValues = new List<String>{'Filter 1', 'Filter 2'};
        Test.startTest();
        Map<String, String> result = RecordSummaryController.getFilterIdsByPicklistValues(picklistValues);
        Test.stopTest();

        // Step 3: Assertions
        System.assertEquals(2, result.size(), 'The map should contain 2 filters.');
        System.assert(result.containsKey('Filter 1'), 'The map should contain Filter 1.');
        System.assert(result.containsKey('Filter 2'), 'The map should contain Filter 2.');
    }

    @isTest
    public static void testGetSummaryByPicklistAndField() {
        // Step 1: Create test data
        createTestSObjectData();

        // Step 2: Test summary with picklist field 'Industry' and fieldValue 'Technology'
        String sObjectName = 'Account';
        String picklistField = 'Industry';
        String fieldName = 'Industry'; // Changed to 'Industry' field
        String fieldValue = 'Technology'; // Field value 'Technology' for the Industry field
        
        Test.startTest();
        Map<String, Integer> summary = RecordSummaryController.getSummaryByPicklistAndField(sObjectName, picklistField, fieldName, fieldValue);
        Test.stopTest();

        // Step 3: Assertions
        System.assertEquals(1, summary.size(), 'The summary should contain one entry.');
        System.assert(summary.containsKey('Technology'), 'The summary should contain the Technology industry.');
        System.assertEquals(2, summary.get('Technology'), 'There should be 2 accounts in the Technology industry.');
    }

    @isTest
    public static void testGetRecordTypeId() {
        // Step 1: Create test data
        createTestSObjectData();

        // Step 2: Test the getRecordTypeId method
        String sObjectName = 'Account';
        String fieldName = 'Name';
        String fieldValue = 'Account 1';
        
        Test.startTest();
        Id recordTypeId = RecordSummaryController.getRecordTypeId(sObjectName, fieldName, fieldValue);
        Test.stopTest();

        // Step 3: Assertions
        System.assertNotEquals(null, recordTypeId, 'The record type ID should not be null.');
    }
}