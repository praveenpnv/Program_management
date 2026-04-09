public class RecordFieldError {
        @AuraEnabled
        @InvocableVariable
        public Id recordId;
        @AuraEnabled
        @InvocableVariable
        public String fieldName;
        @AuraEnabled
        @InvocableVariable
        public String errorMessage;

        public RecordFieldError(Id recordId, String fieldName, String errorMessage) {
            this.recordId = recordId;
            this.fieldName = fieldName;
            this.errorMessage = errorMessage;
        }
    }