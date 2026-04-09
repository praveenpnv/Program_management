@isTest(isParallel = false)
public class CPTimeFlowPresalesTest {
    
    @isTest
    static void test_ESBSFSubmitOpportunity (){
        
        // Generate a unique username
        String uniqueUsername87 = 'testuser4' + DateTime.now().getTime() + '@example.com';        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser87 = new User(
            Username = uniqueUsername87,
            Email = 'testuser4@example.com',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser87;
 System.runAs(testUser87) {
              // Create test data for custom settings
        Api_Url__c esbFR = new Api_Url__c(
            Name = 'ESB_FR',
            Url__c = 'https://esb-fr.test.com',
            Key__c = 'testKeyFR'
        );
        insert esbFR;

        Api_Url__c esbBE = new Api_Url__c(
            Name = 'ESB_BE',
            Url__c = 'https://esb-be.test.com',
            Key__c = 'testKeyBE'
        );
        insert esbBE;
     
        // Create test account
        Id clientId = RD1TestDataFactory.getRecordTypeId('Account', 'Client');
        Account objAccount = new Account(
            Name = 'Test CPTimeFlow',
            AUSY_Changepoint_ID__c = 'CHPID525',
            BillingStreet = 'Test Street',
            BillingCity = 'Bangalore',
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            BillingPostalCode = '12345',
            BH_VAT_Number__c = '29GGGGG1314R9Z9',
            RecordTypeId=clientId
        );
        insert objAccount;
        System.assertEquals(objAccount.Name, 'Test CPTimeFlow');
        
        // Create test opportunity
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'Test Opportunity2';
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.StageName = 'Prospecting';
     	objOpportunity.Type = 'New Business';
        objOpportunity.CloseDate = System.Today() + 3;
        objOpportunity.CurrencyIsoCode = 'EUR';
        objOpportunity.LeadSource = 'Other';
        objOpportunity.OwnerId = testUser87.Id; // Set OwnerId to the test user
        
        insert objOpportunity;
        System.assertEquals(objOpportunity.Name, 'Test Opportunity2');
        
        // Query the inserted opportunity
        List<Opportunity> result = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity2'];
        
        // Prepare the list of AusyESBCallable
        List<AusyESBCallable> oppties = new List<AusyESBCallable>();
        for (Integer i = 0; i < 4; i++) {
            AusyESBCallable o = new AusyESBCallable();
            o.opptyID = result[0].Id;
            oppties.add(o);
        }
        
        // Call the method and assert the results
        Test.startTest();
        List<ID> jobIDs = CPTimeFlowPresales.ESBSFSubmitOpportunity(oppties);
        Test.stopTest();
        
        System.assertEquals(4, jobIDs.size());
 }
    }
}