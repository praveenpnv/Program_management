/**
 * @File Name: VMSJobOpportunityHandlerTest.cls
 * @Description: Unit tests for VMSJobOpportunityHandler
 * @Author: Rizwan Ahmed
 * @Created On: Jun 13, 2025
 * @Modified On: Jul 14, 2025
 */
@isTest
public class VMSJobOpportunityHandlerTest {

    @isTest
    static void testVMSOpportunityIsCreated() {
        // Step 1: Create test user
        String username = 'vmsuser' + DateTime.now().getTime();
        User testUser = RD1TestDataFactory.createUser(username, 'VMS', 'US');
        insert testUser;

       System.runAs(testUser) {
        insert new VMS_Opportunity_Creation_Setting__c(
            SetupOwnerId = testUser.Id,   // use runAs user Id
            Is_Enabled__c = true
        );
            Id clientId = RD1TestDataFactory.getRecordTypeId('Account', 'Client');
           Account testAccount = new Account(
                Name = 'Test Client Account',
                RecordTypeId = clientId
            );
            insert testAccount;
        //Account testAccount = RD1TestDataFactory.createTestAccount();

        TR1__Job__c job = RD1TestDataFactory.createVMSJob(testAccount.Id, 'Consulting');
    
        Test.startTest();
        // explicitly call if trigger missing
        VMSJobOpportunityHandler.handle(new List<TR1__Job__c>{ job });
        Test.stopTest();
    
        List<Opportunity> opps = [
            SELECT Id, AccountId FROM Opportunity WHERE AccountId = :testAccount.Id
        ];
        System.assertEquals(1, opps.size(), 'One Opportunity should be created');
      }
    }
}