@isTest(isParallel = false)
public class OpportunityTriggerTest {
    
    @isTest
    public static void testOpportunityTrigger() {
        // Create a test profile (setup object)
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Create a test user using the factory method (don't specify Id here)
        User testUser = OpportunityTestDataFactory.createTestUser(testProfile.Id);
        
        // Insert the test user (this will automatically generate an Id for the user)
        
        System.runAs(testUser) {
            
            // Create a test opportunity for the user
            Opportunity testOpportunity = OpportunityTestDataFactory.createTestOpportunity(testUser.Id);
            insert testOpportunity;
            
            // Get the first 2 initials of Opco__c
            String opcoInitials = (testUser.Opco__c != null && testUser.Opco__c.length() >= 2)
                ? testUser.Opco__c.substring(0, 2).toUpperCase()
                : 'XX';
            
            // Create a list of Opportunity Ids for the batch job
            List<Id> opportunityIds = new List<Id>();
            opportunityIds.add(testOpportunity.Id);
            
            // Start the batch job
            Test.startTest();
            UpdateOpportunityIDsBatch batch = new UpdateOpportunityIDsBatch(opportunityIds);
            Database.executeBatch(batch);
            Test.stopTest();
            
            // Query for the Opportunity to get the updated value
            testOpportunity = [SELECT Randstad_ID__c, Counter_ID__c FROM Opportunity WHERE Id = :testOpportunity.Id];
            
            // Verify that the batch job updated the Opportunity with the correct Randstad_ID__c
            System.assertEquals(opcoInitials + '_' + Date.today().year() + '_' + testOpportunity.Counter_ID__c, testOpportunity.Randstad_ID__c);
        }
    }
}