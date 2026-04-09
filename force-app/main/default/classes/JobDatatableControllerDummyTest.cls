@isTest
private class JobDatatableControllerDummyTest {

    @testSetup
    static void setupData() {
        // Create dummy Account
        Account acc = new Account(Name = 'Dummy Coverage Account');
        insert acc;

        // Create dummy User with a valid Opco__c (must match global value set)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'duser',
            Email = 'dummyuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Dummy',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            Username = 'dummyuser' + DateTime.now().getTime() + '@test.com',
            Opco__c = 'US' // ✅ from your picklist values
        );
        insert u;

        // Create valid Job (respect validation rules + Opco filter)
        TR1__Job__c job = new TR1__Job__c(
            Name = 'Dummy Coverage Job',
            TR1__Open_Date__c = Date.today(),
            TR1__Status__c = 'Open',                // required
            Published_Rate_High__c = 100,           // required
            TR1__Number_of_Openings__c = 1,         // must be > 0
            Responsible_Recruiter__c = u.Id,        // recruiter
            OwnerId = u.Id,                         // owner
            Account__c = acc.Id,
            User_Opco__c = 'US'                     // ✅ required for controller filters
        );
        insert job;
    }

    @isTest
    static void coverAllMethods() {
        User u = [SELECT Id FROM User WHERE Alias = 'duser' LIMIT 1];
        Id uid = u.Id;

        Test.startTest();

        // Query inserted job
        TR1__Job__c job = [SELECT Id, Name FROM TR1__Job__c LIMIT 1];

        // Run all controller methods
        JobDatatableController.getJobs(5, 1, uid);
        JobDatatableController.getTotalJobCount(uid);

        JobDatatableController.updateJobs(new List<TR1__Job__c>{ job });
        JobDatatableController.updateJobs(new List<TR1__Job__c>()); // empty case

        JobDatatableController.getAllUsers();
        JobDatatableController.getTeamRecruiters(uid);

        JobDatatableController.getRecruiterJobs(5, 1, uid);
        JobDatatableController.getRecruiterJobCount(uid);

        JobDatatableController.getRecruiterPlacements(5, 1, uid);
        JobDatatableController.getRecruiterPlacementCount(uid);

        // Edge: call with null userId
        JobDatatableController.getJobs(5, 1, null);
        JobDatatableController.getRecruiterJobs(5, 1, null);
        JobDatatableController.getRecruiterPlacements(5, 1, null);
        JobDatatableController.getRecruiterJobCount(null);
        JobDatatableController.getRecruiterPlacementCount(null);

        // Edge: update with fake Id
        try {
            JobDatatableController.updateJobs(
                new List<TR1__Job__c>{
                    new TR1__Job__c(Id = 'a01' + String.valueOf(System.currentTimeMillis()).right(12), Name = 'Invalid')
                }
            );
        } catch (Exception e) {
            System.debug('Expected DML fail: ' + e.getMessage());
        }

        Test.stopTest();
    }
}