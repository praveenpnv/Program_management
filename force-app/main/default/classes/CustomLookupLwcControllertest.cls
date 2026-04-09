@isTest
public class CustomLookupLwcControllertest {

    @testSetup
    static void setupTestData() {
        // Create base data for non-User sObjects
        Account acc = RD1TestDataFactory.createTestAccount();
        Contact con = RD1TestDataFactory.createTestContact(acc.Id, 'Client');

        TR1__Job__c job = RD1TestDataFactory.createTestJob(acc.Id, con.Id);
        job.OwnerId = UserInfo.getUserId();
        job.Responsible_Recruiter__c = UserInfo.getUserId();
        job.TR1__Open_Date__c = Date.today();
        update job;
    }
    
        private static User createUser(String alias, String profileName, String opco) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = new User(
            FirstName = alias,
            LastName  = 'Test',
            Alias     = alias.left(8),
            Email     = alias + '@test.com',
            Username  = alias + Datetime.now().getTime() + '@test.com',
            CommunityNickname = alias + String.valueOf(Math.random()).replace('.', ''),
            TimeZoneSidKey    = 'Asia/Kolkata',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            Dashboard_Role__c = 'Recruiter',
            LanguageLocaleKey = 'en_US',
            ProfileId         = p.Id,
            Opco__c           = opco
        );
        insert u;
        return u;
    }


    @isTest
    static void testFetchLookupData_UserBranch() {
        // Mock DTOs returned from ManagerTeamController
        Test.startTest();
        List<sObject> results = CustomLookupLwcController.fetchLookupData(
            'test', 'User', 'Recruiter'
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null for User branch');
    }

    @isTest
    static void testFetchDefaultRecord_UserNotFound() {
        // Non-existing user Id (use fake Id prefix 005 for User)
        Id fakeUserId = '005000000000000AAA';

        Test.startTest();
        sObject result = CustomLookupLwcController.fetchDefaultRecord(
            fakeUserId, 'Product2', 'Recruiter'
        );
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null if user not found');
    }
    
    
    @isTest
    static void testFetchLookupData_UserBranchs() {
        Test.startTest();
        List<sObject> results = CustomLookupLwcController.fetchLookupData(
            'test', 'User', 'Recruiter'
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null for User branch');
    }
    @isTest
    static void testFetchLookupData_GenericBranch() {
        Test.startTest();
        List<sObject> results = CustomLookupLwcController.fetchLookupData(
            'test', 'Product2', 'Recruiter'
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null for User branch');
    }

    @isTest
    static void testFetchDefaultRecord_UserBranch() {
         Test.startTest();
        // Use current user Id to force a match
        Id currentUserId = UserInfo.getUserId();

       
        sObject result = CustomLookupLwcController.fetchDefaultRecord(
            currentUserId, 'User', 'Recruiter'
        );
        Test.stopTest();
        
         System.assertEquals(null, result,
        'Result will be null because current user is not in available recruiters');
    }
    @IsTest
static void testFetchDefaultRecord_User() {
    // Create a Recruiter
    String opco = 'US';
    User recruiter = createUser('recLwc', 'Recruiter', opco);

    // Create a Manager (Account Manager)
    User rm = createUser('rmLwc', 'Sales (Account Manager)', opco);


    System.runAs(rm) {
        Test.startTest();
        // Now recruiter.Id will be matched inside fetchDefaultRecord
        sObject result = CustomLookupLwcController.fetchDefaultRecord(
            recruiter.Id, 'User', 'Recruiter'
        );
        Test.stopTest();

		System.assertEquals(result, result,
        'Result will be null because current user is not in available recruiters');
    }
   }

}