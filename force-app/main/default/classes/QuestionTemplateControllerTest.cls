@IsTest
public class QuestionTemplateControllerTest {
    @IsTest
    static void testGetQuestionsGroupedByGrouping() {
        // Setup test data
        TR1__Job__c jobOrder = new TR1__Job__c(Name = 'Test Job Order', Job_Type__c='contract');
        insert jobOrder;

        Question_Template__c qt1 = new Question_Template__c(
            AnswerOptions__c = 'Option1;Option2',
            AnswerType__c = 'Picklist',
            Category__c = 'General',
            Grouping__c = 'General',
            KnockOut__c = false,
            Mandatory__c = false,
            QuestionTextAlt__c = 'Are you are at least 18 years of age?',
            QuestionTextEN__c = 'Are you are at least 18 years of age?',
            Stage__c = 'Application',
            Order__c = 1
        );
        Question_Template__c qt2 = new Question_Template__c(
            AnswerOptions__c = 'Option3;Option4',
            AnswerType__c = 'Picklist',
            Category__c = 'Job',
            Grouping__c = 'Availability',
            KnockOut__c = false,
            Mandatory__c = false,
            QuestionTextAlt__c = 'How much notice time would you need before starting a new job?',
            QuestionTextEN__c = 'How much notice time would you need before starting a new job?',
            Stage__c = 'Application',
            Order__c = 2
        );
        insert new List<Question_Template__c> { qt1, qt2 };

        Question__c question = new Question__c(
            JobOrder__c = jobOrder.Id,
            QuestionTemplate__c = qt1.Id,
            Grouping__c='General',
            Stage__c='Application'
        );
        insert question;

        // Test the method
        Test.startTest();
        Map<String, List<Question_Template__c>> result = QuestionTemplateController.getQuestionsGroupedByGrouping(jobOrder.Id);
        Test.stopTest();
        
        system.debug('result'+result);

        // Verify results

        //System.assert(result.containsKey('Availability'), 'Availability');
       // System.assert(result.containsKey('General'), 'General');
        //System.assertEquals(1, result.get('Grouping__c').size(), 1);
     
    }

   @IsTest
    static void testCheckSetupCompleted() {
        // Setup test data
        TR1__Job__c jobOrder = new TR1__Job__c(Name = 'Test Job Order',Job_Type__c='contract');
        insert jobOrder;

        Question__c question = new Question__c(
            JobOrder__c = jobOrder.Id,
            QuestionTemplate__c = null,
            Grouping__c='General',
            Stage__c='Application'
        );
        insert question;

        // Test the method
        Test.startTest();
        Boolean isSetupCompleted = QuestionTemplateController.checkSetupCompleted(jobOrder.Id);
        Test.stopTest();

        // Verify results
        System.assert(isSetupCompleted, 'Setup should be completed because there is one question');
    }

    @IsTest
    static void testSaveSelectedQuestions() {
        // Setup test data
        TR1__Job__c jobOrder = new TR1__Job__c(Name = 'Test Job Order',Job_Type__c='contract');
        insert jobOrder;

        Question_Template__c qt1 = new Question_Template__c(
            AnswerOptions__c = 'Option1;Option2',
            AnswerType__c = 'Picklist',
            Category__c = 'General',
            Grouping__c = 'General',
            KnockOut__c = false,
            Mandatory__c = false,
            QuestionTextAlt__c = 'Are you are at least 18 years of age?',
            QuestionTextEN__c = 'Are you are at least 18 years of age?',
            Stage__c = 'Application',
            Order__c = 1
        );
        insert qt1;

        // Test the method
        Test.startTest();
        QuestionTemplateController.saveSelectedQuestions(new List<Question_Template__c> { qt1 }, jobOrder.Id);
        Test.stopTest();

        // Verify results
        List<Question__c> insertedQuestions = [SELECT Id, QuestionTemplate__c FROM Question__c WHERE JobOrder__c = :jobOrder.Id];
        System.assertEquals(1, insertedQuestions.size(), 'One question should have been inserted');
        System.assertEquals(qt1.Id, insertedQuestions[0].QuestionTemplate__c, 'The question should reference the correct template');
    }
}