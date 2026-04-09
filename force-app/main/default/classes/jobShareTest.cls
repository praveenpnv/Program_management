@isTest(seeallData=false)
public class jobShareTest 
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
    public static void test1() 
    {
        id jobAppRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Application_V2__c'].id;
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer',Torc_Id__c='testJOBID',User_Opco__c='US');
        job.Job_Share__c='GDC India';
        insert job;  
        
        contact c=torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        update new contact(id=c.id,user_Opco__c='India',Other_Opco_To_Share__c=';Pakistan;');        

        
        List<recordtype> lstRecordtypes = [SELECT Id, Name, DeveloperName,SobjectType, IsActive  from recordType 
                                                    Where sObjectType in ('TR1__Application_V2__c')];            
        TR1__Application_V2__c ap=new TR1__Application_V2__c(TR1__Applicant__c=c.id, TR1__Job__c=job.id);
        ap.Source__c='Torc Match';
        ap.Status__c='Submitted';
        for(recordType rt:lstRecordtypes)
            if(rt.DeveloperName=='Consulting')
                ap.RecordTypeId = rt.id;
        insert ap;
    }
}