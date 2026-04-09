@isTest(isParallel = false)
public class TetrisApplicationAccountTest {
    
    @isTest
    static void test_ESBSFSubmitApplication() {
        // Set up custom settings for testing
        Api_Url__c esbSetting = new Api_Url__c(
            Name = 'ESB_URL',
            Url__c = 'https://test-esb.com',
            Key__c = 'testKey'
        );
        insert esbSetting;

        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account22'
        );
        insert testAccount;

        // Prepare list of AusyApplicationESBCallable with test data
        List<AusyApplicationESBCallable> apps = new List<AusyApplicationESBCallable>();
        AusyApplicationESBCallable app = new AusyApplicationESBCallable();
        app.AppId = testAccount.Id;
        apps.add(app);

        // Call the method under test
        Test.startTest();
        List<ID> jobIDs = TetrisApplicationAccount.ESBSFSubmitApplication(apps);
        Test.stopTest();

        // Verify that the job was enqueued
        System.assertEquals(1, jobIDs.size(), 'One job should have been enqueued.');
        System.assertNotEquals(null, jobIDs[0], 'Job ID should not be null');
    }
}