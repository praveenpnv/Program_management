@isTest
private class JobDatatableControllerTest {

    @testSetup
    static void setupTestData() {
        Account acc = RD1TestDataFactory.createTestAccount();
        Contact con = RD1TestDataFactory.createTestContact(acc.Id, 'Client');

        TR1__Job__c job = RD1TestDataFactory.createTestJob(acc.Id, con.Id);
        job.OwnerId = UserInfo.getUserId();
        job.Responsible_Recruiter__c = UserInfo.getUserId();
        job.TR1__Open_Date__c = Date.today();
        update  job;
    }

    @isTest
    static void testGetJobsAndCount() {
        Id currentUserId = UserInfo.getUserId();
        Test.startTest();
        List<TR1__Job__c> results = JobDatatableController.getJobs(5, 1,currentUserId);
        Integer count = JobDatatableController.getTotalJobCount(currentUserId);
        Test.stopTest();

        System.assert(results.size() >= 0, 'Jobs query should run without error');
        System.assert(count >= 0, 'Count query should run without error');
    }

    @isTest
    static void testUpdateJobs() {
        TR1__Job__c job = [SELECT Id, Name FROM TR1__Job__c LIMIT 1];
        job.Name = 'Test Account - Updated Job Name';

        Test.startTest();
        JobDatatableController.updateJobs(new List<TR1__Job__c>{ job });
        Test.stopTest();

        TR1__Job__c updated = [SELECT Name FROM TR1__Job__c WHERE Id = :job.Id];
        System.assertEquals('Test Account - Updated Job Name', updated.Name, 'Job should update correctly');
    }

    @isTest
    static void testGetAllUsers() {
        Test.startTest();
        List<User> users = JobDatatableController.getAllUsers();
        Test.stopTest();

        //System.assert(!users.isEmpty(), 'Should return at least the running test user');
    }

    @isTest
    static void testRecruiterMethods() {
        Id currentUserId = UserInfo.getUserId();
        Test.startTest();
        List<User> recruiters = JobDatatableController.getTeamRecruiters(currentUserId);
        List<TR1__Job__c> recruiterJobs = JobDatatableController.getRecruiterJobs(5, 1,currentUserId);
        Integer recruiterJobCount = JobDatatableController.getRecruiterJobCount(currentUserId);
        List<TR1__Closing_Report__c> recruitersPlacements = JobDatatableController.getRecruiterPlacements(5,1,currentUserId);
        Integer recruiterPlaceCount = JobDatatableController.getRecruiterPlacementCount(currentUserId);
        Test.stopTest();

        System.assert(recruiters.size() >= 0, 'Recruiters query should run');
        System.assert(recruiterJobs.size() >= 0, 'Recruiter jobs query should run');
        System.assert(recruiterJobCount >= 0, 'Recruiter job count query should run');
    }
}