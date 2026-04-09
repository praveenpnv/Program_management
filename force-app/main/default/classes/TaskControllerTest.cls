@IsTest(isParallel = false)
public class TaskControllerTest {
    @testSetup
    static void setupTestData() {
        // Generate a unique username
        String uniqueUsername444 = 'testuser444' + DateTime.now().getTime() + '@example.com';        
        // Create a test user
        Profile p444 = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser444 = new User(
             ProfileId = p444.Id,
            Username = uniqueUsername444,
            Email = 'testuser444@example.com',
            LastName = 'User',
            Alias = 'aduser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true,
            Opco__c = 'Belux'
        );
        insert testUser444;
 System.runAs(testUser444) {

            // Create test Account
            Account testAccount = new Account(
                Name = 'Test Account1',
                AUSY_Changepoint_ID__c = 'CHPID525',
                BillingStreet = 'Test Street',
                BillingCity = 'Bangalore',
                BillingCountry = 'India',
                BillingState = 'Karnataka',
                BillingPostalCode = '12345',
                BH_VAT_Number__c = '29GGGGG1314R9Z9'
            );
            insert testAccount;
            system.debug('testAccount: ' + testAccount);

            // Create test Contact
            Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Unit__c = '5201 Delivery IT operations',
                RecordTypeId = '0127S000000Tmi2QAC',
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607'
            );
            insert testPerson;
            system.debug('testPerson: ' + testPerson);

            // Create TalentRoverProperties record
            TR1__TalentRoverProperties__c trp = new TR1__TalentRoverProperties__c(
                TR1__Enable_New_ATS_Data_model__c = true
            );
            insert trp;

            // Create test Job
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Test Job',
                Business_unit__c = '5201 Delivery IT operations',
                TR1__Account__c = testAccount.Id,
                TR1__Status__c = 'Accepting Candidates',
                Chapter_job__c = 'Analists',
                RecordTypeId = '0127S000000Tmi4QAC',
                Job_Type__c='contract'
            );
            insert testJob;
            system.debug('testJob: ' + testJob);

            // Create test Application
            TR1__Application_V2__c application = new TR1__Application_V2__c(
                TR1__Stage__c = 'Closing Report',
                TR1__Applicant__c = testPerson.Id,
                TR1__Job__c = testJob.Id,
                RecordTypeId = '0127S000000TmiHQAS'
            );
            insert application;
            system.debug('application: ' + application);
         RecordType taskRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName = 'Power_Notes' LIMIT 1];

         // Create a Task record
        Task task = new Task(
            Subject = 'Test Subject',
            Description = 'Test Description',
            Status = 'Not Started',
            Priority = 'Normal',
              TR1__Application_V2__c = application.Id,
            RecordTypeId = taskRecordType.Id
        );
        insert task;
 }
    }

    @isTest
    static void testGetTasksByCriteria() {
        // Fetch test data
        TR1__Application_V2__c app = [SELECT Id FROM TR1__Application_V2__c LIMIT 1];
        RecordType taskRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName = 'Power_Notes' LIMIT 1];

        system.debug('taskRecordType'+taskRecordType);
        // Test valid query
        Task task = TaskController.getTasksByCriteria(app.Id, 'Test Subject', 'Power_Notes');
        system.debug('Task taskRecordType'+task);
        System.assertNotEquals(null, task, 'Task should be returned');
        System.assertEquals('Test Subject', task.Subject, 'Subject should match');
        //System.assertEquals(taskRecordType.Id, task.RecordTypeId, 'Record Type should match');

        // Test with null subject
        task = TaskController.getTasksByCriteria(app.Id, null, 'Power_Notes');
        System.assertNotEquals(null, task, 'Task should be returned when subject is null');

        // Test with invalid record type
        Test.startTest();
        try {
            task = TaskController.getTasksByCriteria(app.Id, 'Test Subject', 'Invalid_Record_Type');
            System.assert(false, 'Exception should be thrown for invalid record type');
        } catch (AuraHandledException e) {
            //System.assertEquals('Error retrieving record type ID: null', e.getMessage());
        }
        

        // Test with null applicationId
        
        try {
            TaskController.getTasksByCriteria(null, 'Test Subject', 'Power_Notes');
            System.assert(false, 'Exception should be thrown for null application ID');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
static void testUpsertTaskDescription() {
    // Fetch test data
    TR1__Application_V2__c app = [SELECT Id FROM TR1__Application_V2__c LIMIT 1];
    RecordType taskRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Task' AND DeveloperName = 'Power_Notes' LIMIT 1];
    Task existingTask = [SELECT Id, Description FROM Task LIMIT 1];

    // Test updating existing task
    Test.startTest();
    TaskController.upsertTaskDescription(existingTask.Id, 'Updated Description', null, null, null);
    Task updatedTask = [SELECT Id, Description FROM Task WHERE Id = :existingTask.Id];
    System.assertEquals('Updated Description', updatedTask.Description, 'Description should be updated');

    // Test creating a new task
    TaskController.upsertTaskDescription(null, 'New Task Description', app.Id, 'New Subject', 'Power_Notes');
    // Query without filtering on Description
    List<Task> tasks = [SELECT Id, Description, Subject, RecordTypeId FROM Task WHERE Subject = 'New Subject'];
    Task newTask = null;
    for (Task t : tasks) {
        if (t.Description == 'New Task Description') {
            newTask = t;
            break;
        }
    }
    System.assertNotEquals(null, newTask, 'New task should be created');
    System.assertEquals('New Task Description', newTask.Description, 'Description should match');
    System.assertEquals('New Subject', newTask.Subject, 'Subject should match');
    System.assertEquals(taskRecordType.Id, newTask.RecordTypeId, 'Record Type should match');

    // Test exception handling for invalid record type
    try {
        TaskController.upsertTaskDescription(null, 'Invalid Task', app.Id, 'Invalid Subject', 'Invalid_Record_Type');
        System.assert(false, 'Exception should be thrown for invalid record type');
    } catch (AuraHandledException e) {
        System.assertEquals('Script-thrown exception', e.getMessage());
    }
    Test.stopTest();
}

}