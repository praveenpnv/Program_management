/**
* @File Name : OpportunityLIcontrollerTest.cls
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

@isTest
public class OpportunityLIcontrollerTest {

    @testSetup
    static void setupData() {
       
        RD1TestDataFactory.createOpportunityLineItemData(true);
    }

    @isTest
    static void testAssignStandardPricebook() {
    Opportunity opp = RD1TestDataFactory.createCleanOpportunity();

    System.assertEquals(null, opp.Pricebook2Id, 'Pricebook should be null initially');

    Test.startTest();
    Boolean result = OpportunityLIcontroller.assignStandardPricebook(opp.Id);
    Test.stopTest();

    System.assertEquals(true, result);
    Opportunity updatedOpp = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opp.Id];
    System.assertNotEquals(null, updatedOpp.Pricebook2Id, 'Pricebook should be set by controller');
}
    
    @isTest
    static void testAssignAlredayStandardPricebook() {
        Opportunity opp = [SELECT Id,Name,CurrencyIsoCode,Pricebook2Id FROM Opportunity LIMIT 1];
       
        Test.startTest();
        Boolean result = OpportunityLIcontroller.assignStandardPricebook(opp.Id);
        Test.stopTest();

        System.assertEquals(true, result);
        Opportunity updatedOpp = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, updatedOpp.Pricebook2Id);
    }

    @isTest
    static void testGetDefaultLineItemValues() {
        Opportunity opp = [SELECT Id,Pricebook2Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Test.startTest();
        OpportunityLIcontroller.DefaultLineItemDefaults defaults =
            OpportunityLIcontroller.getDefaultLineItemValues(opp.Id);
        Test.stopTest();

        System.assertEquals(opp.Id, defaults.opportunityId);
        System.assertNotEquals(null, defaults.pricebookEntryId);
        System.assertEquals(100, defaults.salesPrice);
        System.assertEquals(1, defaults.quantity);
    }

    @isTest
    static void testGetFieldSetFields() {
        List<Map<String, Object>> fields = OpportunityLIcontroller.getFieldSetFields('LineItem_Field');
        system.debug('fields'+fields);
        System.assert(fields != null);
    }
    @isTest
static void testGetOpportunityFields() {
    // Retrieve an existing Opportunity from setup
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    
    Test.startTest();
    Opportunity result = OpportunityLIcontroller.getOpportunityFields(opp.Id);
    Test.stopTest();
    
    // Validate the result
    System.assertNotEquals(null, result, 'Returned Opportunity should not be null');
    System.assertEquals(opp.Id, result.Id, 'Opportunity Id should match');
}
    @isTest
    static void testGetJobTypePicklistValues_Success() {
        Test.startTest();
        // Act: Call the method.
        List<OpportunityLIcontroller.PicklistOption> options = OpportunityLIcontroller.getJobTypePicklistValues();
        Test.stopTest();

        // Assert: Verify that the method returned a list of options.
        System.assertNotEquals(null, options, 'Picklist options list should not be null.');
        System.assert(!options.isEmpty(), 'Picklist options list should not be empty.');
        // Optionally, check for a specific known value.
        Boolean foundContract = false;
        for(OpportunityLIcontroller.PicklistOption opt : options) {
            if(opt.value == 'Contract') {
                foundContract = true;
                break;
            }
        }
        System.assert(foundContract, 'The "Contract" option was not found in the picklist values.');
    }

}