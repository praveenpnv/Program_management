@isTest (SeeallData=false)
private class QuestionnaireTest 
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData('QUESTION');
    }
    @isTest
    private static void test1() 
    {        
        Test.startTest();
        Torc_User__c tu=[Select id,email__c from Torc_user__c LIMIT 1];
        PageReference pageRef = Page.Questionnaire;
        Test.setCurrentPageReference(pageRef);
        Questionnaire aCls = new Questionnaire();
        aCls.showNONUSBased();
        aCls.rec.Full_Name__c = 'Sumit Mishra';
        aCls.rec.Email__c = 'sumitmishra041979@gmail.com';
        aCls.rec.Business_Name__c = 'Cloud2Crowd';
        aCls.rec.Form_Of_Business__c = 'Other';
        aCls.rec.Client_Count__c = '0 or 1';
        aCls.rec.Worked_As_Employee__c = 'No';
        aCls.rec.Employeement_Detail__c = '';
        aCls.marketServicelst.options[0].chk=true;
        aCls.investmentlst.options[0].chk=true;
        aCls.rec.completed_all_required_registrations__c = 'Yes';
        aCls.rec.business_registration_number__c = 'G000100000010001';
        aCls.rec.Agree_to_terms__c = TRUE;
        aCls.rec.Country__c = 'India';
        aCls.rec.Other_Market_Your_Service__c = '';
        aCls.rec.Document_Upload__c = '';
        aCls.rec.Other_Investment__c = '';
        aCls.rec.Initiate_Approval_Process__c = FALSE;
        aCls.rec.Other_Form_of_Business__c = 'Test';
        aCls.rec.Signature__c = '';
        aCls.rec.State_of_residence__c = '';
        aCls.rec.State_of_Business__c = '';
        aCls.rec.Employees_Contractor_Count__c = '';
        aCls.rec.Insurance_requirement__c = '';
        
        aCls.filename1='abc.pdf';
        aCls.filename2='abc.pdf';
        aCls.uploadedFile1 = Blob.valueOf('This is dummy content');
        aCls.uploadedFile2 = Blob.valueOf('This is dummy content');
        
        aCls.next();
        aCls.Save();
        aCls.previous();
        
    }
    @isTest
    private static void test2() 
    {        
        Test.startTest();
        Torc_User__c tu=[Select id,email__c from Torc_user__c LIMIT 1];
        PageReference pageRef = Page.Questionnaire;
        Test.setCurrentPageReference(pageRef);
        Questionnaire aCls = new Questionnaire();
        aCls.showUSBased();
        aCls.rec.Full_Name__c = 'Sumit Mishra';
        aCls.rec.Email__c = 'sumitmishra041979@gmail.com';
        aCls.rec.Business_Name__c = 'Cloud2Crowd';
        aCls.rec.Form_Of_Business__c = 'Other';
        aCls.rec.Client_Count__c = '0 or 1';
        aCls.rec.Worked_As_Employee__c = 'No';
        aCls.rec.Employeement_Detail__c = '';
        aCls.marketServicelst.options[0].chk=true;
        aCls.investmentlst.options[0].chk=true;
        aCls.rec.completed_all_required_registrations__c = 'Yes';
        aCls.rec.business_registration_number__c = 'G000100000010001';
        aCls.rec.Agree_to_terms__c = TRUE;
        aCls.rec.Other_Market_Your_Service__c = '';
        aCls.rec.Document_Upload__c = '';
        aCls.rec.Other_Investment__c = '';
        aCls.rec.Initiate_Approval_Process__c = FALSE;
        aCls.rec.Other_Form_of_Business__c = 'Test';
        aCls.rec.Signature__c = '';
        aCls.rec.State_of_residence__c = 'Boston';
        aCls.rec.State_of_Business__c = 'new york';
        //aCls.rec.Employees_Contractor_Count__c = '';
        //aCls.rec.Insurance_requirement__c = '';
        aCls.Save();
    }
    @isTest
    private static void test3() 
    {        
        Test.startTest();
        PageReference pageRef = Page.Questionnaire;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('type','US');
        Questionnaire aCls = new Questionnaire();
    }
    @isTest
    private static void test4() 
    {        
        Test.startTest();
        Torc_Match__c tm=[Select ID,Torc_Job_Opportunity__c, Status__c from Torc_Match__c where status__c !='ACCEPTED' and torc_User_ref__c!=NULL LIMIT 1];
        Opportunity opp=[Select id,Job_Opportunity__c from Opportunity Where Torc_Opportunity__c=TRUE and IsWON=TRUE Order By closeDate DESC LIMIT 1];
        opp.Job_Opportunity__c = tm.Torc_Job_Opportunity__c;
        update opp;
        tm.Status__c='ACCEPTED';
        update tm;
    }
    @isTest
    private static void test5() 
    {        
        Freelancer_Questionnaire__c rec=new Freelancer_Questionnaire__c();
        rec.Full_Name__c = 'Sumit Mishra';
        rec.Email__c = 'sumitmishra041979@gmail.com';
        rec.Business_Name__c = 'Cloud2Crowd';
        rec.Form_Of_Business__c = 'Other';
        rec.Client_Count__c = '0 or 1';
        rec.Worked_As_Employee__c = 'No';
        rec.Employeement_Detail__c = '';
        rec.completed_all_required_registrations__c = 'Yes';
        rec.business_registration_number__c = 'G000100000010001';
        rec.Agree_to_terms__c = TRUE;
        rec.Other_Market_Your_Service__c = '';
        rec.Document_Upload__c = '';
        rec.Other_Investment__c = '';
        rec.Initiate_Approval_Process__c = FALSE;
        rec.Other_Form_of_Business__c = 'Test';
        rec.Signature__c = '';
        rec.State_of_residence__c = 'Boston';
        rec.State_of_Business__c = 'new york';
        rec.approval_status__c='Pending';
        ApexPages.StandardController sc = new ApexPages.StandardController(rec);
        PageReference pageRef = Page.approveRejectRequest;
        Test.setCurrentPageReference(pageRef);
        approveRejectRequest apx = new approveRejectRequest(sc);
        apx.launch();
        apx.test1();
        
    }        
}