@isTest(seeallData =false)
public class candidateStatusChangeTest 
{
    @testSetup
    public static void T()
    {
        torcRD1IntegrationTest.T();
        Torc_Constants__c tc= Torc_Constants__c.getOrgDefaults();
        tc.Contact_Status_Automation__c=true;
        
        upsert tc;
    }
    @isTest
    private static void testcandidateStatusChange1() 
    {
        Torc_Job_Type__c tjt=new Torc_Job_Type__c(external_id__c='jobTypeId',Name='AI Engineer');
        insert tjt;
        id jobAppRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Application_V2__c'].id;
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer',Torc_Id__c='testJOBID');
        insert job;  
        contact c= torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        c.TR1__Candidate_Status__c ='New';
        c.Availability_date__c = null;
        update c;
        system.debug([Select id, TR1__Candidate_Status__c FROM Contact where id=:c.id]);
        Tr1__Application_V2__c app=new Tr1__Application_V2__c(TR1__Applicant__c=c.id, TR1__Job__c=job.id,Source__c = 'Torc Match',RecordTypeId = jobAppRecordTypeId,TR1__Stage__c='Application',Status__c='Submitted');
        insert app;
        system.debug([Select id, TR1__Candidate_Status__c FROM Contact where id=:c.id]);
        c.TR1__Candidate_Status__c ='New';
        update c;
        system.debug([Select id, TR1__Candidate_Status__c FROM Contact where id=:c.id]);
        
        app.TR1__Stage__c = 'Send Out';
        app.Substage__c ='Completed';
        update app;
        system.debug([Select id, TR1__Candidate_Status__c  FROM Contact  where id=:c.id]);
        id recTypeId=[SELECT Id from recordtype where DeveloperName='External_Interview' and SobjectType  = 'TR1__Send_Out_Schedule_V2__c'].id;
    
        TR1__Send_Out_Schedule_V2__c interview= new TR1__Send_Out_Schedule_V2__c(recordTypeId=recTypeId,TR1__Interviewee__c=c.id,TR1__Date__c=date.today().adddays(5), TR1__Application_V2__c=app.id);
        insert interview;
        test.stopTest();
    }
    @isTest
    private static void testcandidateStatusChange2() 
    {
        Torc_Job_Type__c tjt=new Torc_Job_Type__c(external_id__c='jobTypeId',Name='AI Engineer');
        insert tjt;
        id jobAppRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Application_V2__c'].id;
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        id placementRecordType =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Closing_Report__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer',Torc_Id__c='testJOBID');
        insert job;  
        contact c= torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        c.TR1__Candidate_Status__c ='New';
        c.Availability_date__c = null;
        update c;
        Tr1__Application_V2__c app=new Tr1__Application_V2__c(TR1__Applicant__c=c.id, TR1__Job__c=job.id,Source__c = 'Torc Match',RecordTypeId = jobAppRecordTypeId,TR1__Stage__c='Application',Status__c='Submitted');
        insert app;
        c.TR1__Candidate_Status__c ='New';
        c.Availability_date__c = null;
        update c;
        TR1__Closing_Report__c placement = new TR1__Closing_Report__c(TR1__Account__c=act.id, TR1__Job__c=job.id,  TR1__Start_Date__c=date.today(),TR1__End_Date__c=date.today().adddays(100),recordTypeid=placementRecordType,TR1__Bill_Rate__c=100,TR1__Pay_Rate__c=50, TR1__Job_Percentage__c=0.5, TR1__Candidate_Percentage__c =0.5,User_Opco__c='US');
        insert placement;
        placement.Placement_Type__c = 'Permanent';
        placement.Status_US__c ='Ready for Back Office';
        placement.TR1__Person_Placed__c=c.id;
        update placement;
        
        placement = new TR1__Closing_Report__c(TR1__Account__c=act.id, TR1__Job__c=job.id,  TR1__Start_Date__c=date.today(),TR1__End_Date__c=date.today().adddays(100),recordTypeid=placementRecordType,TR1__Bill_Rate__c=100,TR1__Pay_Rate__c=50, TR1__Job_Percentage__c=0.5, TR1__Candidate_Percentage__c =0.5,User_Opco__c='US');
        insert placement;
        placement.Placement_Type__c = 'Solutions';
        placement.Status_US__c ='Ready for Back Office';
        placement.TR1__Person_Placed__c=c.id;
        update placement;
        
        placement = new TR1__Closing_Report__c(TR1__Account__c=act.id, TR1__Job__c=job.id,  TR1__Start_Date__c=date.today(),TR1__End_Date__c=date.today().adddays(100),recordTypeid=placementRecordType,TR1__Bill_Rate__c=100,TR1__Pay_Rate__c=50, TR1__Job_Percentage__c=0.5, TR1__Candidate_Percentage__c =0.5,User_Opco__c='US');
        insert placement;
        placement.Placement_Type__c = 'Contract';
        placement.Status_US__c ='Ready for Back Office';
        placement.TR1__Person_Placed__c=c.id;
        update placement;
        
        placement.Status_US__c ='Closed';
        update placement;
        test.stopTest();
    }
    @isTest
    private static void testcandidateStatusChange3() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        test.startTest();
        contact c= torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        c.TR1__Candidate_Status__c ='New';
        update c;
        id recId = [SELECT Id from RecordType Where DeveloperName='Power_Notes'].Id;
        string loc = '{"recordId":"'+c.id+'","source":"Record"}';
        task tsk=new task(Subject='Notes', WhoId=c.id,recordTypeId=recId, TR1__Location__c=loc,description='ssdd', TR1__Original_Power_Note__c=true);
        tsk.Sub_Action__c =  'Candidate Actions: Recruiter Phone Screen';
        insert tsk;
        
        test.stopTest();
    }
    @isTest
    private static void testcandidateStatusChange4() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        test.startTest();
        contact c1= torcRD1IntegrationTest.getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        c1.TR1__Candidate_Status__c ='Interviewing';
        c1.Latest_Client_interview_Date__c = date.today().adddays(-15);
        update c1;
        candidateStatusChangeHandleScheduler sc=new candidateStatusChangeHandleScheduler();
        sc.execute(null);
        
        test.stopTest();
    }
}