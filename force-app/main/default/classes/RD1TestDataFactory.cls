/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-29-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class RD1TestDataFactory {

    public static User createUser(String username, String firstName, String opco) {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        return new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = firstName,
            Email = username + '@example.com',
            Username = username + '@example.com',
            Alias = 'aduser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true,
            Opco__c = opco
        );
    }
    public static User createUserAlias(String username, String firstName, String opco, String alias) {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        return new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = firstName,
            Email = username + '@example.com',
            Username = username + '@example.com',
            Alias = alias,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true,
            Opco__c = opco
        );
    }

    // A generic method that setups a account, contact, client, and job and closing report
    public static Account setupAll() {
        Account testAccount = createTestAccount();
        Contact client = createTestContact(testAccount.Id, 'Client');
        TR1__Job__c job = createTestJob(testAccount.Id, client.Id);

        // Create TalentRoverProperties record
         TR1__TalentRoverProperties__c trp = new TR1__TalentRoverProperties__c(
            TR1__Enable_New_ATS_Data_model__c = true
        );
        insert trp;


        Contact candidate = createCandidate();

        testAccount.AUSY_Changepoint_ID__c = 'ChargepointAA11';
        update testAccount;

        TR1__Application_V2__c application = createApplication(candidate.Id, job.Id, 'Consulting');
        TR1__Closing_Report__c closingReport = createPlacement(candidate.Id, testAccount.Id, job.Id, 'Consulting');

        return testAccount;
    }
    //Create Application for Candidate and a job Id
    public static TR1__Application_V2__c createApplication(Id candidateId, Id jobId, String recordType) {
        String recordTypeId = getRecordTypeId('TR1__Application_V2__c', recordType);

        TR1__Application_V2__c testApplication = new TR1__Application_V2__c();
        testApplication.TR1__Stage__c = 'Closing Report';
        testApplication.TR1__Applicant__c = candidateId;
        testApplication.TR1__Job__c = jobId;
        testApplication.RecordTypeId = recordTypeId;
        testApplication.Source__c = 'Google';
        testApplication.Status__c = 'Submitted';

        insert testApplication;
        return testApplication;
    }

    // Create a Placement record, given a candidate and job Id
    public static TR1__Closing_Report__c createPlacement(Id candidateId, Id accountId, Id jobId, String recordType) {
        Id recordTypeId = getRecordTypeId('TR1__Closing_Report__c', 'Consulting');
        TR1__Closing_Report__c testClosingReport = new TR1__Closing_Report__c(
            TR1__Person_Placed__c = candidateId,
            TR1__Account__c = accountId,
            TR1__Job__c = jobId,
            User_Opco__c = 'Belux',
            Assignment_Type__c = 'T&M',
            Business_unit__c = '5201 Delivery IT operations',
            TR1__Start_Date__c = Date.today().addDays(-30),
            Billing_Entity__c = 'RSD Belgium',
            TR1__Other_Percentage__c = 100,
            RecordTypeId = recordTypeId
        );

        insert testClosingReport;
        return testClosingReport;
    }

    public static Contact createCandidate() {
        Id candidateRecordTypeId = getRecordTypeId('Contact', 'Candidate');

        Contact testPerson = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                RecordTypeId = candidateRecordTypeId,
                Email = 'salesforce@randstaddigital.com',
                Mpleo_Id__c = '1006607',
                Employee_Type__c='GDC',
                Line_of_Business__c='RD',
                Source_Type__c='Dice'
            );
            insert testPerson;
        return testPerson;
    }

    /********************* Account Related  **********************/
    public static Account buildAccount() {
        Account testAccount = new Account(
            Name = 'Test Account',
            BH_VAT_Number__c = '1234567',
            BillingCity = 'Bangalore',
            BillingStreet = 'Test Street',
            BillingCountry = 'India',
            BillingState = 'Karnataka',
            BillingPostalCode = '12345'
        );
        return testAccount;
    }

    public static Account createAccount(String recordType) {
        Id recordTypeId = getRecordTypeId('Account', recordType);
        Account account = buildAccount();
        account.RecordTypeId = recordTypeId;

        return account;
    }

    public static Account createTestAccount() {
        Account account = buildAccount();
        insert account;
        return account;
    }
    /************************ END Account Related  *****************************/


    /************************** Opportunity Related **************************/
    // Creates an Opportunity without a Pricebook assigned
    public static Opportunity createCleanOpportunity() {
    Opportunity oppTest = new Opportunity(
        Name = 'Test Opportunity - Clean',
        StageName = 'New',
        CloseDate = Date.today(),
        Offshore_Possibility__c='Yes'
    );
    insert oppTest;
    return oppTest;
    }

    /************************** END Opportunity Related **************************/

    public static Contact createTestContact(Id accountId,String recordTypeDeveloperName) {
       Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName AND SObjectType = 'Contact' LIMIT 1].Id;

    Contact testContact = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        Email = 'test@test.com',
        TR1__Is_Contact__c= True,
        AccountId = accountId,
        RecordTypeId = recordTypeId
    );
    insert testContact;
        testContact = [SELECT Id, TR1__Is_Contact__c FROM Contact WHERE Id = :testContact.Id LIMIT 1];
    System.debug('TR1__Is_Contact__c value: ' + testContact.TR1__Is_Contact__c);
    return testContact;
}

    public static TR1__Job__c buildJob() {
        TR1__Job__c testJob = new TR1__Job__c(
            Name = 'Test Job',
            Job_priority__c = 'P1',
            Billing_Entity__c = 'RSD Germany',
            Employment__c = 'Permanent',
            Line_of_Business__c = 'CR',
            //Service_line_job__c = 'RDPS',
            Source__c = 'Direct Manager',
            Publishing_Status__c = 'Not Published',
            Job_Type__c = 'Contract'
        );
        return testJob;
    }

    public static TR1__Job__c createTestJob(Id accountId, Id contactId) {
        TR1__Job__c testJob = buildJob();
        testJob.TR1__Account__c = accountId;
        testJob.TR1__Contact__c = contactId;

        insert testJob;
        return testJob;
    }

    public static TR1__Closing_Report__c createTestClosingReport(Id accountId, Id jobId) {
        TR1__Closing_Report__c testRecord = new TR1__Closing_Report__c(
            Comments__c = 'Test Report',
            Employee_Type__c = 'Vendor',
            Exempt_or_NonExempt__c = 'Exempt',
            Home_Work__c = 'Yes',
            Invoice_Attention__c = 'Test',
            Invoice_Client_Name__c = 'Test',
            New_Invoicing_Client__c='Yes',
            Line_of_Business__c = 'Advisory',
            Manager_Contact_Allowed__c = 'Yes',
            Rev_Share_Job_Lead_Sharing__c = 'Yes',
            Payroll_Deal__c = 'Yes',
            Hours_of_Operation__c = '5am to 2pm',
            Estimated_End_Date_status__c = 'Extension Likely',
            TR1__Pay_Type__c='Per Hour',
            Placement_Type__c='Contract',
            Sales_Division__c='36962',
            iLabor_Candidate__c='Yes',
            Billing_Entity__c='	RSD Germany',
            TR1__Account__c = accountId,
            TR1__Other_Percentage__c = 100,
            TR1__Job__c = jobId,
            Assignment_Type__c ='T&M'
        );
        insert testRecord;
        return testRecord;
    }

     public static TR1__Closing_Report__c createTestClosingReportWithRecordType(Id accountId, Id jobId, String recordType) {
        TR1__Closing_Report__c closingReport = new TR1__Closing_Report__c(
            Comments__c = 'Test Report',
            Employee_Type__c = 'Vendor',
            Exempt_or_NonExempt__c = 'Exempt',
            Home_Work__c = 'Yes',
            Invoice_Attention__c = 'Test Attention',
            Invoice_Client_Name__c = 'Test Client',
            New_Invoicing_Client__c = 'Yes',
            Line_of_Business__c = 'Advisory',
            Manager_Contact_Allowed__c = 'Yes',
            Rev_Share_Job_Lead_Sharing__c = 'Yes',
            Payroll_Deal__c = 'Yes',
            Hours_of_Operation__c = '5am to 2pm',
            Estimated_End_Date_status__c = 'Extension Likely',
            TR1__Pay_Type__c = 'Per Hour',
            Placement_Type__c = recordType,
            Sales_Division__c = '36962',
            iLabor_Candidate__c = 'Yes',
            Billing_Entity__c = 'RSD US', // fixed tab spacing
            TR1__Account__c = accountId,
            TR1__Other_Percentage__c = 100,
            TR1__Job__c = jobId,
            TR1__Salary__c = 100000,
            TR1__Fee_Percentage__c = 0.1,
            Placement_Fee_Flat__c = 10000,
            Assignment_Type__c = 'T&M'
        );

        insert closingReport;
        return closingReport;
    }

     public static TR1__Closing_Report__c createPlacementChangeRequestSync(Id accountId, Id jobId, String changeRequestRTId,String parentPlacementId) {
        TR1__Closing_Report__c closingReport = new TR1__Closing_Report__c(
            Comments__c = 'Test Report 1',
            Employee_Type__c = 'Vendor',
            Exempt_or_NonExempt__c = 'Exempt',
            Home_Work__c = 'Yes',
            Invoice_Attention__c = 'Test Attention',
            Invoice_Client_Name__c = 'Test Client',
            New_Invoicing_Client__c = 'Yes',
            Line_of_Business__c = 'Advisory',
            Manager_Contact_Allowed__c = 'Yes',
            Rev_Share_Job_Lead_Sharing__c = 'Yes',
            Payroll_Deal__c = 'Yes',
            Hours_of_Operation__c = '5am to 2pm',
            Estimated_End_Date_status__c = 'Extension Likely',
            TR1__Pay_Type__c = 'Per Hour',
            Placement_Type__c = 'Permanent',
            Sales_Division__c = '36962',
            iLabor_Candidate__c = 'Yes',
            Billing_Entity__c = 'RSD US', // fixed tab spacing
            TR1__Account__c = accountId,
            TR1__Other_Percentage__c = 100,
            TR1__Job__c = jobId,
            RecordTypeId = changeRequestRTId,
            Request_Status__c = 'Submitted',
            ParentPlacementId__c = parentPlacementId
        );

        insert closingReport;
        return closingReport;
    }

    /******************** Record Type Utilty Functions *******************/
    public static Schema.SObjectType getSObjectTypeFromName(String objectType) {
        Schema.SObjectType targetSObject = null;

        if (objectType == 'TR1__Job__c') {
            targetSObject = TR1__Job__c.sObjectType;
        }
        if (objectType == 'Opportunity') {
            targetSObject = Opportunity.sObjectType;
        }
        if (objectType == 'Account') {
            targetSObject = Account.sObjectType;
        }
        if (objectType == 'Contact') {
            targetSObject = Contact.sObjectType;
        }
        if (objectType == 'TR1__Application_V2__c') {
            targetSObject = TR1__Application_V2__c.sObjectType;
        }
        if (objectType == 'TR1__Closing_Report__c') {
            targetSObject = TR1__Closing_Report__c.sObjectType;
        }
        if (objectType == 'TR1__Send_Out_Schedule_V2__c') {
            targetSObject = TR1__Send_Out_Schedule_V2__c.sObjectType;
        }
        return targetSObject;
    }

    public static Id getRecordTypeId(String objectType, String recordTypeName) {
        Schema.SObjectType targetSObject = getSObjectTypeFromName(objectType);
        String recordTypeId = null;

        Schema.DescribeSObjectResult describeResult = targetSObject.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfoByName = describeResult.getRecordTypeInfosByDeveloperName();

        if (recordTypeInfoByName.containsKey(recordTypeName)) {
            recordTypeId = recordTypeInfoByName.get(recordTypeName).getRecordTypeId();
        }
        return recordTypeId;
    }

    /***************************************** END Record Type ********************/


   /***********************************OpportunityLineItem Creation TestData************/
  // Creates an Opportunity used specifically for assigning the Standard Pricebook
    public static Opportunity createTestOpportunity()
{
    Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        CloseDate = Date.today().addDays(10),
        StageName = 'New',
        Offshore_Possibility__c='Yes');
        insert opp;
        return opp;
}

public static Product2 createTestProduct() {
        Product2 prod = new Product2(
            Name = 'Job',
            IsActive = true
        );
        insert prod;
        return prod;
    }
public static PricebookEntry createTestPricebookEntry(Id productId) {
        Id standardPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

 public static JobFunction__c createTestJobFunction() {
        JobFunction__c jobFunction = new JobFunction__c(Name = 'IT Policy Adviser');
        insert jobFunction;
        return jobFunction;
    }

public static OpportunityLineItem createTestOpportunityLineItem(Id oppId, Id pbeId, Id jobFunctionId) {
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            OpportunityId = oppId,
            PricebookEntryId = pbeId,
            Quantity = 1,
            UnitPrice = 100,
            Job_Type__c = 'Permanent',
            Number_of_Positions__c = 2,
            Job_Function__c = jobFunctionId,
            Torc_Job_Type__c='Backend Engineer'
        );
        insert opportunityLineItem;
        return opportunityLineItem;
    }

    public static TR1__Job__c createJob(Id oppLineItemId){
        TR1__Job__c job = new TR1__Job__c(
            Name = 'Test Job',
            OpportunityLineItem__c = oppLineItemId,
            Job_Type__c='Contract'
        );
        insert job;
        return job;

    }

    public static void createOpportunityLineItemData(Boolean createJob) {
    Opportunity opp = createTestOpportunity();
    Product2 product = createTestProduct();
    PricebookEntry pbe = createTestPricebookEntry(product.Id);
    JobFunction__c jobFunction = createTestJobFunction();
    OpportunityLineItem lineItem = createTestOpportunityLineItem(opp.Id, pbe.Id, jobFunction.Id);

        if (createJob) {
            createJob(lineItem.Id);
        }
	}
   /*********************************** END OpportunityLineItem Creation TestData ************/

   /****VMS Related TestData***/

   public static void createVMSOpportunityCreationSetting(Boolean isEnabled) {
        VMS_Opportunity_Creation_Setting__c setting = new VMS_Opportunity_Creation_Setting__c(
            SetupOwnerId = UserInfo.getUserId(),
            Is_Enabled__c = isEnabled
        );
        insert setting;
	}

    public static TR1__Job__c createVMSJob(Id accountId, String recordTypeName) {
        Id jobRTId = getRecordTypeId('TR1__Job__c', recordTypeName);
        TR1__Job__c job = new TR1__Job__c(
            Name = 'Test VMS Job',
            TR1__Account__c = accountId,
            TR1__Status__c = 'Accepting Candidates',
            Chapter_job__c = 'Analists',
            Line_of_Business__c = 'CR',
            RecordTypeId = jobRTId,
            Job_Type__c = 'Contract',
            TR1__Unique_VMS_Req_ID__c = 'REQ-VMS-' + DateTime.now().getTime(),
            TR1__VMS_Status__c = 'Submitted',
            TR1__Estimated_Start_Date__c = Date.today(),
            TR1__Estimated_End_Date__c = Date.today().addDays(30),
            TR1__Maximum_Bill_Rate__c = 2.0,
            TR1__Maximum_Pay_Rate__c = 1.0,
            Calculated_GP__c = 3123,
            Education_Requirements__c = 'Bachelors',
            Independent_Contractors_Allowed__c = 'No',
            Interview_Info__c = 'Phone to Hire',
            RITS_Talent_Allowed__c='No'

        );
        insert job;
        return job;
	}

    /****End of VMS Related TestData***/
}