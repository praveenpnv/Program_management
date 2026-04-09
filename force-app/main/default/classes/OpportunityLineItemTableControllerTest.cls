/**
 * @File Name: OpportunityLineItemTableControllerTest.cls
 * @Description: Unit tests for OpportunityLineItemTableController
 * @Author: Rizwan Ahmed
 * @Created On: Jun 13, 2025
 * @Modified On: Jul 14, 2025
 */
@isTest
public class OpportunityLineItemTableControllerTest {

    @testSetup
    static void setupData() {
        RD1TestDataFactory.createOpportunityLineItemData(true);
    }

    @isTest
    static void testGetLineItems_WithTreeStructure() {
        // Get test Opportunity from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> results = OpportunityLineItemTableController.getLineItems(opp.Id);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Expected at least one OpportunityLineItem row');

        Boolean foundChildJob = false;
        for (Map<String, Object> oliRow : results) {
            System.assert(oliRow.containsKey('LineItem_Name__c'), 'OLI should have LineItem_Name__c');
            System.assert(oliRow.containsKey('Job_Count__c'), 'OLI should contain job count field');

            if (oliRow.containsKey('_children')) {
                List<Object> children = (List<Object>) oliRow.get('_children');
                System.assert(children.size() > 0, 'Expected child job rows');
                Map<String, Object> jobRow = (Map<String, Object>)children[0];

                System.assert(jobRow.containsKey('Job_Name__c'), 'Job child should have Job_Name__c');
                System.assert(jobRow.containsKey('Job_Status__c'), 'Job child should have Job_Status__c');
                foundChildJob = true;
            }
        }

        System.assert(foundChildJob, 'Expected at least one child job record');
    }
    
    @isTest
    static void testGetLineItems_WithNullOpportunityId() {
        Test.startTest();
        try {
            OpportunityLineItemTableController.getLineItems(null);
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'Exception message did not match.');
        }
        Test.stopTest();
    }
}