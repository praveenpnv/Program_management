@isTest
public class torcRD1IntegrationTest 
{
    public static torc_user__c getTorcUserNoInsert(string userName, string sfdcExternalId, string email, string userType)
    {
        Torc_user__c tu= new Torc_user__c(updater__c='sumit',
                                         name=userName,
                                         given_Name__c=userName,
                                         Family_Name__c=userName,
                                         userName__c = userName, 
                                         external_Id__c=userName,
                                         sfdcExternalId__c=sfdcExternalId,
                                         email__c=email,
                                         CountryName__c='United States',
                                         UserType__c=userType,
                                         status__c='ACTIVE',
                                         linkedin__c='sumitmishra',
                                         noticePeriod__c=30,
                                         WhatsappAllowed__c=true,
                                         Phone__c='+919829113328',
                                         ratePerHour__c=10,
                                         salary__c=1000,
                                         overallExperience__c =5);        
        return tu;                                         
    }
    public static torc_user__c getTorcUser(string userName, string sfdcExternalId, string email, string userType)
    {
        Torc_user__c tu=getTorcUserNoInsert(userName, sfdcExternalId, email, userType);   
        insert tu;    
        return tu;                                         
    }
    public static contact getContact(Id candidateAccountId, id CandidateRecordTypeId, string userName,string email,string torc_id,integer count)
    {
        list<Contact> lst=new list<Contact>();
        for(integer i=0;i<count;i++)
        {
        string eml = i==0?email:email+i.toString();
        contact c=new contact(Accountid=candidateAccountId,
                              LastName=userName,
                              Firstname=userName, 
                              email=email,
                              recordTypeId=CandidateRecordTypeId,
                              torc_Id__c=torc_id,
                              TR1__Candidate_Status__c ='New',
                              TR1__Notice_Period__c ='30',
                              Years_of_experience__c=20,
                              Availability_date__c=date.today(),
                              WhatsApp_Allowed__c=true,
                              phone='+919829113328',
                              TR1__Desired_Hourly__c=10,
                              TR1__Desired_Salary__c=100,
                              mailingCity='Jaipur',
                              mailingCountry='India',
                              mailingState='rajasthan',
                              TR1__LinkedIn_ProfileUrl__c='https://www.linkedin.com/in/sumitmishra'
                              );
        lst.add(c);
        }                              
        insert lst;
        return lst[0];                              
    }
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
    private static void testUser1() 
    {
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();
        Torc_user__c tu1=getTorcUser('tutesttu_1',null,'tutesttu_1@gmail.com','FREELANCER');
        Torc_user__c tu2=getTorcUser('tutesttu_2',null,currentUser.email,'CUSTOMER');
        test.stoptest();
    } 
    @isTest
    private static void testUserCandidate() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        
        Torc_user__c tuCust= getTorcUser('tucustomertu2',null,currentUser.email,'CUSTOMER');
        Torc_user__c tu= getTorcUserNoInsert('tutesttu_1',null,'sumit@rdINS.com','FREELANCER');
        tu.creator__c='tucustomertu2';
        insert tu;
        
        torcRD1Integration.skipTorcPlatformUpdateUSER=false;
        torcRD1Integration.skipTorcPlatformUpdateJOB =false;
        torcRD1Integration.skipTorcPlatformUpdateForTheseJOBs.clear();
        tu.sfdcExternalid__c = c.id;
        tu.given_Name__c = tu.given_Name__c+'1';
        tu.resumeLocation__c='sumit.doc';
        update tu;
        torcRD1Integration.skipTorcPlatformUpdateUSER=false;
        torcRD1Integration.skipTorcPlatformUpdateJOB =false;
        torcRD1Integration.skipTorcPlatformUpdateForTheseJOBs.clear();
        Torc_Note__c tn= new Torc_Note__c(userid__c=tu.external_id__c,content__c='testContent',external_id__c='notest1ExtId',updater__c='Sumit');
        insert tn;
        
        
        torcRD1Integration.skipTorcPlatformUpdateUSER=false;
        torcRD1Integration.skipTorcPlatformUpdateJOB =false;
        torcRD1Integration.skipTorcPlatformUpdateForTheseJOBs.clear();
        string loc = '{"recordId":"'+c.id+'","source":"Record"}';
        id recId = [SELECT Id from RecordType Where DeveloperName='Power_Notes'].Id;
        string s= torcRD1Integration.getrecordidFromTR1Location(loc);
        task tsk=new task(Subject='Notes', Torc_Id__c=NULL,recordTypeId=recId, TR1__Location__c=loc,description='ssdd');
        insert tsk;
        
        test.stopTest();
    }
    @isTest
    private static void testUser2() 
    {
        Torc_user__c tu= getTorcUser('tutesttu_1',null,'sumit@rdINS.com','FREELANCER');
        tu.userType__c = 'CUSTOMER';
        update tu;
    }
    // Mock HTTP Response Generator
    public class MockHttpResponseGenerator implements HttpCalloutMock 
    {
        public HTTPResponse respond(HTTPRequest req) 
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            res.setBodyAsBlob(Blob.valueOf('%PDF-1.4 Fake PDF content here'));
            res.setStatusCode(200);
            return res;
        }
    }
    
    
    
    
    @isTest
    private static void testUserCandidate2() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,3);
        ATSExtractedCandidateSkill__c rec=new ATSExtractedCandidateSkill__c(Contact_Candidate__c = c.id,Extracted_Skill__c='Java', Category__c ='IT_skill');
        insert rec;
        test.stopTest();
    }
    @isTest
    private static void testJob() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        id jobAppRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Application_V2__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();
        Torc_user__c tu2=getTorcUser('tutesttu_2',null,currentUser.email,'CUSTOMER');
        
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer'
                                       ,Torc_Location_Type__c='Region/Country');
        job.Primary_Timezone__c='Pacific/Midway';
        
        job.timeOverlap__c='No restriction';
        job.Remote_Work_Mode__c='Partial';
        job.Workregime__c='100%';
        job.Responsible_Recruiter__c=currentUser.id;                                 
        insert job;                                 
        
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,3);
        Tr1__Application_V2__c app=new Tr1__Application_V2__c(TR1__Applicant__c=c.id, TR1__Job__c=job.id,Source__c = 'Torc Match',RecordTypeId = jobAppRecordTypeId,TR1__Stage__c='Application',Status__c='Submitted');
        app.Torc_Id__c = 'test';
        app.Torc_Application_id__c = 'test';
        insert app;
         
              
        test.stoptest();
    }
    @isTest
    private static void testJob2() 
    {
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer',Torc_Id__c='sssuuummm');
        insert job;                                       
        test.stoptest();
    }  
    @isTest
    private static void testMatch() 
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
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        Torc_user__c tu= getTorcUser('tutesttu_1',null,'sumit@rdINS.com','FREELANCER');
        Torc_Job_Opportunity__c tJob=new Torc_Job_Opportunity__c(Name='tJob',  external_id__c='testJOBID',Torc_Job_Type__c=tjt.id, jobTypeId__c='jobTypeId');
        insert tJob;  
                                  
        //Torc_match__c tm= new Torc_match__c(updater__c='sumitMishra', Torc_Job_Opportunity__c =tJob.id, external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID', Torc_User_Ref__c=tu.id, userid__c='tutesttu_1', status__c='MATCHED');
        Torc_match_Shadow__c tm= new Torc_match_Shadow__c(updater__c='sumitMishra',  external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID',  userid__c='tutesttu_1', status__c='MATCHED');
        insert tm;
        tm.Delete_From_Platform__c=true;
        update tm;
        
        Tr1__Application_V2__c app=new Tr1__Application_V2__c(TR1__Applicant__c=c.id, TR1__Job__c=job.id,Source__c = 'Torc Match',RecordTypeId = jobAppRecordTypeId,TR1__Stage__c='Application',Status__c='Submitted');
        app.Torc_Id__c = 'test';
        app.Torc_Application_id__c = 'test';
        insert app;
        torcRD1Integration.skipTorcPlatformUpdateMATCH = false;
        app.TR1__Stage__c = 'Submittal';
        update app;
        Torc_API_Call__c call1=new Torc_API_Call__c(type__c='Match',Application__c=app.id,Operation__c='INSERT',Body__c = JSON.serialize(app),createdDate=datetime.now().addminutes(-1));
        insert call1;
        List<Torc_API_Call__c> lstRecord=new List<Torc_API_Call__c>();
        lstRecord.add(call1);
        torcRD1Integrationbatch.runProcessNow(lstRecord);
        
        test.stoptest();
        TR1__Master_Skill__c  tms = new TR1__Master_Skill__c(TR1__Skill_Code__c = 'torctest', TR1__Type__c='IT', TR1__Status__c='Active', TR1__Master_Skill_Name__c='.Nettester1');
        insert tms;
        
        insert new TR1__Skills__c(TR1__Job__c=job.id, TR1__Master_Skill__c=tms.id);
        
        
        
    }  
    
    @isTest
    private static void testJobMatchController() 
    {
        Torc_Job_Type__c tjt=new Torc_Job_Type__c(external_id__c='jobTypeId',Name='AI Engineer');
        insert tjt;
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
        Torc_Job_Opportunity__c tJob=new Torc_Job_Opportunity__c(Name='tJob',  external_id__c='testJOBID',Torc_Job_Type__c=tjt.id, jobTypeId__c='jobTypeId');
        insert tJob;   
        
        
        
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        
        Torc_user__c tuCUST= getTorcUserNoInsert('tucustomer',null,currentuser.email,'CUSTOMER');
        insert tuCUST;
        Torc_user__c tu= getTorcUserNoInsert('tutesttu_1',null,'sumit@rdINS.com','FREELANCER');
        insert tu;
        job.Torc_Id__c='testJOBID';
        update job;     
                            
        //Torc_match__c tm= new Torc_match__c(updater__c='sumitMishra', Torc_Job_Opportunity__c =tJob.id, external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID', Torc_User_Ref__c=tu.id, userid__c='tutesttu_1', status__c='PRESHORTLISTED');
        Torc_match_Shadow__c tm= new Torc_match_Shadow__c(updater__c='sumitMishra',  external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID',  userid__c='tutesttu_1', status__c='PRESHORTLISTED');
        insert tm;
        JobMatchController.getTorcJobId(job.id);
        JobMatchController.getMatches(job.id);
        JobMatchController.getOrgId();
        JobMatchController.getSearchURL();
        JobMatchController.setSyncTime(job.id);
        JobMatchController.setSyncTime(c.id);
        JobMatchController.getJobCreatedDate(job.id); 
        test.stoptest();
    } 
    @isTest
    private static void testJobMatchController1() 
    {
        Torc_Job_Type__c tjt=new Torc_Job_Type__c(external_id__c='jobTypeId',Name='AI Engineer');
        insert tjt;
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
        Torc_Job_Opportunity__c tJob=new Torc_Job_Opportunity__c(Name='tJob',  external_id__c='testJOBID',Torc_Job_Type__c=tjt.id, jobTypeId__c='jobTypeId');
        insert tJob;   
        
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        
        Torc_user__c tuCUST= getTorcUserNoInsert('tucustomer',null,currentuser.email,'CUSTOMER');
        insert tuCUST;
        Torc_user__c tu= getTorcUserNoInsert('tutesttu_1',null,'sumit@rdINS.com','FREELANCER');
        insert tu;
        job.Torc_Id__c='testJOBID';
        update job;     
        system.debug('======STARTING TORC MATCH TEST==');                    
        //Torc_match__c tm= new Torc_match__c(updater__c='sumitMishra', Torc_Job_Opportunity__c =tJob.id, external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID', Torc_User_Ref__c=tu.id, userid__c='tutesttu_1', status__c='MATCHED', matcher__c='tucustomer');
        torcRD1Integration.skipTorcPlatformUpdateMATCH = false;
        Torc_match_Shadow__c tm= new Torc_match_Shadow__c(updater__c='sumitMishra',applicationid__c='User#tutesttu_1',  external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID',  userid__c='tutesttu_1', status__c='MATCHED', matcher__c='tucustomer');
        insert tm;
        torcRD1Integration.skipTorcPlatformUpdateMATCH = false;
        Tr1__Application_V2__c tr=[Select id, TR1__Stage__c from Tr1__Application_V2__c where TR1__Applicant__c=:c.id LIMIT 1];
        tr.TR1__Stage__c='Internal Interview';
        update tr;
        test.stoptest();
    } 
    @isTest
    private static void testResume() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        String dummyPdfContent = '%PDF-1.4\n%Fake PDF content here...';
        Blob pdfBlob = Blob.valueOf(dummyPdfContent);
        ContentVersion cv = new ContentVersion(FirstPublishLocationId = c.id,Resume_From_Torc__c=false);
        cv.is_resume__c = true;
        cv.File_Category__c = 'Resume';
        cv.Title = 'test.pdf';
        cv.PathOnClient = '/test.pdf';
        cv.VersionData = pdfBlob;
        insert cv;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        test.startTest();
        torcRD1Integrationbatch.uploadresume('www.yahoo.com', 'abc.pdf',c.id); 
        test.stoptest();
        
        cv = new ContentVersion(FirstPublishLocationId = userinfo.getuserId(),Resume_From_Torc__c=false);
        cv.is_resume__c = true;
        cv.File_Category__c = 'Resume';
        cv.Title = 'test.pdf';
        cv.PathOnClient = '/test.pdf';
        cv.VersionData = pdfBlob;
        insert cv;
        cv = [Select id,contentDocumentId from ContentVersion where id=:cv.id];
        ContentDocumentLink cvl=new ContentDocumentLink(LinkedEntityId=c.id, ContentDocumentId=cv.contentDocumentId);
        insert cvl;
    } 
    private static void testResumeWebApply() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com','tutesttu_1',1);
        String dummyPdfContent = '%PDF-1.4\n%Fake PDF content here...';
        Blob pdfBlob = Blob.valueOf(dummyPdfContent);
        ContentVersion cv = new ContentVersion(FirstPublishLocationId = userInfo.getuserId(),Resume_From_Torc__c=false);
        cv.is_resume__c = true;
        cv.File_Category__c = 'Resume';
        cv.Title = 'test.pdf';
        cv.PathOnClient = '/test.pdf';
        cv.VersionData = pdfBlob;
        insert cv;
         cv = [Select id,contentDocumentId from ContentVersion where id=:cv.id];
        ContentDocumentLink cl=new ContentDocumentLink(LinkedEntityId=c.id,ContentDocumentId =cv.contentDocumentId);
        insert cl;
    }  
    
    @isTest
    private static void testSkipcode()
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        string s='testUser1100';
        Contact c=new contact();
        c.FirstName=s;
        c.LastName=s;
        c.email='sumit+'+s+'@cloud2crowd.com';
        c.AccountId=candidateAccount;
        c.RecordTypeId = CandidateRecordTypeId;
        test.startTest();
        insert c;
        
        torcRD1Integration.skipTorcPlatformUpdateUSER = false;
        c=[Select id,FirstName from Contact where FirstName=:s];
        c.FirstName = c.FirstName+'-1';
        update c;
        test.stopTest();
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        
        TR1__Job__c job=new TR1__Job__c(TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId, Job_Type__c = 'Contract',
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer');
        insert job;                                       
        Torc_API_Call__c call1=new Torc_API_Call__c(type__c='Job',Job__c=job.id,Operation__c='INSERT',Body__c = JSON.serialize(job),createdDate=datetime.now().addminutes(-1));
        insert call1;
        Torc_API_Call__c call2=new Torc_API_Call__c(type__c='Job',Job__c=job.id,Operation__c='INSERT',Body__c = JSON.serialize(job));
        insert call2;
        List<Torc_API_Call__c> lstRecord=new List<Torc_API_Call__c>();
        lstRecord.add(call2);
        torcRD1Integrationbatch.runProcessNow(lstRecord);
        
    }
    @isTest
    private static void torcRD1IntegrationOnetimeBatch1()
    {
        torcRD1IntegrationOnetimeBatch.processSFDCContactreferencesetup();
    }
    @isTest
    private static void torcRD1IntegrationOnetimeBatch2()
    {
        torcRD1IntegrationOnetimeBatch.processCleanUpAPICallObject(1);
    }
    @isTest
    private static void torcRD1IntegrationOnetimeBatch3()
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        torcRD1IntegrationOnetimeBatch.processSFDCToTorc(1,null,null,1);
        test.Stoptest();
    }
    @isTest
    private static void torcRD1IntegrationOnetimeBatch4()
    {
        torcRD1IntegrationOnetimeBatch.processTorcToSFDC(1,null,null,1);
    }
    @isTest
    private static void testSkipCodeNew1() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        test.startTest();        
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer');
        job.Primary_Timezone__c='Pacific/Midway';
        
        job.timeOverlap__c='No restriction';
        job.Remote_Work_Mode__c='Partial';
        job.Workregime__c='100%';
        job.Responsible_Recruiter__c=currentUser.id;                                 
        insert job;                                         
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,3);
        Torc_API_Call__c rec=new Torc_API_Call__c(type__c='User',Contact__c=c.id,Operation__c='INSERT');
        rec.Body__c = JSON.serialize(c);
        List<Torc_API_Call__c>lstTorcAPICalls=new List<Torc_API_Call__c>();
        lstTorcAPICalls.add(rec);
        insert lstTorcAPICalls;
        List<id> lstI=new List<id>();
        lstI.add(rec.id);
        torcApiInvokeAction.notify(lstI);
        torcRD1Integrationbatch.runProcessNow(lstTorcAPICalls);
        lstTorcAPICalls=new List<Torc_API_Call__c>();
        rec=new Torc_API_Call__c(type__c='User',Contact__c=c.id,Operation__c='INSERT');
        rec.Body__c = JSON.serialize(c);
        lstTorcAPICalls.add(rec);
        insert lstTorcAPICalls;
        torcRD1Integrationbatch.runProcessNow(lstTorcAPICalls);
        test.stoptest();
    }
    
    @isTest
    private static void testCompleteJobSync() 
    {
        id CandidateRecordTypeId =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        id candidateAccount=[Select id from Account where name='Candidate Pool Account'].id;
        id jobRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Job__c'].id;
        id jobAppRecordTypeId =[Select ID from RecordType where DeveloperName = 'Consulting' and SobjectType='TR1__Application_V2__c'].id;
        Torc_Job_Type__c tjt=new Torc_Job_Type__c(external_id__c='jobTypeId',Name='AI Engineer');
        insert tjt;
        Account act=new Account(Name='testAccountMLPIntegration',Website='www.mlpIntegration.cas', Quickbooks_ID__c='191', Quickbooks_Customer__c='dsdf11');
        insert act;
        User currentUser = [Select id,userName,email from User where id=:Userinfo.getuserId()];
        Active_Trigger_Flow_VR__c atf= Active_Trigger_Flow_VR__c.getOrgDefaults();
        Torc_Rd1_Integration__c tr= Torc_Rd1_Integration__c.getInstance();
        tr.Sync_Enabled__c=false;
        upsert tr;
        
        TR1__Job__c job=new TR1__Job__c(Job_Type__c = 'Contract',TR1__Account__c=act.id, TR1__Job_Title__c='testjob1',recordtypeid=jobRecordTypeId,
                                       TR1__Status__c='Accepting Candidates',Torc_Job_Type__c='AI Engineer',Legacy_BH_Id__c='100',Responsible_Recruiter__c=currentUser.id);
        insert job;                                         
        Torc_Job_Opportunity__c tJob=new Torc_Job_Opportunity__c(Name='tJob',  external_id__c='testJOBID',Torc_Job_Type__c=tjt.id, jobTypeId__c='jobTypeId',externalJobId__c='100');
        insert tJob;          
        contact c=getContact(candidateAccount,CandidateRecordTypeId,'SumitM','sumit@rdINS.com',null,3);
        Torc_user__c tu= getTorcUser('tutesttu_1',null,'sumit@rdINS.com','FREELANCER');
        //Torc_match__c tm= new Torc_match__c(updater__c='sumitMishra', Torc_Job_Opportunity__c =tJob.id, external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID', Torc_User_Ref__c=tu.id, userid__c='tutesttu_1', status__c='MATCHED');
        Torc_match_Shadow__c tm= new Torc_match_Shadow__c(updater__c='sumitMishra',  external_id__c='User#tutesttu_1_testJOBID',jobOpportunityId__c='testJOBID',  userid__c='tutesttu_1', status__c='MATCHED');
        insert tm;
        Tr1__Application_V2__c app=new Tr1__Application_V2__c(TR1__Applicant__c=c.id, TR1__Job__c=job.id,Source__c = 'Torc Match',RecordTypeId = jobAppRecordTypeId,TR1__Stage__c='Application',Status__c='Submitted');
        insert app;
        tr.Sync_Enabled__c=true;
        upsert tr;
        insert new AWS_Sync__c(Use_Query__c=true, Name='Match', Table_Name__c='Match', Order__c=1);
        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(job);
        PageReference pageRef = Page.torcRd1SyncJob;
        Test.setCurrentPageReference(pageRef);
        torcRd1SyncJob controller = new torcRd1SyncJob(sc);
        controller.processNow(); 
        controller.currentStep=4;
        controller.processNow(); 
        for(List<Torc_API_Call__c>l:[Select id from Torc_API_Call__c])Delete l;
        controller.currentStep=4;
        controller.processNow(); 
        controller.currentStep=5;
        controller.processNow(); 
        for(List<Torc_API_Call__c>l:[Select id from Torc_API_Call__c])Delete l;
        controller.currentStep=6;
        controller.processNow(); 
        controller.currentStep=7;
        for(List<Torc_API_Call__c>l:[Select id from Torc_API_Call__c])Delete l;
        controller.processNow(); 
        for(List<Torc_API_Call__c>l:[Select id from Torc_API_Call__c])Delete l;
        controller.currentStep=10;
        controller.processNow();        
        test.stoptest();
    }
    @isTest
    private static void testUnnecessary() 
    {
        List<Torc_API_Call__c>t=new List<Torc_API_Call__c>();
        for(integer i=0;i<101;i++)
            t.add(new Torc_API_Call__c());
        insert t;
        list<id>l=new List<id>();
        for(Torc_API_Call__c t1:t)
            l.add(t1.id);
        try
        {    
        torcApiInvokeAction.notify (l);
        }
        catch(exception ex){}
    }
    @isTest
    private static void testTorcRD1Event() 
    {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/torcRD1Event';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('[{"eventID":"f319a6443b7fc0b9d3ea57a379dc4f6b","eventName":"MODIFY","eventVersion":"1.1","eventSource":"aws:dynamodb","awsRegion":"us-east-1","dynamodb":{"ApproximateCreationDateTime":1760374546,"Keys":{"id":{"S":"36eabf97-4e98-46b0-ba3b-a01bf5b7b7ca"}},"NewImage":{"creator":{"S":"com.opentorc.id.post_confirmation"},"additionalMarkup":{"N":"1"},"visibility":{"S":"FULL"},"__typename":{"S":"User"},"referrerCode":{"S":""},"given_name":{"S":"test"},"updater":{"S":"com.opentorc.id.post_confirmation"},"createdAt":{"S":"2025-10-13T16:55:35.889Z"},"identity_username":{"S":"testrenan123"},"agreedToMarketing":{"BOOL":true},"lastActivityDate":{"S":"2025-10-13T16:55:46.491Z"},"systemProcessName":{"S":"com.opentorc.id.user_activity"},"referralCode":{"S":"1E38bDhN"},"location":{"M":{}},"id":{"S":"36eabf97-4e98-46b0-ba3b-a01bf5b7b7ca"},"userType":{"S":"FREELANCER"},"family_name":{"S":"test"},"agreedToTerms":{"BOOL":true},"email":{"S":"dehic84821@lorkex.com"},"status":{"S":"ACTIVE"},"updatedAt":{"S":"2025-10-13T16:55:35.889Z"},"username":{"S":"testrenan123"},"cognitoGroups":{"L":[]}},"OldImage":null,"SequenceNumber":"6429235400004276663827544060","SizeBytes":1136,"StreamViewType":"NEW_AND_OLD_IMAGES"},"eventSourceARN":"arn:aws:dynamodb:us-east-1:741363590887:table/User-ahssmy3yy5dg3gwujmtemowjbm-develop/stream/2022-01-27T14:39:39.026"}]'); 
        RestContext.request = req;
        RestContext.response = new RestResponse();
        try
        {
        torcRD1Event.postEvent();
        }
        catch(exception ex)
        {
        }
    }
    
}