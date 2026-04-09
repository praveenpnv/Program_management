@isTest
public class QuestionDisplayControllerTest {

    // Helper method to create test data for Application, Job, Question, and Response
    private static void createTestData() {
        // Create a Job record (for reference in TR1__Application_V2__c)
        TR1__Job__c job = new TR1__Job__c(Name = 'Test Job',Job_Type__c='contract');
        insert job;

        // Create a TR1__Application_V2__c record without setting the Name field
        TR1__Application_V2__c application = new TR1__Application_V2__c(
            TR1__Job__c = job.Id
            // Do not set Name here, Salesforce will auto-generate it
        );
        insert application;

        // Create Question__c records associated with the job (JobOrder__c)
        List<Question__c> questions = new List<Question__c>{
            new Question__c(
                QuestionTextEN__c = 'What is your name?',
                ResponseOptions__c = 'Text',
                ResponseType__c = 'Text',
                Grouping__c = 'General',
                Stage__c = 'Application',
                JobOrder__c = job.Id
            ),
            new Question__c(
                QuestionTextEN__c = 'What is your age?',
                ResponseOptions__c = 'Numeric',
                ResponseType__c = 'Number',
                Grouping__c = 'General',
                Stage__c = 'Application',
                JobOrder__c = job.Id
            )
        };
        insert questions;

        // Create Response__c records for the application
        List<Response__c> responses = new List<Response__c>{
            new Response__c(
                JobQuestion__c = questions[0].Id,
                Response_Text__c = 'John Doe',
                ApplicationID__c = application.Id
            ),
            new Response__c(
                JobQuestion__c = questions[1].Id,
                Response_Text__c = '30',
                ApplicationID__c = application.Id
            )
        };
        insert responses;
    }

    @isTest
    public static void testGetSelectedQuestions() {
        // Step 1: Create test data
        createTestData();

        // Step 2: Query the Application ID we inserted
        TR1__Application_V2__c application = [SELECT Id FROM TR1__Application_V2__c LIMIT 1];

        Test.startTest();
        // Call the getSelectedQuestions method
        List<QuestionDisplayController.QuestionWrapper> questionWrappers = 
            QuestionDisplayController.getSelectedQuestions(application.Id);
        Test.stopTest();

        // Step 3: Assertions
        System.assertNotEquals(null, questionWrappers, 'The list of question wrappers should not be null');
        System.assertEquals(2, questionWrappers.size(), 'There should be 2 question wrappers.');

        // Check if the first question matches the expected data
        System.assertEquals('What is your name?', questionWrappers[0].questionText, 'The first question text should match.');
        System.assertEquals('John Doe', questionWrappers[0].responseValue, 'The response value for the first question should match.');
        
        // Check if the second question matches the expected data
        System.assertEquals('What is your age?', questionWrappers[1].questionText, 'The second question text should match.');
        System.assertEquals('30', questionWrappers[1].responseValue, 'The response value for the second question should match.');
    }

    @isTest
    public static void testSaveResponses() {
        // Step 1: Create test data
        createTestData();

        // Step 2: Query the Application ID we inserted
        TR1__Application_V2__c application = [SELECT Id FROM TR1__Application_V2__c LIMIT 1];
        
        // Query all questions to filter by QuestionTextEN__c in Apex code
        List<Question__c> questions = [SELECT Id, QuestionTextEN__c FROM Question__c];
        Question__c question1 = null;
        Question__c question2 = null;

        // Find the questions by text (this replaces direct filtering)
        for (Question__c q : questions) {
            if (q.QuestionTextEN__c == 'What is your name?') {
                question1 = q;
            }
            if (q.QuestionTextEN__c == 'What is your age?') {
                question2 = q;
            }
        }

        // Create a list of QuestionWrapper objects with new responses
        List<QuestionDisplayController.QuestionWrapper> responsesToSave = new List<QuestionDisplayController.QuestionWrapper>();
        
        // Check if the questions were found
        if (question1 != null && question2 != null) {
            // Correct way to instantiate QuestionWrapper objects (use constructor, not name=value)
            responsesToSave.add(new QuestionDisplayController.QuestionWrapper(
                question1.Id, 
                'What is your name?', 
                'Text', 
                'Text', 
                'General', 
                null,  // New response, no existing ID
                'Jane Doe', 
                true, 
                application.Id
            ));

            responsesToSave.add(new QuestionDisplayController.QuestionWrapper(
                question2.Id, 
                'What is your age?', 
                'Numeric', 
                'Number', 
                'General', 
                null,  // New response, no existing ID
                '25', 
                true, 
                application.Id
            ));

            Test.startTest();
            // Call the saveResponses method
            QuestionDisplayController.saveResponses(responsesToSave);
            Test.stopTest();

            List<Response__c> savedResponses = [SELECT Response_Text__c, JobQuestion__c, ApplicationID__c FROM Response__c WHERE ApplicationID__c = :application.Id];
        } else {
            System.assert(false, 'Questions not found.');
        }
    }
}