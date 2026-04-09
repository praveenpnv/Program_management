public class ValidateFieldsResult {
        @AuraEnabled
        @InvocableVariable
        public List<RecordFieldError> recordFieldErrors;

        public ValidateFieldsResult(List<RecordFieldError> recordFieldErrors) {
            this.recordFieldErrors = recordFieldErrors;
        }
    }