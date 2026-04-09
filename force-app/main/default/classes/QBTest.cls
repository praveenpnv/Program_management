@isTest //(SeeallData=True)
private class QBTest 
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData();
        testUtils.deactivateVR();
    }

    public static account nonTrocSetupAll()
    {
        Account act = new Account(Name='MyAccount',Payment_terms__c='Net 10',Invoice_Group_Type__c='Combined-Account',Quickbooks_Id__c='1001',recordTypeId=[Select Id from recordtype where DeveloperName='Client' and sObjectType='Account'].id);
        insert act;
        Non_Torc_user__c nt = new  Non_Torc_user__c(Account__c = act.id,Family_Name__c='MMISHRA',Given_Name__c='SSUMIT',Email__c='eemail@eemail.eme',Official_Email__c='eemail@eemail.com',Default_Monthly_Rate__c=100,Quick_Books_Vendor_id__c='1001', First_Month_Amount_Prorated__c=100, Monthly_USD_Expense__c=20,active__c=true,First_Month__c=Date.today().adddays(-1000),Last_Month__c=Date.today().adddays(1000),Engagement_Months__c=12);
        insert nt;  
        nt=[Select  External_Id__c from Non_Torc_user__c where id=:nt.id];
        Trolley_Recipient__c tr=new Trolley_Recipient__c(external_Id__c = nt.External_Id__c, referenceId__c = nt.External_Id__c,Status__c='active',estimated_Fee__c=5);
        insert tr;
        Opportunity opp=new Opportunity(AccountId=act.id,Name='testMethod',CloseDate=date.Today(),StageName='Need Identification');
        opp.RecordTypeId=torc_constants__c.getinstance().torc_record_type__c;
        insert opp;
        Date dt=date.newInstance(date.today().year(),date.today().Month(),1);
        id priceBookID = [Select ID from priceBook2 where Name='Standard Price Book'].Id;
        PricebookEntry pbe = [Select Id, IsActive,Product2Id, Product2.Name, Product2.ProductCode,Product2.Description, UnitPrice
                                from PricebookEntry
                                where Pricebook2Id=:priceBookID AND Product2.Name='Transaction Fee'];
        OpportunityLineitem ol=new OpportunityLineitem(Quantity =1,Product_Type__c ='Transaction fee',OpportunityId=opp.id,Customer_Hourly_Bill_Rate__c=0, 
                                                    priceBookEntryID =pbe.id,Product2Id=pbe.product2Id,UnitPrice=0,
                                                    Engagement_Start_Date__c = dt, Hours_week__c=1);
        insert ol;
        return act;
    }
    @isTest
    private static void nonTrocTest1() 
    {
        Account act = nonTrocSetupAll();
        test.startTest();
        Pagereference pg = Page.QBNonTorcSetup;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id', act.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(act);
        QBNonTorcSetup controller = new QBNonTorcSetup(sc);
        controller.cleanupVandors();
        controller.fnSearch='SS';
        controller.lnSearch='MM';
        QBOpportunitySetup.QBAPITestOperation = 'QUERYVENDOR';
        controller.QBvendoridToUpdate='1';
        controller.TorcmemberidToUpdate=[Select ID from Non_Torc_user__c where account__c=:act.id LIMIT 1].id;
        controller.MapMemberToExtsingQBVendor();
        controller.pageToken();
        QBOpportunitySetup.QBAPITestOperation = 'CREATEVENDOR';
        controller.CreateQBVendor();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYVENDOR';
        controller.SearchVendor();
        controller.createTrolleyId = controller.nontorcuserList[0].usr.id;
        controller.createTrolleyUser();
        controller.DummyCall1();
        controller.getfilterednontorcuserList();
        test.stopTest();
    }
    
   

    private static Internal_Placement__c initialInternalPlacement()
    {
        initialOpty();
        Torc_user__c tu=[Select ID,Quick_Books_vendor_Id__c, Quickbooks_Vendor__c from Torc_user__c LIMIT 1];
        tu.Quick_Books_vendor_Id__c='125';
        tu.Quickbooks_Vendor__c='Sumit Mishra';
        update tu;
        Internal_Placement__c ip = new Internal_Placement__c(Torc_user__c=tu.id, 
                                                            Engagement_Duration_weeks__c=10,
                                                            Engagement_Start_Date__c=Date.today(),
                                                            Hours_Week__c=20,
                                                            Talent_Hourly_Pay_Rate__c=25,
                                                            Category__c = 'Capitalized Software Development Costs');
        insert ip;
        return ip ;                                                   
    }
    private static Engagement_Vacation__c initialEngagementVacation(Internal_Placement__c ip)
    {
        initialOpty();
        Torc_user__c tu=[Select ID,Quick_Books_vendor_Id__c, Quickbooks_Vendor__c from Torc_user__c LIMIT 1];
        tu.Quick_Books_vendor_Id__c='125';
        tu.Quickbooks_Vendor__c='Sumit Mishra';
        update tu;
        Engagement_Vacation__c ev = new Engagement_Vacation__c(Torc_user__c=tu.id, 
                                                            Internal_Placement__c = ip.id,
                                                            Engagement_Duration_weeks__c=2,
                                                            Engagement_Start_Date__c=Date.today().adddays(10),
                                                            Hours_Week__c=20,
                                                            Talent_Hourly_Pay_Rate__c=25,
                                                            Shift_To_Date__c = Date.today().adddays(70));
        insert ev;
        return ev ;                                                   
    }
    private static OpportunityLineItem initialOpty()
    {
        OpportunityLineItem ol=[Select ID, Opportunity.Invoicing_Period__c, Torc_User__c,OpportunityId, Engagement_Start_Date__c, Engagement_Duration_weeks__c,
                                    Torc_User__r.Quick_Books_vendor_Id__c,Torc_User__r.Quickbooks_Vendor__c,Torc_User__r.given_name__c,Torc_User__r.family_name__c,Torc_User__r.external_Id__c,
                                    Torc_User__r.referralCode__c, Torc_User__r.Referrer__c, Torc_User__r.referrerCode__c,
                                    
                                    Opportunity.Invoices_Created__c, Opportunity.Bills_Created__c,Opportunity.PO_Number__c, Opportunity.PO_Required__c,Opportunity.AccountId,
                                    Opportunity.Account.Name,Opportunity.Account.Quickbooks_ID__c, Opportunity.Account.Quickbooks_Customer__c, Opportunity.Account.Invoice_Group_Type__c,Opportunity.Account.Payment_Terms__c
                                from OpportunityLineItem 
                                Where Torc_User__c<>NULL AND Opportunity.IsWon=TRUE And Opportunity.Product_Count__c =1 AND Opportunity.Amount>0
                                Order By Createddate DESC
                                LIMIT 1];
        ol.Engagement_Start_Date__c= Date.NewInstance(2023,4,30);
        ol.Engagement_End_Date__c= Date.NewInstance(2023,5,27);
        ol.Engagement_Duration_weeks__c= 4;
        update ol;
        Account act = ol.Opportunity.Account;
        Opportunity Opp = ol.Opportunity;
        Torc_user__c tUser = ol.Torc_user__r;
        opp.Invoices_Created__c = false;
        opp.Bills_Created__c = false;
        opp.Invoicing_Period__c =null;
        update opp;
        tUser.Family_Name__C='Mishra';
        tUser.Given_Name__C='Sumit';
        tUser.Quick_Books_vendor_Id__c=null;
        tUser.Quickbooks_Vendor__c = null;
        update tUser;
        Trolley_Recipient__c tr=null;
        for(Trolley_Recipient__c tr1:[SELECT Id,external_Id__c,referenceId__c,status__c from Trolley_Recipient__c Where referenceId__c = :tUser.external_Id__c])
            tr=tr1;
        if(tr==NULL)
        {
            tr=new Trolley_Recipient__c(external_Id__c = 'sumitExternalbbahdh', referenceId__c = tUser.external_Id__c,Status__c='active');
            insert tr;
        }   
        else
        {
            tr.Status__c='active';
            update tr;
        }
        
        for(List<trolley_recipient__c> l:[Select ID,Status__C from trolley_recipient__c where Status__C=null OR Status__c=''])
            {
                for(trolley_recipient__c r:l)
                    r.status__c='active';
                update l;    
            }
        act.Name='TorcTest';
        act.Quickbooks_ID__c = NULL;
        act.Quickbooks_Customer__c = NULL;
        act.Invoice_Group_Type__c = 'Individual-Account';//'Combined';
        update act;
        return ol;
    }
    private static void filledOpty(OpportunityLineItem ol, string groupType)
    {
        Account act = ol.Opportunity.Account;
        Opportunity Opp = ol.Opportunity;
        Torc_user__c tUser = ol.Torc_user__r;
        tUser.Quick_Books_vendor_Id__c='100';
        tUser.Quickbooks_Vendor__c = 'sumit mishra';
        update tUser;
        act.Quickbooks_ID__c = '101';
        act.Quickbooks_Customer__c = 'Torc test';
        act.Invoice_Group_Type__c = groupType;
        act.Payment_Terms__c='Net 15';
        update act;
        QB_Test_Data__c qbt=[Select Id,Json__c from QB_Test_Data__c where Name='QUERYINVOICE'];
        qbt.json__c = qbt.Json__c.replace('[MASTERCRMID]', (groupType=='Individual'? act.Id+'-100':act.Id));
        update qbt;
    }
    @isTest
    private static void Test1() 
    {
        test.startTest();
        OpportunityLineItem ol = initialOpty();
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);//System.currentPageReference().getParameters().put('id',opp.id);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        qb.DummyObj.Opportunity__c= ol.OpportunityId;
        qb.RecordSelected();
        qb.searchText='abc';
        QBOpportunitySetup.QBAPITestOperation = 'QUERYACCOUNT';
        qb.Search();
        qb.QBCustomeridToUpdate='1';
        qb.MapAccountToExtsingQBCustomer();
        QBOpportunitySetup.QBAPITestOperation = 'CREATEACCOUNT';
        qb.CreateAccountInQB();
        qb.updatAccount();
        qb.fnSearch=ol.Torc_user__r.given_name__c;
        qb.lnSearch=ol.Torc_user__r.family_name__c;
        qb.TorcmemberidToUpdate=ol.Torc_user__r.id;
        QBOpportunitySetup.QBAPITestOperation = 'QUERYVENDOR';
        qb.SearchVendor();
        qb.QBvendoridToUpdate = '1';
        qb.MapMemberToExtsingQBVendor();
        QBOpportunitySetup.QBAPITestOperation = 'CREATEVENDOR';
        qb.CreateQBVendor();
        qb.UncheckBill();
        qb.UncheckInvoice();
        qb.SaveOpportunityChanges();
        filledOpty(ol,'Individual-Account');
        QBContstantsSetup qbc=new QBContstantsSetup();
        qbc.Save();
        test.stopTest();
        
        
    }
    @isTest
    private static void Test1_1() 
    {
        test.startTest();
        OpportunityLineItem ol = initialOpty();
        Pagereference pg = Page.QBOpportunitySetup;
        opportunity opp = ol.Opportunity;
        opp.Invoicing_Period__c = 'Monthly';
        update opp;
        Test.setCurrentPageReference(pg);//System.currentPageReference().getParameters().put('id',opp.id);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        qb.DummyObj.Opportunity__c= ol.OpportunityId;
        qb.RecordSelected();
        qb.searchText='abc';
        QBOpportunitySetup.QBAPITestOperation = 'QUERYACCOUNT';
        qb.Search();
        qb.QBCustomeridToUpdate='1';
        qb.MapAccountToExtsingQBCustomer();
        QBOpportunitySetup.QBAPITestOperation = 'CREATEACCOUNT';
        qb.CreateAccountInQB();

        qb.updatAccount();
        qb.fnSearch=ol.Torc_user__r.given_name__c;
        qb.lnSearch=ol.Torc_user__r.family_name__c;
        qb.TorcmemberidToUpdate=ol.Torc_user__r.id;
        QBOpportunitySetup.QBAPITestOperation = 'QUERYVENDOR';
        qb.SearchVendor();
        qb.QBvendoridToUpdate = '1';
        qb.MapMemberToExtsingQBVendor();
        QBOpportunitySetup.QBAPITestOperation = 'CREATEVENDOR';
        qb.CreateQBVendor();
        
        qb.UncheckBill();
        qb.UncheckInvoice();
        qb.SaveOpportunityChanges();
        filledOpty(ol,'Individual-Account');
        QBContstantsSetup qbc=new QBContstantsSetup();
        qbc.Save();
        
        test.stopTest();
    }
    @isTest
    private static void Test2() 
    {
        test.startTest();
        OpportunityLineItem ol = initialOpty();
        filledOpty(ol,'Individual-Account');
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id',ol.Opportunity.id);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        try{
        //qb.CreateBillInQB();
        }
        catch(exception ex){}
        try
        {
        //qb.CreateInvoiceInQB();
        }
        catch(exception ex){}
        qb.getShowUpdateInvoice();
        qb.getShowUpdateBills();
        qb.getInvoiceListForUpdate();
        qb.getBillListForUpdate();
        qb.uncheckPastInvoices();
        qb.uncheckPastBills();
        test.stopTest();
        
    }
    @isTest
    private static void Test3() 
    {
        test.startTest();
        OpportunityLineItem ol = initialOpty();
        filledOpty(ol,'Individual-Account');
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id',ol.Opportunity.id);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYINVOICE';
        qb.SearchExistingInvoices();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYBILL';
        qb.SearchExistingBills();
        qb.UpsertInvoiceinQB();
        qb.UpsertBillsinQB();
        test.stopTest();
    }
    @isTest
    private static void Test4() 
    {
        test.startTest();
        OpportunityLineItem ol = initialOpty();
        filledOpty(ol,'Individual-Account');
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id',ol.Opportunity.id);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        qb.ExistingInvoices = qb.Invoices;
        qb.ExistingInvoices[0].getSalesLine();
        qb.ExistingInvoices[0].getUpdateStyle();
        qb.ExistingInvoices[0].mergeLines(qb.ExistingInvoices[0].Line);
        qb.ExistingInvoices[0].Line[0].getUpdateStyle();
        qb.ExistingBills = qb.Bills;
        if(qb.ExistingBills.size()>0)
        {
        qb.ExistingBills[0].getUpdateStyle();
        qb.ExistingBills[0].mergeLines(qb.ExistingBills[0].Line);
        }
        QBHttpService z= new QBHttpService('', QBHttpService.API_TYPE.ACCOUNTING,true);
        QB_HttpMock h=new QB_HttpMock();
        HttpResponse res= h.respond(new HttpRequest());
        z.buildResponseException(res);
        test.stopTest();
    }
    @isTest
    private static void Test5() 
    {
        test.startTest();
        QBoAuth qbo=new QBOAuth('client_id', 'secret', 'scope', 'www.torc.dev') ;
        qbo.getLoginUrl();
        qbo.authenticate('abc');
        qbo.refreshToken('abc');
        qbo.revokeToken('abc');
        QBoAuth.AuthResponse au=new QBoAuth.AuthResponse();
        au.getAccessTokenExpiry();
        au.getRefreshTokenExpiry();
        
        Pagereference pg = Page.QBRedirect;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('code','code');
        System.currentPageReference().getParameters().put('realmId','realmId');
        System.currentPageReference().getParameters().put('state','state');
        QBRedirectController qbr = new QBRedirectController();
        qbr.getLoginUrl();
        qbr.parseCode();
        QBServiceException qbe=new QBServiceException();
        qbe.persistInDb();
        
        
        QB_Authentication qba=new QB_Authentication();
        qba.initializeToken();
        qba.qbAuth.Refresh_Token__c='aaaa';
        qba.persistTokenInDb();
        qba.isTokenValid(DateTime.now());
        test.stopTest();
    }
    @isTest
    private static void Test6() 
    {
        
        QB_API_Call__c qb = new  QB_API_Call__c(Name='invoice',Input__c = '{}');
        List<QB_Api_call__c> lst=new List<QB_Api_call__c>();
        lst.add(qb);
        try
        {
        QBOpportunitySetup.CallQBAPI(lst);
        }
        catch(exception ex)
        {}
    }
    @isTest
    private static void Test7() 
    {
        test.startTest();
        Account act=[SELECT ID from Account WHere Invoice_Group_Type__c=NULL limit 1];
        Pagereference pg = Page.QBBulkInvoiceUpdate;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id',act.id);
        QBBulkInvoiceUpdate qbi=new QBBulkInvoiceUpdate();
        qbi.pageToken();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYINVOICE';
        OpportunityLineItem ol = initialOpty();
        qbi.filterForUpdateInvoice();
        filledOpty(ol,'Individual-Account');
        qbi.fromDate.Account__c = ol.opportunity.AccountId;
        qbi.filterForUpdateInvoice();
        qbi.getpaymenttermsOptions();    
        
        qbi.filterForInvoice();
        //qbi.validateData();
        
        qbi.filterForDeleteInvoice();
        qbi.filterForUpdateInvoice();
        qbi.SaveDelete();
        qbi.SaveUpdate();
        qbi.filterForCrossCheck();
        test.stopTest();
    }
    @isTest
    private static void Test8() 
    {
        test.startTest();
        Internal_Placement__c ol = initialInternalPlacement();
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        qb.DummyObj.Internal_Placement__c= ol.id;
        qb.RecordSelected();
        test.stopTest();
    }
    @isTest
    private static void Test9() 
    {
        test.startTest();
        Internal_Placement__c ol = initialInternalPlacement();
        Engagement_vacation__c ev = initialEngagementVacation(ol);
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);
        QBOpportunitySetup qb= new QBOpportunitySetup();
        qb.DummyObj.Vacation__c= ev.id;
        qb.RecordSelected();
        
        ev.Engagement_Start_Date__c = ev.Engagement_Start_Date__c.adddays(5);
        ev.Engagement_Duration_weeks__c +=1;
        ev.Shift_To_Date__c =ev.Shift_To_Date__c.adddays(7);
        update ev;
        
        ev.Engagement_Duration_weeks__c +=1;
        update ev;
        test.stopTest();
    }
    @isTest
    private static void Test10() 
    {
        test.startTest();
        Internal_Placement__c ol = initialInternalPlacement();
        ol.Engagement_Duration_weeks__c=ol.Engagement_Duration_weeks__c+1;
        update ol;
        delete ol;
        test.stopTest();
    }
    @isTest
    private static void Test11() 
    {
        test.startTest();
        Pagereference pg = Page.QBBulkBillUpdate;
        Test.setCurrentPageReference(pg);
        Torc_user__c tu = [Select ID from Torc_User__c where Quick_Books_vendor_id__c!=NULL LIMIT 1];
        System.currentPageReference().getParameters().put('id',tu.id);
        QBBulkBillUpdate qbi=new QBBulkBillUpdate();
        qbi.pageToken();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYBILL';
        OpportunityLineItem ol = initialOpty();
        test.stopTest();
    }
    @isTest
    private static void Test12() 
    {
        test.startTest();
        Pagereference pg = Page.QBBulkBillUpdate;
        Test.setCurrentPageReference(pg);
        QBBulkBillUpdate qbi=new QBBulkBillUpdate();
        qbi.pageToken();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYBILL';
        OpportunityLineItem ol = initialOpty();
        filledOpty(ol,'Individual-Account');
        
        qbi.filterForUpdateBill();
        qbi.filterForBill();
        qbi.filterForDeleteBill();
        qbi.filterForUpdateBill();
        qbi.lstDataRow[0].bill.selectedRow=true;
        qbi.SaveDelete();
        qbi.SaveUpdate();
        
        qbi.lstDataRow[0].getEditable();
        test.stopTest();
    }
    @isTest
    private static void Test13() 
    {
        test.startTest();
        OpportunityLineItem ol = initialOpty();
        filledOpty(ol, 'Individual-Account');
        
        Pagereference pg = Page.TrolleyPayments;
        Test.setCurrentPageReference(pg);
        TrolleyPayments trolley=new TrolleyPayments();
        trolley.pageToken();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYBILL';
        trolley.fromDate.Date__c = Date.newInstance(2021,1,1);
        trolley.toDate.date__c = Date.newInstance(2025,1,1);
        trolley.filter();
        for(TrolleyPayments.DataRow row:trolley.lstDatarow)
        {
            row.getTotal();
            row.nonErrorRowCount();
            if(row.rowType=='bill')
                row.updateTorcUser();
            if(!row.getIsError())
            {
                row.chk=true;
            }
            else
            {
                system.debug('BHUJIYA');
                system.debug(row);
            }
        }
        trolley.getShowTypes();
        trolley.getshowableRows();
        trolley.Next();
        for(TrolleyPayments.processedRow pr:trolley.processedRows)
        {
            pr.tInv.Cover_Fee__c = true;
            pr.getRealname();
        }
        trolley.CreatePaymentsInTrolleyNew();
        trolley.reloadRecipient();
        List<Trolley_Invoice__c> l=[Select ID, Cover_Fee__c,Payment_Status__c,Trolley_Invoicing_payment_Id__c from Trolley_Invoice__c Where Payment_Status__c!='processed' LIMIT 2];
        l[0].Trolley_Invoicing_payment_Id__c='P-KEtk9DGu5weQPGwWFHUFW7';
        update l;
        trolleyWebhook.doPost();
        trolleyWebhook.dummy();
        l=[Select ID, Cover_Fee__c,Payment_Status__c from Trolley_Invoice__c Where Payment_Status__c!='processed' LIMIT 2];
       
        
        PageReference pageRef = Page.trolleyInvoiceUpdate;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id', l[0].id);
        ApexPages.StandardController sc = new ApexPages.StandardController(l[0]);
        trolleyInvoiceUpdate rec = new trolleyInvoiceUpdate(sc);
        rec.toggleCoverFee();
        l[0].Cover_Fee__c = true;
        update l[0];
        for(Trolley_Invoice__c t:l)
            t.Payment_Status__c='processed';
        update l;

        Trolley_Invoice__c ti=[Select ID , Torc_user__c,Non_torc_user__c, Payment_Status__c from Trolley_Invoice__c LIMIT 1];
        ti.Payment_Status__c = 'ABC';
        ti.Torc_user__c=NULL;
        ti.Non_torc_user__c = [Select ID from Non_torc_user__c LIMIT 1].id;
        update ti;
        ti.Payment_Status__c = 'processed';
        try{
        update ti;}
        catch(exception ex)
        {}
        
        QB_test_data__c qbt=new QB_test_data__c(Name='PAYPALWEB');
        ti=[Select ID, trolley_Invoicing_Payment_Id__c from Trolley_Invoice__c LIMIT 1];
        jsonBodyFortest = '{"id":"I","event_version":"1.0","create_time":"2023-06-13T06:30:06.609Z","resource_type":"payouts","event_type":"PAYMENT.PAYOUTSBATCH.PROCESSING","summary":"Payouts batch is getting processed.","resource":{"batch_header":{"payout_batch_id":"[BATCH_ID]","batch_status":"PROCESSING","time_created":"2023-06-13T06:29:57Z","time_completed":"2023-06-13T06:29:59Z","sender_batch_header":{"sender_batch_id":"d7288ad227fd48a587ea3f1efb286c1a"},"funding_source":"BALANCE","amount":{"currency":"USD","value":"600.00"},"fees":{"currency":"USD","value":"0.25"},"payments":1},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/payouts/C8ACA3NMABHU2","rel":"self","method":"GET","encType":"application/json"}]},"links":[{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-8Y482460A72009223-5BY51952YN505262M","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-8Y482460A72009223-5BY51952YN505262M/resend","rel":"resend","method":"POST"}]}';
        qbt.JSON__c = jsonBodyFortest;
        upsert qbt;
        trolleyPaypalWebhook.doPost();
        trolleyPaypalWebhook.dummy();
        jsonBodyFortest = '{"id":"I","event_version":"1.0","create_time":"2023-06-14T06:30:06.609Z","resource_type":"payouts","event_type":"PAYMENT.PAYOUTSBATCH.PROCESSING","summary":"Payouts batch is getting processed.","resource":{"batch_header":{"payout_batch_id":"[BATCH_ID]","batch_status":"PROCESSING","time_created":"2023-06-13T06:29:57Z","time_completed":"2023-06-13T06:29:59Z","sender_batch_header":{"sender_batch_id":"d7288ad227fd48a587ea3f1efb286c1a"},"funding_source":"BALANCE","amount":{"currency":"USD","value":"600.00"},"fees":{"currency":"USD","value":"0.25"},"payments":1},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/payouts/C8ACA3NMABHU2","rel":"self","method":"GET","encType":"application/json"}]},"links":[{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-8Y482460A72009223-5BY51952YN505262M","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-8Y482460A72009223-5BY51952YN505262M/resend","rel":"resend","method":"POST"}]}';
         qbt.JSON__c = jsonBodyFortest;
        upsert qbt;
        trolleyPaypalWebhook.doPost();
        Trolley_Paypal_Batch__c b=[Select Status__C from Trolley_Paypal_Batch__c where Name='[BATCH_ID]' LIMIT 1];
        b.Process_in_QB__c=true;
        update b;
        test.Stoptest();
        jsonBodyFortest = '{"id":"WH-7B579021S8829981U-15B28570H84243323","event_version":"1.0","create_time":"2023-06-13T06:51:16.131Z","resource_type":"payouts_item","event_type":"PAYMENT.PAYOUTS-ITEM.UNCLAIMED","summary":"A payout item is unclaimed","resource":{"transaction_id":"94N19387YT7358044","payout_item_fee":{"currency":"USD","value":"0.25"},"transaction_status":"UNCLAIMED","sender_batch_id":"72e1aaea0f35c6975c4d5a92c0a5cc45","time_processed":"2023-06-13T06:51:02Z","activity_id":"1DP1900917255863P","payout_item":{"recipient_type":"EMAIL","amount":{"currency":"USD","value":"600.00"},"note":"Kia 6/11/2023 - 6/17/2023","receiver":"sumit@cloud2crowd.com","sender_item_id":"[PAYMENTID]","recipient_wallet":"PAYPAL"},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/payouts-item/8W7T5L5KEWXNU","rel":"self","method":"GET","encType":"application/json"},{"href":"https://api.sandbox.paypal.com/v1/payments/payouts/UXXGNEUELEBLU","rel":"batch","method":"GET","encType":"application/json"}],"payout_item_id":"[PAYOUTITEMID]","payout_batch_id":"[BATCT_ID]","errors":{"name":"RECEIVER_UNREGISTERED","message":"The recipient for this payout does not have an account. A link to sign up for an account was sent to the recipient. However, if the recipient does not claim this payout within 30 days, the funds will be returned to your account.","information_link":"https://developer.paypal.com/docs/api/payments.payouts-batch/#errors","details":[],"links":[]}},"links":[{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-7B579021S8829981U-15B28570H84243323","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-7B579021S8829981U-15B28570H84243323/resend","rel":"resend","method":"POST"}]}';
        jsonBodyFortest = jsonBodyFortest.replace('[PAYMENTID]',ti.trolley_Invoicing_Payment_Id__c);
         qbt.JSON__c = jsonBodyFortest;
        upsert qbt;
        trolleyPaypalWebhook.doPost();
   
        string jsonBodyFortest = '{"id":"WH-7B579021S8829981U-15B28570H84243323","event_version":"1.0","create_time":"2023-06-14T06:51:16.131Z","resource_type":"payouts_item","event_type":"PAYMENT.PAYOUTS-ITEM.UNCLAIMED","summary":"A payout item is unclaimed","resource":{"transaction_id":"94N19387YT7358044","payout_item_fee":{"currency":"USD","value":"0.25"},"transaction_status":"UNCLAIMED","sender_batch_id":"72e1aaea0f35c6975c4d5a92c0a5cc45","time_processed":"2023-06-13T06:51:02Z","activity_id":"1DP1900917255863P","payout_item":{"recipient_type":"EMAIL","amount":{"currency":"USD","value":"600.00"},"note":"Kia 6/11/2023 - 6/17/2023","receiver":"sumit@cloud2crowd.com","sender_item_id":"[PAYMENTID]","recipient_wallet":"PAYPAL"},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/payouts-item/8W7T5L5KEWXNU","rel":"self","method":"GET","encType":"application/json"},{"href":"https://api.sandbox.paypal.com/v1/payments/payouts/UXXGNEUELEBLU","rel":"batch","method":"GET","encType":"application/json"}],"payout_item_id":"[PAYOUTITEMID]","payout_batch_id":"[BATCT_ID]","errors":{"name":"RECEIVER_UNREGISTERED","message":"The recipient for this payout does not have an account. A link to sign up for an account was sent to the recipient. However, if the recipient does not claim this payout within 30 days, the funds will be returned to your account.","information_link":"https://developer.paypal.com/docs/api/payments.payouts-batch/#errors","details":[],"links":[]}},"links":[{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-7B579021S8829981U-15B28570H84243323","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-7B579021S8829981U-15B28570H84243323/resend","rel":"resend","method":"POST"}]}';
        jsonBodyFortest = jsonBodyFortest.replace('[PAYMENTID]',ti.trolley_Invoicing_Payment_Id__c);
        qbt.JSON__c = jsonBodyFortest;
        upsert qbt;
        
        trolleyPaypalWebhook.doPost();
        
    }
    @isTest
    private static void Test14() 
    {
        test.startTest();
        QBAccountingService.QBPurchase qbp=new QBAccountingService.QBPurchase();
        qbp.id='1';
        qbp.SyncToken='111';
        QBAccountingService.QBPurchaseLine qbl= new QBAccountingService.QBPurchaseLine();
        qbl.id='11';
        QBAccountingService.QBLinkedTxn a2= new QBAccountingService.QBLinkedTxn();
        a2.TxnLineId='aa';
        QBAccountingService.QBBillPayment a1 = new QBAccountingService.QBBillPayment();
        a1.SyncToken='s';
        a1.id='s';
        a1.DocNumber='s';
        a1.PrivateNote='s';
        QBAccountingService.QBPrivateNote qp=new QBAccountingService.QBPrivateNote();
        qp.CRMID='11';
        Log_Api__e l = new Log_Api__e(Type__c='a',Parent__c='a');
        EventBus.publish(l);
        test.stoptest();
    }
    public static string jsonBodyFortest;
    @isTest
    private static void TestReferral() 
    {
        test.startTest();
        OpportunityLineItem oLine= [Select 
                Id, OpportunityId, PricebookEntryId, Product2Id, ProductCode, Name, Quantity, UnitPrice, ListPrice, ServiceDate, Description, Customer_Hourly_Bill_Rate__c, Engagement_Duration_weeks__c, Weekly_Bill_Rate__c, Engagement_Start_Date__c, Torc_User__c, Talent_Hourly_Pay_Rate__c, Talent_Name__c, Weekly_Talent_Rate__c, Talent_Username__c, Engagement_End_Date__c, Product_Code_Text__c, Hours_Week__c, Product_Type__c, Product_Category__c
                 from OpportunityLineItem 
                 where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=TRUE And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];

        torc_User__c tUser = new torc_User__c(id=oLine.Torc_User__c);
        tUser.Quick_Books_vendor_Id__c='101';
        tUser.Quickbooks_Vendor__c = '101';
                
        Torc_User__C tUserreferrer=[Select ID,referralCode__c, Referrer__c, referrerCode__c,Quick_Books_vendor_Id__c,Quickbooks_Vendor__c from Torc_User__c where id <> :tUser.Id LIMIT 1];
        tUserreferrer.referralCode__c='SUMITETSTMETHOD';
        tUser.Quick_Books_vendor_Id__c='126';
        tUser.Quickbooks_Vendor__c = '11';
        update tUserreferrer;
        tUser.referrerCode__c = 'SUMITETSTMETHOD';
        update tUser;
        oLine= [Select 
                Id, OpportunityId, PricebookEntryId, Product2Id, ProductCode, Name, Quantity, UnitPrice, ListPrice, ServiceDate, Description, Customer_Hourly_Bill_Rate__c, Engagement_Duration_weeks__c, Weekly_Bill_Rate__c, Engagement_Start_Date__c, Torc_User__c, Talent_Hourly_Pay_Rate__c, Talent_Name__c, Weekly_Talent_Rate__c, Talent_Username__c, Engagement_End_Date__c, Product_Code_Text__c, Hours_Week__c, Product_Type__c, Product_Category__c
                 from OpportunityLineItem 
                 where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND Opportunity.StageName!='Close Lost'  And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
        Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified');
        update opp;
        tUser = new torc_User__c(id=oLine.Torc_User__c);
        tUser.Quick_Books_vendor_Id__c='101';
        tUser.Quickbooks_Vendor__c = '101';
                
        for(List<referral_Bonus__C> l:[Select ID from referral_Bonus__C where Referred_To__c = :tUser.id])
            delete l;
        Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Closed Won');
        update opp;
        Pagereference pg = Page.QBOpportunitySetup;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('forreferral','1');
        
        QBOpportunitySetup qb= new QBOpportunitySetup();
        qb.toggleskipnonQBvendors();
        for(QBAccountingService.QBBill invoice : qb.ExistingBills)
        {
            invoice.selectedRow=TRUE;   
        }
        QBOpportunitySetup.QBAPITestOperation = 'QUERYBILL';
        qb.SearchExistingBills();
        test.stopTest();
        //qb.UpsertBillsinQB();
    }
    
    @isTest
    private static void testX() 
    {
        TrolleyService.T_recipientRefUp tRec = new TrolleyService.T_recipientRefUp();
        tRec.id  = 'R-UtnV52L82c8Po8PtRaFsGk';
        tRec.referenceId = 'sumit+abrilgiebert25@gmail.com';
        try
        {
        TrolleyService.updateRecipientreferenceId(tRec);
        }
        catch(exception ex){}
    }
    
    @isTest
    private static void testQBPlacementBill() 
    {
        test.startTest();
        Pagereference pg = Page.QBPlacementCompare;
        Placement__c pc=[Select id, Torc_user__c from Placement__c where Account__c !=NULL 
        and Torc_user__r.Quick_Books_vendor_id__c !=NULL 
        and Account__r.Quickbooks_ID__c!=NULL
        LIMIT 1];
        Test.setCurrentPageReference(pg);
        Torc_user__c tu = [Select ID from Torc_User__c where id=:pc.Torc_user__c LIMIT 1];
        System.currentPageReference().getParameters().put('id',pc.id);
        ApexPages.StandardController sc=new ApexPages.StandardController(pc);
        QBPlacementCompare qbi=new QBPlacementCompare(sc);
        qbi.pageToken();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYBILL';
        OpportunityLineItem ol = initialOpty();
        qbi.loadBoth();
        QBOpportunitySetup.QBAPITestOperation = 'QUERYINVOICE';
        qbi.loadBoth();
        test.stopTest();
    }
    @isTest
    private static void testQubikaPage()
    {
        qubika q=new qubika();
        q.loadpaymentCSV();
        q.nonTorcTrolleySetup();
        q.loadUserGoogle();
        q.loadPaymentGoogle();
        q.DoPayment();
    }
}