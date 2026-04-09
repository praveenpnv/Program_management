public class testUtils
{
    public static void deactivateVR()
    {
        Active_Trigger_Flow_VR__c atf= Active_Trigger_Flow_VR__c.getOrgDefaults();
        atf.Account_Flow__c = false;
        atf.Account_Trigger__c = false;
        atf.Account_VR__c = false;
        atf.ApplicationV2_Flow__c = false;
        atf.ApplicationV2_Trigger__c = false;
        atf.ApplicationV2_VR__c = false;
        atf.Contact_Flow__c = false;
        atf.Contact_Trigger__c = false;
        atf.Contact_VR__c = false;
        atf.Job_Flow__c = false;
        atf.Job_Trigger__c = false;
        atf.Job_VR__c = false;
        atf.Placement_Flow__c = false;
        atf.Placement_Trigger__c = false;
        atf.Placement_VR__c = false;
        upsert atf;
    }
    public static integer counter=0;
    public static Account setupCustomSettings(User currentUser,dfsle__EnvelopeConfiguration__c d)
    {
        id recTypeId=[Select Id from recordtype where DeveloperName='Client' and sObjectType='Account'].id;
        Account act=new Account(Name='SumitAlltesting',Website='www.abba.cas', Quickbooks_ID__c='10001', Quickbooks_Customer__c='dsdf',recordTypeId=recTypeId);insert act;
        Torc_Constants__c tc= Torc_Constants__c.getOrgDefaults();
        tc.torc_Account__c = act.id;
        tc.Auto_Create_Qubika_Process__c = true;
        tc.AWS_Always_Query__c = true;
        tc.Disable_Attachment_Trigger__c=false;
        tc.Disable_Opportunity_Platform_Update__c = false;
        tc.Wish_Anniversary__c = true;
        tc.Wish_Birthday__c=true;        
        tc.Default_Contact_Recordtype__c=[SELECT Id from RecordType Where SobjectType='Contact' and DeveloperName='Client'].id;
        tc.Engagement_Updator__c = currentUser.userName;
        tc.Google_Key__c ='abc';
        tc.Hiring_Product__c='Hiring Fee';
        tc.Manual_Doc_Number__c = true;
        tc.Max_Payments__c = 500;
        tc.RD_Bullhorn_Job_Sync__c = true;
        tc.Referral_Bonus_category__c ='Recruiting:Community:Community Incentives';
        tc.Run_Extension_Check__c = true;
        tc.Skip_Placement__c = false;        
        tc.Slack_Wish_Channel__c ='C02CZN1B3M2';
        tc.check_opportunity_record_type__c=true;
        tc.torc_record_type__c=[Select ID from recordType Where Name='Torc Process' LIMIT 1].id;
        tc.Trolley_Payment_batch_Size__c =15;
        if(d!=NULL)
            tc.MSA_Template_Id__c = d.id;
        tc.Docusign_Special_Accounts__c = act.id;
        tc.Members_Account__c = act.id;
        tc.Qubika_Account__c = act.id;
        tc.RandstadAccountId__c = act.id;
        upsert tc;
        setupRd1ToRorcIntegrationCustomSettings(true);
        return act;
    }
    public static void setupRd1ToRorcIntegrationCustomSettings(boolean skipIt)
    {
        Torc_Rd1_Integration__c tc= Torc_Rd1_Integration__c.getOrgDefaults();
        tc.Candidate_bi_Directional__c = false;
        tc.Candidate_Recordtype_Id__c =[Select ID from RecordType where DeveloperName = 'Candidate' and SobjectType='Contact'].id;
        tc.Default_Account__c=[Select ID from Account where Name = 'Candidate Pool Account'].id;
        tc.Skip_RD1_To_Torc__c = skipIt;
        tc.Skip_Torc_to_RD1__c = skipIt;
        tc.updater_list_in_torc__c ='sfdc_dev_integration,SFDC';
        upsert tc;
    }
    Public static Account getNewAccount()
    {
        string name=(counter==0?'Cloud2Crowd':(counter==1?'TorcLLC':(counter==2?'RD1':(counter==3?'Google':'Yahoo'))));
        for(Account a:[Select id,Name,Quickbooks_ID__c from Account where Name=:name LIMIT 1])
            return a;
        Account act=new Account(Name=name,Quickbooks_ID__c='1002'+counter,RecordTypeId=[Select Id from recordtype where DeveloperName='Client' and sObjectType='Account'].id);
        system.debug('NEWACCOUNT:'+counter+':'+act.name);
        counter++;
        insert act;
        return act;
    }
    Public static Opportunity getNewBlankOpportunity(Account act)
    {
        Opportunity opp=new Opportunity(Name='test Opportunity', AccountId=act.id,CloseDate=Date.Today(),StageName='Qualification');
        opp.RecordTypeId=torc_constants__c.getinstance().torc_record_type__c;
        insert opp;
        return opp;
    }
    Public static Opportunity getNewOpportunity(Account act)
    {
        Opportunity opp=new Opportunity(Name='test Opportunity', AccountId=act.id,CloseDate=Date.Today(),StageName='Qualification');
        opp.RecordTypeId=torc_constants__c.getinstance().torc_record_type__c;
        insert opp;
        Date dt=date.newInstance(date.today().year(),date.today().Month(),1);
        id pricebookId=Test.getStandardPricebookId();
        PricebookEntry pbe = [Select Id, IsActive,Product2Id, Product2.Name, Product2.ProductCode,Product2.Description, UnitPrice
                                from PricebookEntry
                                where Pricebook2Id=:priceBookID AND Product2.Name='Transaction Fee'];
        OpportunityLineitem ol=new OpportunityLineitem(Quantity =1,Product_Type__c ='Transaction fee',OpportunityId=opp.id,Customer_Hourly_Bill_Rate__c=0, 
                                                    priceBookEntryID =pbe.id,Product2Id=pbe.product2Id,UnitPrice=0,
                                                    Engagement_Start_Date__c = dt, Hours_week__c=1);
        insert ol;        
        return opp;
    }
    Public static Opportunity getFreelancerOpportunity(Account act)
    {
        Opportunity opp=new Opportunity(Name='test Opportunity', AccountId=act.id,CloseDate=Date.Today(),StageName='Qualification');
        opp.RecordTypeId=torc_constants__c.getinstance().torc_record_type__c;
        insert opp;
        Date dt=date.newInstance(date.today().year(),date.today().Month(),1);
        id pricebookId=Test.getStandardPricebookId();
        PricebookEntry pbe = [Select Id, IsActive,Product2Id, Product2.Name, Product2.ProductCode,Product2.Description, UnitPrice
                                from PricebookEntry
                                where Pricebook2Id=:priceBookID AND Product2.Name='Freelancer'];
        Torc_user__c tu = [Select id,Name from Torc_user__c LIMIT 1];
        OpportunityLineitem lineitem=new OpportunityLineitem(Quantity =1,Product_Type__c ='Freelancer',OpportunityId=opp.id,priceBookEntryID =pbe.id,Product2Id=pbe.product2Id,
                                                    UnitPrice=0,
                                                    Engagement_Start_Date__c = dt, Hours_week__c=40
                                                    
                                                    );
            lineitem.Product_Category__c = 'Front End Engineer'; 
            lineitem.Time_Commitment__c='FULLTIME';
            lineitem.Hours_Week__c =40;
            lineitem.Engagement_Duration_weeks__c=5;
            lineitem.Engagement_Start_Date__c=Date.NewInstance(2024,11,11);
            lineitem.Engagement_End_Date__c=Date.NewInstance(2024,12,15);
            lineitem.Customer_Hourly_Bill_Rate__c =50; 
            lineitem.Talent_Hourly_Pay_Rate__c =20;
            lineItem.UnitPrice = lineitem.Customer_Hourly_Bill_Rate__c;
            lineitem.Quantity=lineitem.Engagement_Duration_weeks__c * lineitem.Hours_Week__c;            
            lineitem.Torc_user__c = tu.id;
            
            lineitem.Talent_Username__c = tu.Name;
        insert lineitem;
        return opp;
    }
    public static void setupAllTestData()
    {
        setupAllTestData('');
    }
    public static void setupAllTestData(string forWhat)
    {
        if([Select ID from Account where Name = 'Candidate Pool Account'].size()==0)
        {
            Account act=new Account(Name='Candidate Pool Account',Website='www.candidatePoolTest.cas', Quickbooks_ID__c='19', Quickbooks_Customer__c='dsdf');
            insert act;
        }    
        User currentUser = [Select id,userName from User where id=:Userinfo.getuserId()];
        Questionnaire__c ques= new Questionnaire__c();
        ques.Default_Submitter__c = currentUser.id;
        ques.Non_US_Match_Approver__c = currentUser.id;
        ques.Non_US_Non_Match_Approver__c = currentUser.id;
        ques.US_Match_Approver__c = currentUser.id;
        ques.US_Non_Match_Approver__c = currentUser.id;
        if(forWhat=='QUESTION')
            upsert ques;
        
        Torc_Config__c tcon = new Torc_Config__c(
        Access_Token_Expiry_At__c = dateTime.now().addminutes(1),
        Active__c=true,
        Authentication_URL__c='https://cognito-idp.us-east-1.amazonaws.com/',
        Client_ID__c='1111',
        Operations_URL__c='https://cc7kwnqydjhbzfdv4bc4ykn6f4.appsync-api.us-east-1.amazonaws.com/graphql',
        Password__c='*****',
        Previous_Access_Token__c ='ccc',
        User_Name__c='sfdc_integration'
        );
        insert tCon;
        Payment_Date__c pd=new Payment_Date__c(Date__c= Date.newInstance(2021,01,06));
        insert pd;
        List<QB_Test_Data__c> testData=new List<QB_Test_Data__c>();
        
        testData.add(new QB_Test_Data__c(Name='CREATEACCOUNT',JSON__c='{"Customer": {"domain": "QBO", "PrimaryEmailAddr": {"Address": "jdrew@myemail.com"}, "DisplayName": "Kings Groceries", "CurrencyRef": {"name": "United States Dollar", "value": "USD"}, "DefaultTaxCodeRef": {"value": "2"}, "PreferredDeliveryMethod": "Print", "GivenName": "James", "FullyQualifiedName": "Kings Groceries", "BillWithParent": false, "Title": "Mr", "Job": false, "BalanceWithJobs": 0, "PrimaryPhone": {"FreeFormNumber": "(555) 555-5555"}, "Taxable": true, "MetaData": {"CreateTime": "2015-07-23T10:58:12-07:00", "LastUpdatedTime": "2015-07-23T10:58:12-07:00"}, "BillAddr": {"City": "Mountain View", "Country": "USA", "Line1": "123 Main Street", "PostalCode": "94042", "CountrySubDivisionCode": "CA", "Id": "112"}, "MiddleName": "B", "Notes": "Here are other details.", "Active": true, "Balance": 0, "SyncToken": "0", "Suffix": "Jr", "CompanyName": "King Groceries", "FamilyName": "King", "PrintOnCheckName": "King Groceries", "sparse": false, "Id": "67"}, "time": "2015-07-23T10:58:12.099-07:00"}'));
        testData.add(new QB_Test_Data__c(Name='CREATEBATCH',JSON__c='{"ok": true, "batch": {"id": "B-Pn7wJZneEBsDMNvdSQyWpF", "status": "open", "tags": [], "amount": "0.00", "currency": "USD", "totalPayments": 0, "description": "Payouts on 30 May 2023 #99", "sentAt": null, "completedAt": null, "createdAt": "2023-05-30T05:27:29.251Z", "updatedAt": "2023-05-30T05:27:29.355Z", "quoteExpiredAt": null, "payments": {"payments": [], "meta": {"page": 1, "pages": 0, "records": 0}}}}'));
        testData.add(new QB_Test_Data__c(Name='CREATEINVOICE',JSON__c='{"ok": true, "invoice": {"id": "I-943ubvXhFaHXQGuwAXbk48", "invoiceNumber": "0000031", "description": "", "status": "open", "externalId": "a198B000000KQNSQA4", "invoiceDate": "2023-05-30T05:27:29.713Z", "dueDate": null, "releaseAfter": null, "createdAt": "2023-05-30T05:27:29.712Z", "updatedAt": "2023-05-30T05:27:29.723Z", "totalAmount": {"value": "400.00", "currency": "USD"}, "paidAmount": {"value": "0.00", "currency": "USD"}, "pendingAmount": {"value": "0.00", "currency": "USD"}, "dueAmount": {"value": "400.00", "currency": "USD"}, "tags": [], "lines": [{"id": "IL-QpUDAy3gYuvyFB8oDDMVMB", "status": "open", "itemUrl": null, "description": "Abc Corp 4/2/2023 - 4/8/2023", "unitAmount": {"value": "400.00", "currency": "USD"}, "quantity": "1", "discountAmount": {"value": "0.00", "currency": "USD"}, "taxAmount": {"value": "0.00", "currency": "USD"}, "totalAmount": {"value": "400.00", "currency": "USD"}, "dueAmount": {"value": "400.00", "currency": "USD"}, "paidAmount": {"value": "0.00", "currency": "USD"}, "pendingAmount": {"value": "0.00", "currency": "USD"}, "externalId": "a188B000000F3KtQAK", "taxReportable": true, "tags": [], "category": "services", "forceUsTaxActivity": false}], "recipientId": "R-VRcRK8YtUqkB7a2keaaApJ", "syncDetails": null}}'));
        testData.add(new QB_Test_Data__c(Name='CREATEINVOICEPAYMENT',JSON__c='{"ok": true, "invoicePayment": {"batchId": "B-Pn7wJZneEBsDMNvdSQyWpF", "paymentId": "P-NzTsnNNW8fyNGpbG2DhLXm", "invoicePayments": [{"invoiceId": "I-943ubvXhFaHXQGuwAXbk48", "invoiceLineId": "IL-QpUDAy3gYuvyFB8oDDMVMB", "paymentId": "P-NzTsnNNW8fyNGpbG2DhLXm", "amount": {"value": "400.00", "currency": "USD"}, "status": "pending"}]}}'));
        testData.add(new QB_Test_Data__c(Name='CREATEVENDOR',JSON__c='{"Vendor": {"domain": "QBO", "PrimaryEmailAddr": {"Address": "dbradley@myemail.com"}, "DisplayName": "Diannes Auto Shop", "CurrencyRef": {"name": "United States Dollar", "value": "USD"}, "GivenName": "Dianne", "Title": "Ms.", "PrimaryPhone": {"FreeFormNumber": "(650) 555-2342"}, "Active": true, "MetaData": {"CreateTime": "2015-07-28T12:51:21-07:00", "LastUpdatedTime": "2015-07-28T12:51:21-07:00"}, "Vendor1099": false, "BillAddr": {"City": "Millbrae", "Country": "U.S.A", "Line3": "29834 Mustang Ave.", "Line2": "Dianne Bradley", "Line1": "Diannes Auto Shop", "PostalCode": "94030", "CountrySubDivisionCode": "CA", "Id": "423"}, "Mobile": {"FreeFormNumber": "(650) 555-2000"}, "WebAddr": {"URI": "http://DiannesAutoShop.com"}, "Balance": 0, "SyncToken": "0", "Suffix": "Sr.", "CompanyName": "Diannes Auto Shop", "FamilyName": "Bradley", "TaxIdentifier": "99-5688293", "AcctNum": "35372649", "PrintOnCheckName": "Diannes Auto Shop", "sparse": false, "Id": "137"}, "time": "2015-07-28T12:51:21.326-07:00"}'));
        testData.add(new QB_Test_Data__c(Name='QUERYACCOUNT',JSON__c='{"QueryResponse": {"Customer": [{"domain": "QBO", "FamilyName": "Lauterbach", "DisplayName": "Amys Bird Sanctuary", "DefaultTaxCodeRef": {"value": "2"}, "PrimaryEmailAddr": {"Address": "Birds@Intuit.com"}, "PreferredDeliveryMethod": "Print", "GivenName": "Amy", "FullyQualifiedName": "Amys Bird Sanctuary", "BillWithParent": false, "Job": false, "BalanceWithJobs": 274.0, "PrimaryPhone": {"FreeFormNumber": "(650) 555-3311"}, "Active": true, "MetaData": {"CreateTime": "2014-09-11T16:48:43-07:00", "LastUpdatedTime": "2015-07-01T10:14:15-07:00"}, "BillAddr": {"City": "Bayshore", "Line1": "4581 Finch St.", "PostalCode": "94326", "Lat": "INVALID", "Long": "INVALID", "CountrySubDivisionCode": "CA", "Id": "2"}, "MiddleName": "Michelle", "Notes": "Note added via Update operation.", "Taxable": true, "Balance": 274.0, "SyncToken": "5", "CompanyName": "Amys Bird Sanctuary", "ShipAddr": {"City": "Bayshore", "Line1": "4581 Finch St.", "PostalCode": "94326", "Lat": "INVALID", "Long": "INVALID", "CountrySubDivisionCode": "CA", "Id": "109"}, "PrintOnCheckName": "Amys Bird Sanctuary", "sparse": false, "Id": "1"}, {"domain": "QBO", "PrimaryEmailAddr": {"Address": "Consulting@intuit.com"}, "DisplayName": "Weiskopf Consulting", "FamilyName": "Weiskopf", "PreferredDeliveryMethod": "Print", "GivenName": "Nicola", "FullyQualifiedName": "Weiskopf Consulting", "BillWithParent": false, "Job": false, "BalanceWithJobs": 390.0, "PrimaryPhone": {"FreeFormNumber": "(650) 555-1423"}, "Active": true, "MetaData": {"CreateTime": "2014-09-11T17:29:04-07:00", "LastUpdatedTime": "2015-06-24T15:54:02-07:00"}, "BillAddr": {"City": "Bayshore", "Line1": "45612 Main St.", "PostalCode": "94326", "Lat": "45.256574", "Long": "-66.0943698", "CountrySubDivisionCode": "CA", "Id": "30"}, "Taxable": false, "Balance": 390.0, "SyncToken": "0", "CompanyName": "Weiskopf Consulting", "ShipAddr": {"City": "Bayshore", "Line1": "45612 Main St.", "PostalCode": "94326", "Lat": "45.256574", "Long": "-66.0943698", "CountrySubDivisionCode": "CA", "Id": "30"}, "PrintOnCheckName": "Weiskopf Consulting", "sparse": false, "Id": "29"}], "startPosition": 1, "maxResults": 6}, "time": "2015-07-23T11:02:25.149-07:00"}'));
        testData.add(new QB_Test_Data__c(Name='QUERYBILL',JSON__c='{"QueryResponse": {"startPosition": 1, "totalCount": 2, "Bill": [{"SyncToken": "2", "domain": "QBO", "VendorRef": {"name": "Norton Lumber and Building Materials", "value": "100"}, "TxnDate": "2023-05-06", "TotalAmt": 225.0, "APAccountRef": {"name": "Accounts Payable (A/P)", "value": "101"}, "Id": "150", "sparse": false, "Line": [{"DetailType": "ItemBasedExpenseLineDetail", "Amount": 100.0, "Id": "1", "ItemBasedExpenseLineDetail": {"TaxCodeRef": {"value": "NON"}, "Qty": 8, "BillableStatus": "NotBillable", "UnitPrice": 10, "ItemRef": {"name": "Pump", "value": "11"}}, "Description": "TorcTest 4/30/2023 - 5/6/2023"}, {"DetailType": "ItemBasedExpenseLineDetail", "Amount": 125.0, "Id": "2", "ItemBasedExpenseLineDetail": {"TaxCodeRef": {"value": "NON"}, "Qty": 1, "BillableStatus": "NotBillable", "UnitPrice": 125, "ItemRef": {"name": "Rock Fountain", "value": "5"}}, "Description": "Rock Fountain"}], "Balance": 225.0, "DueDate": "2014-10-07", "MetaData": {"CreateTime": "2014-10-15T13:55:31-07:00", "LastUpdatedTime": "2014-10-15T14:24:54-07:00"}}, {"SyncToken": "0", "domain": "QBO", "VendorRef": {"name": "Bobs Burger Joint", "value": "56"}, "TxnDate": "2014-10-15", "TotalAmt": 200.0, "APAccountRef": {"name": "Accounts Payable (A/P)", "value": "33"}, "Id": "149", "sparse": false, "Line": [{"DetailType": "AccountBasedExpenseLineDetail", "Amount": 200.0, "Id": "1", "AccountBasedExpenseLineDetail": {"TaxCodeRef": {"value": "NON"}, "AccountRef": {"name": "Advertising", "value": "7"}, "BillableStatus": "NotBillable"}}], "Balance": 200.0, "DueDate": "2014-10-15", "MetaData": {"CreateTime": "2014-10-15T13:48:00-07:00", "LastUpdatedTime": "2014-10-15T13:48:00-07:00"}}], "maxResults": 2}, "time": "2014-10-15T14:41:39.98-07:00"}'));
        testData.add(new QB_Test_Data__c(Name='QUERYINVOICE',JSON__c='{"QueryResponse": {"Invoice": [{"AllowIPNPayment": false, "AllowOnlinePayment": false, "AllowOnlineCreditCardPayment": false, "AllowOnlineACHPayment": false, "domain": "QBO", "sparse": false, "Id": "442", "SyncToken": "2", "MetaData": {"CreateTime": "2023-04-25T02:21:40-07:00", "LastModifiedByRef": {"value": "9130354777134566"}, "LastUpdatedTime": "2023-04-25T02:55:09-07:00"}, "CustomField": [{"DefinitionId": "1", "Name": "CRMID", "Type": "StringType", "StringValue": "[CRMID]"}, {"DefinitionId": "2", "Name": "MASTERCRMID", "Type": "StringType", "StringValue": "[MASTERCRMID]"}, {"DefinitionId": "3", "Name": "PO Number", "Type": "StringType"}], "DocNumber": "1195", "TxnDate": "2023-05-15", "CurrencyRef": {"value": "USD", "name": "United States Dollar"}, "LinkedTxn": [], "Line": [{"Id": "1", "LineNum": 1, "Description": "Sumit Mishra 4/30/2023 - 5/6/2023", "Amount": 1000, "DetailType": "SalesItemLineDetail", "SalesItemLineDetail": {"ItemRef": {"value": "23", "name": "Services"}, "UnitPrice": 1000, "Qty": 1, "ItemAccountRef": {"value": "163", "name": "Services"}, "TaxCodeRef": {"value": "NON"}}}, {"Amount": 1000, "DetailType": "SubTotalLineDetail", "SubTotalLineDetail": {}}], "CustomerRef": {"value": "101", "name": "TATA Moters"}, "CustomerMemo": {"value": "Payment Information:Bank NameMorganUSABank Address: ABC Address"}, "BillAddr": {"Id": "144", "Line1": "j-6/117 Chaat house lane, trimurti circle, narayan singh road", "City": "Jaipur", "CountrySubDivisionCode": "Rajasthan", "PostalCode": "302004"}, "ShipAddr": {"Id": "147", "Line1": "j-6/117 Chaat house lane, Trim", "City": "Jaipur", "Country": "India", "CountrySubDivisionCode": "Rajasthan", "PostalCode": "302004"}, "FreeFormAddress": false, "SalesTermRef": {"value": "13", "name": "Net 15"}, "DueDate": "2023-05-09", "TotalAmt": 1000, "ApplyTaxAfterDiscount": false, "PrintStatus": "NeedToPrint", "EmailStatus": "NotSet", "Balance": 1000}], "startPosition": 1, "maxResults": 1, "totalCount": 1}, "time": "2023-05-03T01:31:24.927-07:00"}'));
        testData.add(new QB_Test_Data__c(Name='QUERYVENDOR',JSON__c='{"QueryResponse": {"startPosition": 1, "Vendor": [{"Vendor1099": false, "domain": "QBO", "DisplayName": "Bobs Burger Joint", "SyncToken": "0", "PrintOnCheckName": "Bobs Burger Joint", "sparse": false, "Active": true, "Balance": 390.0, "Id": "56", "MetaData": {"CreateTime": "2014-10-03T14:28:52-07:00", "LastUpdatedTime": "2015-07-14T12:37:57-07:00"}}, {"Vendor1099": false, "domain": "QBO", "DisplayName": "Cal Telephone", "BillAddr": {"City": "Palo Alto", "Line1": "10 Main St.", "PostalCode": "94303", "Lat": "37.445013", "Long": "-122.1391443", "CountrySubDivisionCode": "CA", "Id": "33"}, "SyncToken": "0", "CompanyName": "Cal Telephone", "TermRef": {"value": "1"}, "PrimaryPhone": {"FreeFormNumber": "(650) 555-1616"}, "PrintOnCheckName": "Cal Telephone", "sparse": false, "Active": true, "Balance": 0, "Id": "32", "MetaData": {"CreateTime": "2014-09-12T10:13:24-07:00", "LastUpdatedTime": "2014-09-19T12:55:23-07:00"}}, {"Vendor1099": false, "domain": "QBO", "GivenName": "Melanie", "DisplayName": "Hall Properties", "sparse": false, "SyncToken": "0", "Mobile": {"FreeFormNumber": "(973) 888-6222"}, "PrintOnCheckName": "Hall Properties", "PrimaryPhone": {"FreeFormNumber": "(973) 555-3827"}, "FamilyName": "Hall", "TaxIdentifier": "XXXXXXXX2222", "AcctNum": "55642", "CompanyName": "Hall Properties", "WebAddr": {"URI": "http://www.hallproperties.intuit.org"}, "BillAddr": {"City": "South Orange", "Line1": "P.O.Box 357", "PostalCode": "07079", "Lat": "40.7489277", "Long": "-74.2609903", "CountrySubDivisionCode": "NJ", "Id": "36"}, "Active": true, "Balance": 0, "Id": "40", "MetaData": {"CreateTime": "2014-09-12T10:24:28-07:00", "LastUpdatedTime": "2014-09-18T13:43:08-07:00"}}, {"Vendor1099": false, "domain": "QBO", "GivenName": "Geoff", "DisplayName": "Hicks Hardware", "BillAddr": {"City": "Middlefield", "Line1": "42 Main St.", "PostalCode": "94303", "Lat": "37.445013", "Long": "-122.1391443", "CountrySubDivisionCode": "CA", "Id": "37"}, "SyncToken": "0", "Mobile": {"FreeFormNumber": "(650) 445-6666"}, "PrintOnCheckName": "Hicks Hardware", "FamilyName": "Hicks", "PrimaryPhone": {"FreeFormNumber": "(650) 554-1973"}, "AcctNum": "556223", "CompanyName": "Hicks Hardware", "WebAddr": {"URI": "http://Hickshardware.co"}, "sparse": false, "Active": true, "Balance": 0, "Id": "41", "MetaData": {"CreateTime": "2014-09-12T10:26:56-07:00", "LastUpdatedTime": "2014-09-18T13:01:57-07:00"}}, {"PrimaryEmailAddr": {"Address": "Materials@intuit.com"}, "Vendor1099": false, "domain": "QBO", "GivenName": "Julie", "DisplayName": "Norton Lumber and Building Materials", "BillAddr": {"City": "Middlefield", "Line1": "4528 Country Road", "PostalCode": "94303", "Lat": "37.3752919", "Long": "-122.1692159", "CountrySubDivisionCode": "CA", "Id": "40"}, "SyncToken": "0", "PrintOnCheckName": "Norton Lumber and Building Materials", "FamilyName": "Norton", "PrimaryPhone": {"FreeFormNumber": "(650) 363-6578"}, "AcctNum": "32980256", "CompanyName": "Norton Lumber and Building Materials", "sparse": false, "Active": true, "Balance": 0, "Id": "46", "MetaData": {"CreateTime": "2014-09-12T10:32:55-07:00", "LastUpdatedTime": "2015-01-16T16:00:29-08:00"}}, {"Vendor1099": false, "domain": "QBO", "PrimaryEmailAddr": {"Address": "utilities@noemail.com"}, "DisplayName": "PG&E", "BillAddr": {"City": "Palo Alto", "Line1": "4 Main St.", "PostalCode": "94303", "Lat": "37.445013", "Long": "-122.1391443", "CountrySubDivisionCode": "CA", "Id": "42"}, "SyncToken": "1", "CompanyName": "PG&E", "PrimaryPhone": {"FreeFormNumber": "(888) 555-9465"}, "AcctNum": "00649587213", "PrintOnCheckName": "PG&E", "sparse": false, "Active": true, "Balance": 0, "Id": "48", "MetaData": {"CreateTime": "2014-09-12T10:36:57-07:00", "LastUpdatedTime": "2015-01-16T15:36:20-08:00"}}, {"Vendor1099": false, "domain": "QBO", "DisplayName": "QuickBooks Payments", "SyncToken": "0", "PrintOnCheckName": "QuickBooks Payments", "sparse": false, "Active": true, "Balance": 0, "Id": "63", "MetaData": {"CreateTime": "2015-04-13T13:42:23-07:00", "LastUpdatedTime": "2015-04-13T13:42:23-07:00"}}, {"Vendor1099": false, "domain": "QBO", "GivenName": "Jenny", "DisplayName": "Robertson & Associates", "BillAddr": {"City": "Bayshore", "Line1": "P.O. Box 147", "PostalCode": "94326", "Lat": "45.2720537", "Long": "-79.7935909", "CountrySubDivisionCode": "CA", "Id": "43"}, "SyncToken": "0", "PrintOnCheckName": "Robertson & Associates", "FamilyName": "Robertson", "PrimaryPhone": {"FreeFormNumber": "(650) 557-1111"}, "AcctNum": "000005641", "CompanyName": "Robertson & Associates", "sparse": false, "Active": true, "Balance": 95.0, "Id": "49", "MetaData": {"CreateTime": "2014-09-12T10:38:12-07:00", "LastUpdatedTime": "2015-06-30T15:09:07-07:00"}}, {"Vendor1099": false, "domain": "QBO", "DisplayName": "Squeaky Kleen Car Wash", "SyncToken": "0", "PrintOnCheckName": "Squeaky Kleen Car Wash", "sparse": false, "Active": true, "Balance": 0, "Id": "57", "MetaData": {"CreateTime": "2014-10-03T14:29:35-07:00", "LastUpdatedTime": "2014-10-03T14:29:35-07:00"}}, {"PrimaryEmailAddr": {"Address": "tim.philip@timphilipmasonry.com"}, "Vendor1099": false, "domain": "QBO", "GivenName": "Tim", "DisplayName": "Tim Philip Masonry", "sparse": false, "SyncToken": "0", "Mobile": {"FreeFormNumber": "(650) 555-1549"}, "PrintOnCheckName": "Tim Philip Masonry", "PrimaryPhone": {"FreeFormNumber": "(800) 556-1254"}, "FamilyName": "Philip", "TaxIdentifier": "XXXXXXXX5555", "AcctNum": "0078965", "CompanyName": "Tim Philip Masonry", "WebAddr": {"URI": "http://www.bricksbytim4less.co"}, "BillAddr": {"City": "Middlefield", "Line1": "3948 Elm St.", "PostalCode": "94482", "Lat": "37.4604972", "Long": "-122.1547528", "CountrySubDivisionCode": "CA", "Id": "45"}, "Active": true, "Balance": 0, "Id": "51", "MetaData": {"CreateTime": "2014-09-12T10:42:31-07:00", "LastUpdatedTime": "2014-09-18T13:06:58-07:00"}}], "maxResults": 10}, "time": "2015-07-28T13:29:10.643-07:00"}'));
        testData.add(new QB_Test_Data__c(Name='RETRIVEREC',JSON__c='{"ok": true, "recipients": [{"id": "R-G5oEiEQwHXV2kdcRhb7ywX", "referenceId": "3501e888-540d-4644-ac77-75dbc69ec630", "parentRecipientId": null, "email": "pravesh@su.flow", "name": "Pravesh Signupflow", "lastName": "Signupflow", "firstName": "Pravesh", "legalName": "", "type": "individual", "status": "incomplete", "language": "en", "complianceStatus": "pending", "dob": null, "passport": "", "placeOfBirth": null, "updatedAt": "2023-05-25T06:55:58.060Z", "createdAt": "2023-05-25T06:55:58.060Z", "tags": [], "isPortalUser": false, "taxDeliveryType": "mail", "contactEmails": [], "occupation": "", "address": {"street1": "", "street2": "", "city": "", "postalCode": "", "country": null, "region": null, "phone": "", "phoneValidated": false}, "compliance": {"status": "pending", "checkedAt": null}, "gravatarUrl": "https://www.gravatar.com/avatar/f30c5ac17b70b145400ace0204734539?d=404", "governmentId": null, "ssn": null, "governmentIds": [], "birthplace": {"country": null, "region": null, "city": null}, "citizenships": [], "routeType": null, "routeMinimum": null, "estimatedFees": null, "accounts": [], "payoutMethod": null, "primaryCurrency": null, "riskScore": null, "merchantId": "M-56eoAaJaeQxphgoUyWLYrw", "inactiveReasons": {"primaryAccount": "missing"}, "taxWithholdingPercentage": null, "taxForm": null, "taxFormStatus": null}, {"id": "R-VRcRK8YtUqkB7a2keaaApJ", "referenceId": "fecc883a-adb2-487a-b57d-5d477c7e44bc", "parentRecipientId": null, "email": "mcards@torc.dev", "name": "Mike Cardillo", "lastName": "Cardillo", "firstName": "Mike", "legalName": "", "type": "individual", "status": "active", "language": "en", "complianceStatus": "pending", "dob": "1990-01-01", "passport": "", "placeOfBirth": null, "updatedAt": "2023-05-25T06:50:39.276Z", "createdAt": "2023-05-24T10:40:12.633Z", "tags": [], "isPortalUser": false, "taxDeliveryType": "mail", "contactEmails": [], "occupation": "", "address": {"street1": "j-6/117 Chaat house lane, Trim", "street2": "Trimurti Circle", "city": "Jaipur", "postalCode": "99950", "country": "US", "region": null, "phone": "", "phoneValidated": false}, "compliance": {"status": "pending", "checkedAt": null}, "gravatarUrl": "https://www.gravatar.com/avatar/0808df7704cb1346f13b209c88ae6cf8?d=404", "governmentId": null, "ssn": null, "governmentIds": [], "birthplace": {"country": null, "region": null, "city": null}, "citizenships": [], "routeType": "ach", "routeMinimum": "0", "estimatedFees": "1", "accounts": [{"status": "primary", "type": "bank-transfer", "primary": true, "currency": "USD", "id": "A-3vP6CYdRYbPtLJzpL9LEUi", "recipientId": "R-VRcRK8YtUqkB7a2keaaApJ", "recipientAccountId": "A-3vP6CYdRYbPtLJzpL9LEUi", "disabledAt": null, "recipientReferenceId": "fecc883a-adb2-487a-b57d-5d477c7e44bc", "deliveryBusinessDaysEstimate": 5, "country": "US", "iban": "", "accountNum": "**11", "bankAccountType": null, "bankCodeMappingId": null, "accountHolderName": "MikeC", "swiftBic": "USBKUS44XXX", "branchId": "122105155", "bankId": "", "bankName": "US Bank National Association", "bankAddress": "4811 N 83rd Ave", "bankCity": "Phoenix", "bankRegionCode": "Arizona", "bankPostalCode": "85033", "routeType": "ach", "recipientFees": "1"}], "payoutMethod": "bank-transfer", "primaryCurrency": "USD", "riskScore": null, "merchantId": "M-56eoAaJaeQxphgoUyWLYrw", "inactiveReasons": {}, "taxWithholdingPercentage": null, "taxForm": null, "taxFormStatus": null}, {"id": "R-HXUwKWpmbWfA712H7mcj99", "referenceId": "d9cf1ab1-4eea-4a85-870e-c36bf5e37bf3", "parentRecipientId": null, "email": "sumitmishra041979@gmail.com", "name": "Sumit Mishra", "lastName": "Mishra", "firstName": "Sumit", "legalName": "", "type": "individual", "status": "active", "language": "en", "complianceStatus": "verified", "dob": "1979-01-01", "passport": "", "placeOfBirth": null, "updatedAt": "2023-05-25T09:41:28.084Z", "createdAt": "2023-05-22T04:47:40.639Z", "tags": [], "isPortalUser": false, "taxDeliveryType": "mail", "contactEmails": [], "occupation": "", "address": {"street1": "j-6/117 Chaat house lane, Trim", "street2": "Trimurti Circle", "city": "Jaipur", "postalCode": "302004", "country": "IN", "region": null, "phone": "", "phoneValidated": false}, "compliance": {"status": "verified", "checkedAt": "2023-05-25T09:41:28.085Z"}, "gravatarUrl": "https://www.gravatar.com/avatar/85dd82001dbc208d97fbe2edc12aca7a?d=404", "governmentId": null, "ssn": null, "governmentIds": [], "birthplace": {"country": null, "region": null, "city": null}, "citizenships": [], "routeType": "iach", "routeMinimum": "0.01", "estimatedFees": "4", "accounts": [{"status": "primary", "type": "bank-transfer", "primary": true, "currency": "INR", "id": "A-2fFwd5MQWm7wmLJXLxrMCc", "recipientId": "R-HXUwKWpmbWfA712H7mcj99", "recipientAccountId": "A-2fFwd5MQWm7wmLJXLxrMCc", "disabledAt": null, "recipientReferenceId": "d9cf1ab1-4eea-4a85-870e-c36bf5e37bf3", "deliveryBusinessDaysEstimate": 5, "country": "IN", "iban": "", "accountNum": "************11", "bankAccountType": null, "bankCodeMappingId": null, "accountHolderName": "Sumit Mishra", "swiftBic": "HDFCINBB111", "branchId": "HDFC0005306", "bankId": "", "bankName": "HDFC Bank Ltd", "bankAddress": "j-6/117 Chaat house lane, Trim", "bankCity": "Jaipur", "bankRegionCode": "DH", "bankPostalCode": "302019", "routeType": "iach", "recipientFees": "0"}], "payoutMethod": "bank-transfer", "primaryCurrency": "INR", "riskScore": null, "merchantId": "M-56eoAaJaeQxphgoUyWLYrw", "inactiveReasons": {}, "taxWithholdingPercentage": null, "taxForm": null, "taxFormStatus": null}], "meta": {"page": 1, "pages": 1, "records": 3}}'));
        testData.add(new QB_Test_Data__c(Name='TROLLYWEBHOOK',JSON__c='{"model": "payment", "action": "updated", "body": {"payment": {"id": "P-KEtk9DGu5weQPGwWFHUFW7", "recipient": {"id": "R-VRcRK8YtUqkB7a2keaaApJ", "referenceId": "fecc883a-adb2-487a-b57d-5d477c7e44bc", "parentRecipientId": null, "email": "mcards@torc.dev", "name": "Mike Cardillo", "lastName": "Cardillo", "firstName": "Mike", "legalName": "", "type": "individual", "status": "active", "language": "en", "complianceStatus": "pending", "dob": "1990-01-01", "passport": "", "placeOfBirth": null, "updatedAt": "2023-05-25T06:50:39.276Z", "createdAt": "2023-05-24T10:40:12.633Z", "tags": [], "isPortalUser": false, "taxDeliveryType": "mail", "contactEmails": [], "occupation": "", "address": {"street1": "j-6/117 Chaat house lane, Trim", "street2": "Trimurti Circle", "city": "Jaipur", "postalCode": "99950", "country": "US", "region": null, "phone": "", "phoneValidated": false}, "compliance": {"status": "pending", "checkedAt": null}, "gravatarUrl": "https://www.gravatar.com/avatar/0808df7704cb1346f13b209c88ae6cf8?d=404", "governmentId": null, "ssn": null, "governmentIds": [], "birthplace": {"country": null, "region": null, "city": null}, "citizenships": [], "routeType": "ach", "routeMinimum": "0", "estimatedFees": "1", "accounts": [{"status": "primary", "type": "bank-transfer", "primary": true, "currency": "USD", "id": "A-3vP6CYdRYbPtLJzpL9LEUi", "recipientId": "R-VRcRK8YtUqkB7a2keaaApJ", "recipientAccountId": "A-3vP6CYdRYbPtLJzpL9LEUi", "disabledAt": null, "recipientReferenceId": "fecc883a-adb2-487a-b57d-5d477c7e44bc", "deliveryBusinessDaysEstimate": 5, "country": "US", "iban": "", "accountNum": "**11", "bankAccountType": null, "bankCodeMappingId": null, "accountHolderName": "MikeC", "swiftBic": "USBKUS44XXX", "branchId": "122105155", "bankId": "", "bankName": "US Bank National Association", "bankAddress": "4811 N 83rd Ave", "bankCity": "Phoenix", "bankRegionCode": "Arizona", "bankPostalCode": "85033", "routeType": "ach", "recipientFees": "1"}], "payoutMethod": "bank-transfer", "primaryCurrency": "USD", "riskScore": null, "merchantId": "M-56eoAaJaeQxphgoUyWLYrw", "inactiveReasons": {}, "taxWithholdingPercentage": null, "taxForm": null, "taxFormStatus": null}, "status": "pending", "isSupplyPayment": false, "coverFees": false, "returnedAmount": "0.00", "category": "services", "amount": "400.00", "currency": "USD", "sourceAmount": "400.00", "sourceCurrency": "USD", "targetAmount": "0.00", "targetCurrency": "USD", "taxReportable": true, "taxBasisAmount": "400.00", "taxBasisCurrency": "USD", "withholdingAmount": "0.00", "withholdingCurrency": "USD", "equivalentWithholdingAmount": "0.00", "equivalentWithholdingCurrency": "USD", "exchangeRate": "0", "fees": "1.00", "recipientFees": "1.00", "fxRate": "2", "memo": "", "externalId": "", "processedAt": null, "createdAt": "2023-05-30T06:07:12.130Z", "updatedAt": "2023-05-30T06:07:12.457Z", "forceUsTaxActivity": false, "batch": {"id": "B-XRMEgK1GdyHdtAAHwwdEHA", "status": "open", "tags": [], "amount": "400.00", "currency": "USD", "totalPayments": 1, "description": "Payouts on 30 May 2023 #113", "sentAt": null, "completedAt": null, "createdAt": "2023-05-30T06:07:11.190Z", "updatedAt": "2023-05-30T06:07:12.546Z", "quoteExpiredAt": null}, "checkNumber": null, "tags": [], "merchantFees": "0.00", "compliance": {"status": "pending", "checkedAt": null}, "account": {"status": "primary", "type": "bank-transfer", "primary": true, "currency": "USD", "id": "A-3vP6CYdRYbPtLJzpL9LEUi", "recipientId": "R-VRcRK8YtUqkB7a2keaaApJ", "recipientAccountId": "A-3vP6CYdRYbPtLJzpL9LEUi", "disabledAt": null, "recipientReferenceId": "fecc883a-adb2-487a-b57d-5d477c7e44bc", "deliveryBusinessDaysEstimate": 5, "country": "US", "iban": "", "accountNum": "**11", "bankAccountType": null, "bankCodeMappingId": null, "accountHolderName": "MikeC", "swiftBic": "USBKUS44XXX", "branchId": "122105155", "bankId": "", "bankName": "US Bank National Association", "bankAddress": "4811 N 83rd Ave", "bankCity": "Phoenix", "bankRegionCode": "Arizona", "bankPostalCode": "85033", "routeType": "ach", "recipientFees": "1"}, "payoutMethod": "bank-transfer", "methodDisplay": "Bank Transfer", "initiatedAt": null, "settledAt": null, "returnedAt": null, "returnedReason": [], "returnedNote": null, "estimatedDeliveryAt": null, "merchantId": "M-56eoAaJaeQxphgoUyWLYrw", "taxes": [{"id": "OP-3hr5GzGRD4Sys9NW5MJdxS", "recipientId": "R-VRcRK8YtUqkB7a2keaaApJ", "taxFormId": null, "entered": {"value": "400.00", "currency": "USD"}, "withholding": {"value": "0.00", "currency": "USD"}, "equivalentWithholding": {"value": "0.00", "currency": "USD"}, "amount": "400.00", "currency": "USD", "withholdingAmount": "0.00", "withholdingCurrency": "USD", "equivalentWithholdingAmount": "0.00", "equivalentWithholdingCurrency": "USD", "paymentId": "P-KEtk9DGu5weQPGwWFHUFW7", "externalId": null, "memo": "", "payoutMethod": "bank-transfer", "tags": [], "taxReportable": true, "category": "services", "processedAt": "2023-05-30T06:07:12.066Z", "forceUsTaxActivity": false, "taxWithholdingReason": null, "equivalentUntaxedAmount": {"value": "400.00", "currency": "USD"}, "modifiedSinceCreation": false, "taxPaidByWithholdingAgents": "0", "status": "internal", "enteredAmount": {"value": "400.00", "currency": "USD"}, "updatedAt": "2023-05-30T06:07:12.449Z", "createdAt": "2023-05-30T06:07:12.066Z", "deletedAt": null, "dac7Meta": null}], "errors": [], "routeMinimum": "0", "routeType": "ach"}}}'));
        insert testData;        
        
        
        dfsle__EnvelopeConfiguration__c d=new dfsle__EnvelopeConfiguration__c();
        d.Name='Account MSA Template';
        d.dfsle__EmailSubject__c ='Torc : {!Account.Name} Talent Sourcing Ag';
        insert d;
        account act = setupCustomSettings(currentUser,d);
    
    
        List<Product2> lstProducts=new List<Product2>();
        lstProducts.add(new Product2(name='Freelancer',ProductCode='Freelancer',IsActive=true));
        lstProducts.add(new Product2(name='Transaction Fee',ProductCode='Transaction Fee',IsActive=true));
        lstProducts.add(new Product2(name='Hiring Fee',ProductCode='Hiring Fee',IsActive=true));
        lstProducts.add(new Product2(name='Direct-Hire',ProductCode='Direct-Hire',IsActive=true));
        insert lstProducts;
        id pricebookId=Test.getStandardPricebookId();
        //for(pricebook2 standardPricebook:[Select Id, Name, isActive from pricebook2 where id=:pricebookId AND (name !='Standard Price Book' OR IsActive!=true)])
        {
            Pricebook2 standardPricebook1 = new Pricebook2(Name='Standard Price Book',Id = pricebookId,    IsActive = true);
            update standardPricebook1;
        }
        system.debug('PRICEBOOK');
        system.debug(pricebookId);

        List<PricebookEntry> lstPricebookEntry=new List<PricebookEntry>();
        lstPricebookEntry.add(new PricebookEntry(Pricebook2Id =pricebookId,Product2Id = lstProducts[0].id, UnitPrice=0,isActive=true));
        lstPricebookEntry.add(new PricebookEntry(Pricebook2Id =pricebookId,Product2Id = lstProducts[1].id, UnitPrice=0,isActive=true));
        lstPricebookEntry.add(new PricebookEntry(Pricebook2Id =pricebookId,Product2Id = lstProducts[2].id, UnitPrice=0,isActive=true));
        lstPricebookEntry.add(new PricebookEntry(Pricebook2Id =pricebookId,Product2Id = lstProducts[3].id, UnitPrice=0,isActive=true));
        insert lstPricebookEntry;
        
        
        
        
        
        
        
        if([Select Id from AWS_Sync__c LIMIT 1].size()==0)
        {
            AWS_Sync__c r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='User',Run_From__c=DateTime.Now(),Order__c=1); insert r1;
            r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='JobType',Run_From__c=DateTime.Now(),Order__c=2); insert r1;
            r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='Application',Run_From__c=DateTime.Now(),Order__c=3); insert r1;
            r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='JobOpportunity',Run_From__c=DateTime.Now(),Order__c=4); insert r1;
            r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='Match',Run_From__c=DateTime.Now(),Order__c=5); insert r1;
            r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='History',Run_From__c=DateTime.Now(),Order__c=6); insert r1;
            r1 = new AWS_Sync__c(Table_Name__c='a',Fields__c='',Name='ReferralStatus',Run_From__c=DateTime.Now(),Order__c=7); insert r1;
        }   
        if([Select Id from Docusign_Defaults__c LIMIT 1].size()==0)
        {
            dfsle__GenTemplate__c gt=new dfsle__GenTemplate__c(Name='GTHT');
            insert gt;
            Docusign_Defaults__c r1= new Docusign_Defaults__c(); 
            r1.Docusign_Additional_Agreement__c='111111';
            r1.Docusign_Additional_Assumptions__c='111111';
            r1.DocuSign_Envelope_Template_MSA__c=d.id;
            r1.DocuSign_Gen_Template__c = gt.id;
            r1.DocuSign_Gen_Template_CO__c = gt.id;
            r1.DocuSign_Gen_Template_Talent__c = gt.id;
            r1.DocuSign_Gen_Template_Blue_Yon_Talent__c = gt.id;
            r1.Docusign_Pricing_Description__c='111111';
            r1.Docusign_Terms__c='111111';
            r1.Randstad_Customer_Gen_template__c = gt.id;
            r1.Randstad_Customer_Gen_template_CO__c = gt.id;
            insert r1;     
        }
            QB_Auth__c r1=new QB_Auth__c();
            r1.Access_Token__c='aa';
            r1.Access_Token_Expires_In__c=datetime.now().adddays(5);
            r1.Active__c=true;
            r1.App_Token__c='aa';
            r1.Constants__c = '{"VendorCompanyName":"Torc Freelancer Community","QubikaExpensePaymentAccountRef":{"value":"167","name":"Payment Rails"},"QubikaExpenseLineItemCategoryRef":{"value":"225","name":"220-001 Agent Liabilities - Talent"},';
            r1.Constants__c += '"PONumberDefinitionId":"1","paymentTerms":[{"value":"1","name":"Due on receipt"},{"value":"17","name":"Net 10"},{"value":"2","name":"Net 15"},{"value":"3","name":"Net 30"},{"value":"4","name":"Net 60"}],"MASTERCRMIDDefinitionId":"2","InvoiceItemRef":{"value":"1","name":"Services"},';
            r1.Constants__c += ('"InternalBillCustomerRef":{"value":"'+act.id+'","name":"Torc LLC"},"internalBillCategory":[{"value":"172","name":"Sales & Business Development"},{"value":"162","name":"Capitalized Software Development Costs"},{"value":"12","name":"Advertising & marketing"},{"value":"45","name":"Legal & accounting services"},{"value":"181","name":"Recruiting"},');
            r1.Constants__c += '{"value":"192","name":"Recruiting:Community Incentives"}],"ExpenseEntityRef":{"value":"43","name":"Payment Rails CA Inc"},"ExpenseAccountRef":{"value":"105","name":"General business expenses fees & service charges"},"customerMemo":"Payment Information:Bank Name: JPMorgan Chase Bank National AssociationBank Address: 270 Park Avenue, New York, NY 10017Account Name: Torc, LLCDOMESTICABA Routing: 021000021Account: 932763136INTERNATIONALSwift Code: CHASUS33Account: 932763136","CRMIDDefinitionID":"3","CheckPayment":{"value":"167","name":"Payment Rails"},';
            r1.Constants__c += '"BillItemRef":{"value":"95","name":"Cost of goods sold of labor - COGS"}}';
            r1.OAuth_Key__c='aa';
            r1.oAuth_Secret__c='aa';
            r1.Production__c=true;
            r1.Realm_ID__c='aa';
            r1.Redirect_Uri__c='aa';
            r1.Refresh_Token__c='aa';
            r1.Refresh_Token_Expires_In__c=datetime.now().adddays(5);
            r1.Token_Time__c=datetime.now().adddays(5);
            r1.Trolley_API_Key__c='aa';
            r1.Trolley_Secret__c='aa';
            insert r1;
        Torc_user__c tu= new Torc_user__c(Quick_Books_vendor_id__c='101',name='tutesttu_1',given_Name__c='Sumit',Family_Name__c='Mishra', external_Id__c='tutesttu_1',email__c='sumit+xpp@gmail.com',referralCode__c='refer123',CountryName__c='United States');
        insert tu;
        Torc_user__c tu2= new Torc_user__c(Quick_Books_vendor_id__c='102',name='tutesttu_2',given_Name__c='Aumit',Family_Name__c='Mishra', external_Id__c='tutesttu_2',email__c='amit+xpp@gmail.com',referralCode__c='refer12',referrerCode__c='refer123',CountryName__c='India');
        insert tu2;
        
        Non_Torc_user__c ntu1= new Non_Torc_user__c(Account__c = act.id,name='tutesttu_2',given_Name__c='Aumit',Family_Name__c='Mishra', email__c='amit+ntu@gmail.com', Default_Monthly_Rate__c=500, First_Month__c=Date.newinstance(2023,1,1));
        insert ntu1;
        Account a= getNewAccount();
        
        //QBContstantsSetup qbs=new QBContstantsSetup();
        //qbs.QBCOn.InternalBillCustomerRef.value=a.id;
        //qbs.save();
        RecordType rt=[Select ID from recordType Where Name='Client' LIMIT 1];
        Opportunity opp=getNewOpportunity(a);
        Opportunity opp1=getFreelancerOpportunity(a);
        opp1=getFreelancerOpportunity(a);
        Contact contact=new contact(AccountId=a.id,FirstName='Sumit',LastName='Mishra',Email='eml@abc.cdd', recordtypeid=rt.id);
        insert contact;
        OpportunityContactRole ocr = new OpportunityContactRole(Role='Engagement Supervisor',ContactId = contact.id, OpportunityId =opp1.id);
        insert ocr;
        opp1.StageName='Closed Won';
        update opp1;
       Lead l1=new Lead(FirstName='Sumit',LastName='Mishra',email='sumit@cloud2crowd.com',company='c2c');
       insert l1;
       
       dfsle__Envelope__c dfsle=new dfsle__Envelope__c(dfsle__SourceId__c =act.id,
                                                       dfsle__EnvelopeConfiguration__c =Torc_Constants__c.getInstance().MSA_Template_Id__c);
        upsert dfsle;
        
        dfsle=new dfsle__Envelope__c(dfsle__SourceId__c =opp.id,
                                     dfsle__EnvelopeConfiguration__c =Torc_Constants__c.getInstance().MSA_Template_Id__c,
                                     dfsle__DocuSignId__c='aaaaaaa'
                                     );
        upsert dfsle;
        
        dfsle__EnvelopeStatus__c dfslestat = new dfsle__EnvelopeStatus__c(dfsle__DocuSignId__c='aaaaaaa');
        insert dfslestat;
        
        
        dfsle__EnvelopeStatus__c dfsleEnvelopeStatus=new dfsle__EnvelopeStatus__c(dfsle__SourceId__c=act.id);
        insert dfsleEnvelopeStatus;
        dfsleEnvelopeStatus=new dfsle__EnvelopeStatus__c(dfsle__SourceId__c=opp.id);
        insert dfsleEnvelopeStatus;
        Blob pdfBlob = Blob.valueOf('%PDF-1.4\n%Dummy PDF content for testing\n');

        // Create the attachment record
        Attachment pdfAttachment = new Attachment();
        pdfAttachment.ParentId = act.Id; // Attach to the parent record
        pdfAttachment.Name = 'TestDocument.pdf';
        pdfAttachment.Body = pdfBlob;
        pdfAttachment.ContentType = 'application/pdf';
        insert pdfAttachment;
        
        Torc_Job_Type__c tjt=new Torc_Job_Type__c(name='FRONT END DEVELOPER',external_id__c='tjti');
        insert tjt;
        Torc_Job_Opportunity__c tj = new Torc_Job_Opportunity__c(Name='abc',external_id__c='jext',Torc_job_Type__c=tjt.id, jobTypeId__c=tjt.external_id__c);
        insert tj;
        Torc_match__c tm= new Torc_match__c(Torc_Job_Opportunity__c=tj.id,Torc_User_ref__c = tu.id, External_Id__c='aaaaa',Status__c='MATCHED');
        insert tm;
        opp1.Job_Opportunity__c = tj.id;
        update opp1;
        List<Torc_History__c> l=new List<Torc_History__c>();
        l.add(new Torc_History__c(Torc_Job_Opportunity__c = tj.id,NewValue__c = 'ACTIVE' , Attribute__c='status', External_Id__c='111' ));
        l.add(new Torc_History__c(Torc_Match__c = tm.id,NewValue__c = 'MATCHED' , Attribute__c='status' , External_Id__c='112'));
        l.add(new Torc_History__c(Torc_Match__c = tm.id,NewValue__c = 'APPLIED' , Attribute__c='status' , External_Id__c='113'));
        insert l;        
        
        
    }
}