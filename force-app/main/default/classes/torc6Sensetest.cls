@isTest
public class torc6Sensetest
{
    @isTest
    private static void test1() 
    {
        Account act = testUtils.getNewAccount();
        Test.startTest();
        List<user> lu=[Select Id,email from user Where IsActive=True and Profile.Name='System Administrator' LIMIT 2];
        Account a=[Select Id,OwnerId,X6sense_Created_By__c from Account LIMIT 1];
        a.X6sense_Created_By__c = lu[0].email;
        update a;
        a.X6sense_Created_By__c = lu[1].email;
        update a;
        Test.stopTest();
    }
    @isTest
    private static void test2() 
    {
        List<user> lu=[Select Id,email from user Where IsActive=True and Profile.Name='System Administrator' LIMIT 2];
        Contact c = new Contact(LastName = 'ABC');
        insert c;

        Test.startTest();
        Contact a=[Select Id,OwnerId,X6sense_Created_By__c from Contact LIMIT 1];
        a.X6sense_Created_By__c = lu[0].email;
        update a;
        a.X6sense_Created_By__c = lu[1].email;
        update a;
        Test.stopTest();
    }
    @isTest
    private static void test3() 
    {
        Lead lead = new Lead(LastName = 'ABC',Company = 'DEF');
        insert lead;
        
        List<user> lu=[Select Id,email from user Where IsActive=True and Profile.Name='System Administrator' LIMIT 2];
        Test.startTest();
        Lead a=[Select Id,OwnerId,X6sense_Created_By__c from Lead LIMIT 1];
        a.X6sense_Created_By__c = lu[0].email;
        update a;
        a.X6sense_Created_By__c = lu[1].email;
        update a;
        Test.stopTest();
    }
}