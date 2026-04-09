public with sharing class QuestionDisplayController {
    @AuraEnabled(cacheable=true)
    public static List<QuestionWrapper> getSelectedQuestions(Id applicationId) {
        // Retrieve the associated Job ID based on the Application ID
        system.debug('Id'+applicationId);
        List<TR1__Application_V2__c> applicationList = [
            SELECT Id, TR1__Job__c FROM TR1__Application_V2__c WHERE Id =:applicationId
        ];
         system.debug('applicationList'+applicationList);
        if (applicationList.isEmpty()) {
            return new List<QuestionWrapper>();
        }

        String jobId = applicationList[0].TR1__Job__c;
         system.debug('jobId'+jobId);

        // Retrieve the questions related to the Job Order
        List<Question__c> questionList = [
            SELECT Id, QuestionTextEN__c, ResponseOptions__c, ResponseType__c, Grouping__c 
            FROM Question__c  
            WHERE JobOrder__c = :jobId
        ];
         system.debug('questionList'+questionList);

        // Retrieve existing responses for the application
        /*Map<Id, Response__c> responseMap = new Map<Id, Response__c>([
            SELECT Id, Response_Text__c, JobQuestion__c, ApplicationID__c
            FROM Response__c
            WHERE ApplicationID__c ='a0A9O0000047Ef3UAE'
        ]);*/
        Map<Id, Response__c> responseMap = new Map<Id, Response__c>();
        for(Response__c res:[SELECT Id, Response_Text__c, JobQuestion__c, ApplicationID__c FROM Response__c WHERE ApplicationID__c =:applicationId])
        {
            responseMap.put(res.JobQuestion__c,res);
        }
        
        system.debug('responseMap'+responseMap);

        // Initialize the wrapper list
        List<QuestionWrapper> questionWrappers = new List<QuestionWrapper>();

        // Create wrappers for each question
        for (Question__c question : questionList) {
            Response__c response = responseMap.get(question.Id);
            questionWrappers.add(new QuestionWrapper(
                question.Id,
                question.QuestionTextEN__c,
                question.ResponseOptions__c,
                question.ResponseType__c,
                question.Grouping__c,
                response != null ? response.Id : null,
                response != null ? response.Response_Text__c : null,
                question.Grouping__c == 'General',
                applicationId
            ));
        }
        system.debug('questionWrappers'+questionWrappers);
        return questionWrappers;
    }

    @AuraEnabled
    public static void saveResponses(List<QuestionWrapper> responses) {
        List<Response__c> responseList = new List<Response__c>();
        system.debug('responses'+responses);
        
        for (QuestionWrapper responseWrapper : responses) {
            Response__c res = new Response__c();
            res.JobQuestion__c = responseWrapper.questionId;
            res.Response_Text__c = responseWrapper.responseValue;
            res.ApplicationID__c = responseWrapper.applicationId;
            res.id=responseWrapper.responseId;
            responseList.add(res);
        }
        

        upsert responseList; // Upsert to handle both insert and update scenarios
    }

    public class QuestionWrapper {
        @AuraEnabled public Id questionId { get; set; }
        @AuraEnabled public String questionText { get; set; }
        @AuraEnabled public String responseOptions { get; set; }
        @AuraEnabled public String responseType { get; set; }
        @AuraEnabled public Boolean isRequired { get; set; }
        @AuraEnabled public String grouping { get; set; }
        @AuraEnabled public Id responseId { get; set; }
        @AuraEnabled public String responseValue { get; set; }
        @AuraEnabled public String applicationId { get; set; }
        
        
        public QuestionWrapper() {}

        // Constructor
        public QuestionWrapper(
            Id questionId,
            String questionText,
            String responseOptions,
            String responseType,
            String grouping,
            Id responseId,
            String responseValue,
            Boolean isRequired,
            Id applicationId
        ) {
            this.questionId = questionId;
            this.questionText = questionText;
            this.responseOptions = responseOptions;
            this.responseType = responseType;
            this.grouping = grouping;
            this.responseId = responseId;
            this.responseValue = responseValue;
            this.isRequired = isRequired;
            this.applicationId=applicationId;
        }
    }
}