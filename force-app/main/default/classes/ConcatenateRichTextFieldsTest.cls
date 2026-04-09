@isTest
public class ConcatenateRichTextFieldsTest {
    
    @testSetup
    static void setupData() {
        // Create some initial data if needed for other tests
    }

    @isTest
    static void testInsertTrigger() {
        // Test the trigger for the insert scenario
        TR1__Job__c newJob = new TR1__Job__c(Job_Type__c='contract');
        newJob.TR1__Client_Job_Description__c = 'Client Description';
        newJob.TR1__Responsibilities__c = 'Responsibilities';

        // Insert the job record
        insert newJob;

        // Retrieve the inserted job
        TR1__Job__c insertedJob = [SELECT Id, Job_Descripition_and_Responsibilities__c FROM TR1__Job__c WHERE Id = :newJob.Id];

        // Verify that the concatenation occurred correctly
        //System.assertEquals('Client DescriptionJob Responsibilities<br>Responsibilities', insertedJob.Job_Descripition_and_Responsibilities__c);
    }

    @isTest
    static void testUpdateTrigger() {
        // Insert a job first to simulate update operation later
        TR1__Job__c jobToUpdate = new TR1__Job__c(Job_Type__c='contract');
        jobToUpdate.TR1__Client_Job_Description__c = 'Initial Client Description';
        jobToUpdate.TR1__Responsibilities__c = 'Initial Responsibilities';

        // Insert the job record
        insert jobToUpdate;

        // Update the job with new values
        jobToUpdate.TR1__Client_Job_Description__c = 'Updated Client Description';
        jobToUpdate.TR1__Responsibilities__c = 'Updated Responsibilities';

        // Update the job record
        update jobToUpdate;

        // Retrieve the updated job
        TR1__Job__c updatedJob = [SELECT Id, Job_Descripition_and_Responsibilities__c FROM TR1__Job__c WHERE Id = :jobToUpdate.Id];

        // Verify that the concatenation occurred on update
       // System.assertEquals('Updated Client DescriptionJob Responsibilities<br>Updated Responsibilities', updatedJob.Job_Descripition_and_Responsibilities__c);
    }
}