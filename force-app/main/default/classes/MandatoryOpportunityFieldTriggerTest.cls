@isTest
public class MandatoryOpportunityFieldTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Account since Opportunity requires an Account
       Id clientId = RD1TestDataFactory.getRecordTypeId('Account', 'Client');

        Account testAccount = new Account(Name = 'Test Account',BH_VAT_Number__c = 'Ab5y65',RecordTypeId=clientId);
        insert testAccount;
    }

    @isTest
    static void testBeforeInsert() {
        // Create a test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = [SELECT Id FROM Account LIMIT 1].Id
        );

        Test.startTest();
        insert testOpportunity;
        Test.stopTest();

        // Verify that the opportunity was inserted
        Opportunity insertedOpp = [SELECT Id, Name FROM Opportunity WHERE Id = :testOpportunity.Id LIMIT 1];
        System.assertNotEquals(null, insertedOpp, 'Opportunity should be inserted.');
    }

    @isTest
    static void testBeforeUpdate() {
        // Create and insert an Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = [SELECT Id FROM Account LIMIT 1].Id
        );
        insert testOpportunity;

        // Update the Opportunity
        testOpportunity.StageName = 'Qualification';

        Test.startTest();
        update testOpportunity;
        Test.stopTest();

        // Verify the update
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpportunity.Id LIMIT 1];
        System.assertEquals('Qualification', updatedOpp.StageName, 'Opportunity stage should be updated.');
    }
}