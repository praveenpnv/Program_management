public class ValidateFieldsRequest {
    @AuraEnabled
    @InvocableVariable(required=true)
    public String objectApiName;

    @AuraEnabled
    @InvocableVariable(required=true)
    public List<SObject> records;

    // Optional: Add a default constructor
    public ValidateFieldsRequest() {}
}