@isTest(isParallel = false)
public class TetrisOpportunityClosedWonTest {

    @isTest
    static void test_ESBSFSubmitOpportunity() {
        // Insert test custom setting data for ESB_FR and ESB_BE in System.runAs block
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Api_Url__c esbFr = new Api_Url__c(Name = 'ESB_FR', Key__c = 'FR', Url__c = 'https://esb-fr.example.com');
            Api_Url__c esbBe = new Api_Url__c(Name = 'ESB_BE', Key__c = 'BE', Url__c = 'https://esb-be.example.com');
            insert esbFr;
            insert esbBe;
        }

        // Create test Account
        Id clientId = RD1TestDataFactory.getRecordTypeId('Account', 'Client');
        
        Account testAccount345 = new Account(
            Name = 'Test Riz Account New',
            AUSY_Changepoint_ID__c = 'CHPID1234',
            BillingStreet = 'Test Street',
            BillingCity = 'Bangalore',
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            BillingPostalCode = '12345',
            BH_VAT_Number__c = '29GGGGG1314R9Z9',
            RecordTypeId=clientId
        );

        // Generate a unique username
        String uniqueUsername123 = 'testuser' + DateTime.now().getTime() + '@example.com';

        // Create a test User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser678 = new User(
            Username = uniqueUsername123,
            Email = 'testuser@example.com',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            Opco__c = 'France',
            LanguageLocaleKey = 'en_US'
        );

        // Insert the test User using System.runAs
        System.runAs(testUser678) {
            insert testAccount345;

            Opportunity objOpportunity = new Opportunity();
            objOpportunity.Name = 'Test Opportunity234';
            objOpportunity.Accountid = testAccount345.id;
            objOpportunity.OwnerId = testUser678.Id;
            objOpportunity.StageName = 'Prospecting';
            objOpportunity.Type = 'New Business';
            objOpportunity.CloseDate = system.Today() + 3;
            objOpportunity.CurrencyIsoCode = 'EUR';

            insert objOpportunity;

            List<Opportunity> result = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity234'];

            List<AusyESBCallable> oppties = new List<AusyESBCallable>();
            for (Integer i = 0; i < 4; i++) {
                AusyESBCallable o = new AusyESBCallable();
                o.opptyID = result[0].id;
                oppties.add(o);
            }

            Test.startTest();
            List<ID> jobIDs = TetrisOpportunityClosedWon.ESBSFSubmitOpportunity(oppties);
            Test.stopTest();

            System.assertEquals(4, jobIDs.size());
        }
    }
}