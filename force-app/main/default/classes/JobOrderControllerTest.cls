@isTest
public class JobOrderControllerTest {

    @testSetup
    static void setupTestData() {
        RD1TestDataFactory.setupAll();
    }

    @isTest
    static void testExtendJob() {
        TR1__Job__c testJob = [SELECT Id, Job_Expiry_Date__c FROM TR1__Job__c LIMIT 1];
        
        Test.startTest();
        JobOrderController.extendJob(testJob.Id, '15');
        Test.stopTest();

        TR1__Job__c updatedJob = [SELECT Id, Job_Expiry_Date__c FROM TR1__Job__c WHERE Id = :testJob.Id LIMIT 1];
		
        DateTime expectedExpiryDate = DateTime.now().addDays(15);
        DateTime actualExpiryDate = updatedJob.Job_Expiry_Date__c;
        
        // Allow a 60-second tolerance
        Integer toleranceInSeconds = 60;
        Boolean isWithinRange = Math.abs(expectedExpiryDate.getTime() - actualExpiryDate.getTime()) <= (toleranceInSeconds * 1000);

        System.assertEquals(isWithinRange, true, 'The Job_Expiry_Date__c should be updated to 15 days from today.');
    }
	
	@isTest
    static void testGetExtensionOptions() {
       TR1__Job__c testJob = [SELECT Id, Job_Expiry_Date__c FROM TR1__Job__c LIMIT 1];
        Test.startTest();
        List<Integer> options = JobOrderController.getExtensionOptions(testJob.Id);
        Test.stopTest();
    
        //System.assertEquals(2, options.size(), 'Should return 2 list');
    }
}