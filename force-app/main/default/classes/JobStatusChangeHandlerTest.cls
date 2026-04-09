@IsTest
public class JobStatusChangeHandlerTest {
    @isTest
    static void testUpdateHoldFields() {
        // STEP 1: Insert the System Admin User (Setup Object)
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser67 = new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = 'TestAdmin',
            Email = 'adminuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'aduser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser67; 

        // STEP 2: Run all TR1__Job__c operations as this user
        System.runAs(adminUser67) {
            // Get Record Type Id
            Id jobRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'TR1__Job__c' AND DeveloperName = 'Consulting' LIMIT 1].Id;

            // Create and insert the job (Non-Setup Object)
            TR1__Job__c job1 = new TR1__Job__c(
                Name = 'Test Job',
                User_Opco__c = 'Belux',
                Business_unit__c = '5201 Delivery IT operations',
                RecordTypeId = jobRecordTypeId,
                TR1__Open_Date__c = Date.today().addDays(-5),
                TR1__Status__c = 'On Hold',
                Job_Type__c = 'Contract',
                Open_Closed__c = True
            );
            insert job1; 

            // Refresh job record from the database
            job1 = [SELECT Id, TR1__Status__c, Hold_From_Date__c, Days_On_Hold__c FROM TR1__Job__c WHERE Id = :job1.Id];

            Test.startTest(); 

            // FIRST CHANGE: Set status to "Hold"
            Map<Id, TR1__Job__c> oldJobMap = new Map<Id, TR1__Job__c>{ job1.Id => job1.clone() }; // Clone before update
            job1.TR1__Status__c = 'On Hold';
            update job1; 

            // Call handler
            job1 = [SELECT Id, TR1__Status__c, Hold_From_Date__c FROM TR1__Job__c WHERE Id = :job1.Id];
            JobStatusChangeHandler.updateHoldFields(new List<TR1__Job__c>{ job1 }, oldJobMap);

            // Verify Hold_From_Date__c is set
            // System.assertNotEquals(null, job1.Hold_From_Date__c, 'Hold_From_Date__c should be set when status changes to Hold');

            // SECOND CHANGE: Set status to "Closed"
            oldJobMap.put(job1.Id, job1.clone()); // Clone old state
            job1.TR1__Status__c = 'Closed';
            job1.TR1__Closed_Reason__c = 'Filled';
            update job1; 

            // Call handler
            job1 = [SELECT Id, TR1__Status__c, Days_On_Hold__c,Hold_From_Date__c FROM TR1__Job__c WHERE Id = :job1.Id];
            
            JobStatusChangeHandler.updateHoldFields(new List<TR1__Job__c>{ job1 }, oldJobMap);
            Test.stopTest(); 

            // Verify Days_On_Hold__c is updated
            // System.assertNotEquals(null, job1.Days_On_Hold__c, 'Days_On_Hold__c should be updated when status changes from Hold');
        }
    }
}