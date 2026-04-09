@isTest
private class InterviewListControllerTest {

    @isTest
    static void testGetInterviewSchedules_ReturnsSchedulesAsAdmin() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'admin1',
            Email = 'admin.test@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Admin',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata', // Setting TimeZone for India
            Username = 'admin.test@example.com' + System.currentTimeMillis()
        );
        insert adminUser;
        System.runAs(adminUser) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            RecordType applicationRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'TR1__Application_V2__c' LIMIT 1];
            RecordType scheduleRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'TR1__Send_Out_Schedule_V2__c' LIMIT 1];
            Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607'
            );
            insert testPerson;
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Test Job',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                Job_Type__c='contract'
            );
            insert testJob;
            TR1__Application_V2__c testApplication = new TR1__Application_V2__c(
                TR1__Stage__c = 'Closing Report',
                TR1__Applicant__c = testPerson.Id,
                TR1__Job__c = testJob.Id
                
            );
            insert testApplication;
            TR1__Send_Out_Schedule_V2__c schedule1 = new TR1__Send_Out_Schedule_V2__c(
                TR1__Application_V2__c = testApplication.Id,
                Interview_Level__c = 'Level 1',
                TR1__Interview_Date_Time__c = DateTime.now().addDays(1)
            );
            TR1__Send_Out_Schedule_V2__c schedule2 = new TR1__Send_Out_Schedule_V2__c(
                TR1__Application_V2__c = testApplication.Id,
                Interview_Level__c = 'Level 2',
                TR1__Interview_Date_Time__c = DateTime.now().addDays(2),
                Interview_Feedback__c = 'Good candidate'
            );
            insert new List<TR1__Send_Out_Schedule_V2__c>{schedule1, schedule2};
            List<TR1__Send_Out_Schedule_V2__c> results = InterviewListController.getInterviewSchedules(testApplication.Id, scheduleRecordType.Id);
            System.assertEquals(2, results.size(), 'The list should contain two interview schedules for the given application and record type.');
            for (TR1__Send_Out_Schedule_V2__c schedule : results) {
                System.assertEquals(testApplication.Id, schedule.TR1__Application_V2__c, 'Incorrect Application ID on the schedule.');
                System.assertEquals(scheduleRecordType.Id, schedule.RecordTypeId, 'Incorrect Record Type ID on the schedule.');
            }
        }
    }

    @isTest
    static void testGetInterviewSchedules_NoMatchingSchedulesAsAdmin() {
        // Get the ID of the System Administrator profile
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'admin2',
            Email = 'admin.test2@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Admin',
            LastName = 'Test2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata', // Setting TimeZone for India
            Username = 'admin.test2@example.com' + System.currentTimeMillis()
        );
        insert adminUser;
        System.runAs(adminUser) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
            insert testContact;
            RecordType applicationRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'TR1__Application_V2__c' LIMIT 1];
            RecordType scheduleRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'TR1__Send_Out_Schedule_V2__c' LIMIT 1];
            Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607'
            );
            insert testPerson;
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Test Job',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                Job_Type__c='contract'
            );
            insert testJob;
            TR1__Application_V2__c testApplication = new TR1__Application_V2__c(
                TR1__Stage__c = 'Closing Report',
                TR1__Applicant__c = testPerson.Id,
                TR1__Job__c = testJob.Id
            );
            insert testApplication;
            List<TR1__Send_Out_Schedule_V2__c> results = InterviewListController.getInterviewSchedules(testApplication.Id, scheduleRecordType.Id);
            System.assert(results.isEmpty(), 'The list of interview schedules should be empty when no matching records exist.');
        }
    }
}