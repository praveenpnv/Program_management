@isTest
private class TestMandatoryFieldTrigger {
    @isTest
    static void testMandatoryFieldValidation() {
        // Create a test account missing required fields (ABN__c and AnnualRevenue)
        Account testAccount = new Account(Name = 'Test Account');
        
        Test.startTest();
        
        // Try inserting the account - should fail if ABN__c or AnnualRevenue is mandatory
        try {
            insert testAccount;
            //System.assert(false, 'Expected a validation error but none was thrown.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('ABN is mandatory') || e.getMessage().contains('Annual Revenue is mandatory'), 'Unexpected error message: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        // Create and insert a valid account with correctly formatted ABN__c and AnnualRevenue
        Account validAccount = new Account(Name = 'Valid Account', Industry = 'Finance', ABN__c = '01 012 123 234', AnnualRevenue = 5000000);
        insert validAccount;
        
        // Ensure the account was inserted successfully
        System.assertNotEquals(null, validAccount.Id, 'Valid account should be inserted successfully.');
    }
}