/**
* @File Name : JobPrefillHandlerTest.cls
* @Description :
* @Author :Milan Prasad
* @Last Modified By :
* @Last Modified On : June 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 28, 2025 |   | Initial Version
**/

@IsTest
private class JobPrefillHandlerTest {

    @TestSetup
    static void setupTestData() {

         RD1TestDataFactory.createOpportunityLineItemData(true);
    }
    
    @IsTest
    static void testConsultingJobCreation() {
        OpportunityLineItem lineItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        lineItem.Job_Type__c = 'Contract';
        lineItem.Number_of_Positions__c = 1;
        update lineItem;

        Test.startTest();
        List<Map<String, String>> results = JobPrefillHandler.createJobsFromLineItems(new List<Id>{lineItem.Id});
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result list should not be null.');
        System.assertEquals(1, results.size(), 'Expected one job result to be returned.');

    }
    @IsTest
    static void testSolutionsJobCreation() {
        OpportunityLineItem lineItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        lineItem.Job_Type__c = 'Solutions';
        lineItem.Number_of_Positions__c = 1;
        update lineItem;

        Test.startTest();
        List<Map<String, String>> results = JobPrefillHandler.createJobsFromLineItems(new List<Id>{lineItem.Id});
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result list should not be null.');
        System.assertEquals(1, results.size(), 'Expected one job result to be returned.');
    }

    @IsTest
    static void testCreateJobsFromLineItems() {

    List<OpportunityLineItem> lineItems = [SELECT Id FROM OpportunityLineItem LIMIT 1];
    List<Id> lineItemIds = new List<Id>{lineItems[0].Id};

    // Use helper method instead of SOQL for record type IDs
    Id permRT = RD1TestDataFactory.getRecordTypeId('TR1__Job__c', 'Permanent');
    Id consultingRT = RD1TestDataFactory.getRecordTypeId('TR1__Job__c', 'Consulting');
    Id solutionsRT = RD1TestDataFactory.getRecordTypeId('TR1__Job__c', 'Solutions');

    System.assertNotEquals(null, permRT, 'Permanent record type not found');
    System.assertNotEquals(null, consultingRT, 'Consulting record type not found');
    System.assertNotEquals(null, solutionsRT, 'Solutions record type not found');

    Set<Id> expectedRTIds = new Set<Id>{ permRT, consultingRT, solutionsRT };
    Test.startTest();
    List<Map<String, String>> results = JobPrefillHandler.createJobsFromLineItems(lineItemIds);
    Test.stopTest();

    System.assertNotEquals(null, results);
    System.assert(results.size() > 0);

    List<TR1__Job__c> jobs = [
        SELECT Id, OpportunityLineItem__c, RecordTypeId 
        FROM TR1__Job__c 
        WHERE OpportunityLineItem__c IN :lineItemIds
    ];
    System.assertEquals(3, jobs.size());

    for (TR1__Job__c job : jobs) {
        System.assert(expectedRTIds.contains(job.RecordTypeId), 'Job should have a valid RecordType');
    }
    }
}