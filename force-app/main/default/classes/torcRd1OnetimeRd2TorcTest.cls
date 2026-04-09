@isTest
public class torcRd1OnetimeRd2TorcTest 
{
    @testSetup
    public static void T()
    {
        if([Select ID from Account where Name = 'Candidate Pool Account'].size()==0)
        {
            Account act=new Account(Name='Candidate Pool Account',Website='www.candidatePoolTest.cas', Quickbooks_ID__c='19', Quickbooks_Customer__c='dsdf');
            insert act;
        }    
        testUtils.setupRd1ToRorcIntegrationCustomSettings(false);
    }
    @isTest
    private static void testUserCandidate() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        contact c= torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,1);
        test.startTest();
        torcRd1OnetimeRd2Torc.Process('Select id from Contact LIMIT 1',1,1);
        test.stopTest();
    }
    @isTest
    private static void testUserControler() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        contact c= torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,1);
        test.startTest();
        torcRd1OnetimeRd2TorcController r=new torcRd1OnetimeRd2TorcController();
        r.soqlQuery = 'Select id from Contact limit 2';
        r.startProcess() ;
        r.poll() ;
        r.getRemainingCount() ;
        r.getPercentDone();
        test.stopTest();
    }
}