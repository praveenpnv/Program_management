public with sharing class QuestionTemplateController {
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Question_Template__c>> getQuestionsGroupedByGrouping(Id jobOrderId) {
        Map<String, List<Question_Template__c>> groupedQuestions = new Map<String, List<Question_Template__c>>();

        // Query the selected questions
        Set<Id> selectedQuestionIds = new Set<Id>();
        for (Question__c question : [SELECT QuestionTemplate__c FROM Question__c WHERE JobOrder__c = :jobOrderId]) {
            selectedQuestionIds.add(question.QuestionTemplate__c);
        }
        system.debug('selectedQuestionIds'+selectedQuestionIds);

        // Query the Question Templates
        for (Question_Template__c qt : [SELECT Id, AnswerOptions__c, AnswerType__c, Category__c, Grouping__c, KnockOut__c, Mandatory__c, QuestionTextAlt__c, QuestionTextEN__c, Stage__c,Order__c FROM Question_Template__c WHERE Stage__c = 'Application' WITH SECURITY_ENFORCED]) {
            if (!groupedQuestions.containsKey(qt.Grouping__c)) {
                groupedQuestions.put(qt.Grouping__c, new List<Question_Template__c>());
            }

            groupedQuestions.get(qt.Grouping__c).add(qt);
        }
        system.debug('groupedQuestions'+groupedQuestions);
        return groupedQuestions;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkSetupCompleted(Id jobOrderId) {
        Integer questionCount = [SELECT COUNT() FROM Question__c WHERE JobOrder__c = :jobOrderId];
        return questionCount > 0;
    }

    @AuraEnabled
    public static void saveSelectedQuestions(List<Question_Template__c> selectedQuestions, Id jobOrderId) {
        List<Question__c> questionsToInsert = new List<Question__c>();
        system.debug('selectedQuestions'+selectedQuestions);
        for (Question_Template__c selectedQuestion : selectedQuestions) {
            Question__c question = new Question__c();
            question.JobOrder__c = jobOrderId;
            question.QuestionTemplate__c = selectedQuestion.Id;
            question.QuestionTextEN__c = selectedQuestion.QuestionTextEN__c;
            question.QuestionTextAlt__c = selectedQuestion.QuestionTextAlt__c;
            question.Category__c = selectedQuestion.Category__c;
            question.Grouping__c = selectedQuestion.Grouping__c;
            question.KnockOut__c = selectedQuestion.KnockOut__c;
            question.MandatoryToBeAsked__c = selectedQuestion.Mandatory__c;
            question.Order__c = selectedQuestion.Order__c;
            question.ResponseOptions__c = selectedQuestion.AnswerOptions__c;
            question.ResponseType__c = selectedQuestion.AnswerType__c;
            question.Stage__c = selectedQuestion.Stage__c;
            question.VariableSource__c = selectedQuestion.VariableSource__c;

            questionsToInsert.add(question);
        }

        if (!questionsToInsert.isEmpty()) {
            insert questionsToInsert;
        }
    }
}