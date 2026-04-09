Public class QBOpportunitySetup
{
    public decimal talentTransferPricePercent=0;
    public integer masterCRMIDFieldNumber{get;set;}
    public static string QBAPITestOperation=NULL;
    public boolean skipnonQBvendors{get;set;}
    public boolean loadAllBills{get;set;}
    public boolean loadAllinvoices{get;set;}
    public decimal ExistingBillSum{get;set;}
    public decimal ExistingLocalreferralBillSum{get;set;}
    public decimal ExistingInvoiceSum{get;set;}
    Public set<string> MasterCRMIDs{get;set;}
    Public set<string> MasterCRMIDsNEW{get;set;}
    
    Public set<string> MasterLocalreferralCRMIDs{get;set;}
    Public Opportunity opp{get;set;}
    Public Internal_Placement__c internalPlacement{get;set;}
    Public Engagement_Vacation__c Vacation{get;set;}
    Public Account act{get;set;}
    public string actNameInDescription{get;set;}
    Public Account localReferralAct{get;set;}
    Public String Step{get;set;}
    Public Boolean SearchDone{get;set;}
    public List<QBAccountingService.QBInvoice> Invoices{get;set;}
    Public Decimal totalInvoiceAmount{get;set;}
    Public Decimal totalMemberPayment{get;set;}
    public List<QBAccountingService.QBBill> Bills{get;set;}
    public List<QBAccountingService.QBBill> localReferralBills{get;set;}
    Public List<Torc_User__c> torcuserList{get;set;}
    Private Map<string,Torc_user__c> mapTotcusers = new Map<string,Torc_user__c> ();
    Public QBContstantsSetup ContstantsSetup{get;set;}
    Public List<Payment_Date__c> lstPaymentDates;
    Public Set<String> vendorIdsListINV{get;set;}
    Public Set<String> vendorIdsListBIL{get;set;}
    Public Set<String> vendorIdsListONLYBIL{get;set;}
    
    Public Set<String> vendorIdsListLocalreferralBIL{get;set;}
    public list<Referral_Bonus__c> lstreferalBonuses=new list<Referral_Bonus__c>();
    public boolean noRecord{get;set;}
    private string recordId{get;set;}
    public Dummy_Object__c DummyObj{get;set;}
    public string operationon{get;set;}
    public boolean forTransactionFee{get;set;}
    Public QBOpportunitySetup()
    {
        latestInvoiceNumber=0;
        invoicingPeriod = '';
        invoicingUnit ='';
        mismatchedInvoicingEmail='';
        skipnonQBvendors = false;
        ContstantsSetup = NEW QBContstantsSetup();
        operationon='';
        loadAllinvoices = loadAllBills=true;
        ExistingInvoiceSum = ExistingBillSum=ExistingLocalreferralBillSum=0;
        vendors = new List<QBAccountingService.QBVendor>();
        lstPaymentDates=[Select Date__c from Payment_Date__c Order By Date__c];
        DummyObj = new Dummy_Object__c();
        noRecord=true;
        recordId = ApexPages.currentPage().getParameters().get('id');
        
        if(recordId!=NULL && recordId!='')
        {
            operationon = 'OPP';
            noRecord=false;
            setupWithRecord();
        }
        else
        {
            recordId = ApexPages.currentPage().getParameters().get('internalid');
            if(recordId!=NULL && recordId!='')
            {
                operationon = 'INTERNAL';
                noRecord=false;
                setupWithRecord();
            }
            else
            {
                recordId = ApexPages.currentPage().getParameters().get('vacationid');
                if(recordId!=NULL && recordId!='')
                {
                    operationon = 'VACATION';
                    noRecord=false;
                    setupWithRecord();
                }
                else
                {
                    recordId = ApexPages.currentPage().getParameters().get('forreferral');
                    if(recordId=='1')
                    {
                        operationon = 'REFERRAL';
                        noRecord=false;
                        setupWithRecord();
                    }
                }
            }
        }
    }
    Public void RecordSelected()
    {
        if(DummyObj.Opportunity__c!=NULL)
        {
            recordId = DummyObj.Opportunity__c;
            noRecord=false;
            operationon = 'OPP';
            setupWithRecord();
        }
        else if(DummyObj.Internal_Placement__c!=NULL)
        {
            recordId = DummyObj.Internal_Placement__c;
            noRecord=false;
            operationon = 'INTERNAL';
            setupWithRecord();
        }
        else if(DummyObj.Vacation__c!=NULL)
        {
            recordId = DummyObj.Vacation__c;
            noRecord=false;
            operationon = 'VACATION';
            setupWithRecord();
        }
        else
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select Opportunity Or Vendor'));
        }
    }
    public string invoicingPeriod{get;set;}
    public string invoicingUnit{get;set;}
    private boolean usePayRateToInvoice = false;
    Public void setupWithRecord()
    {     
        actNameInDescription = '';
        if(operationon=='REFERRAL')
        {
            act = getAccount(ContstantsSetup.QBCOn.InternalBillCustomerRef.value);    
        }   
        else if(operationon=='OPP')
        {
            opp = new Opportunity(id=recordId);
            opp=[Select  Torc_External_Id__c, Use_Pay_Rate_To_Invoice__c, Invoice_To_Randstad_Account__c, Invoicing_Unit__c,Invoicing_Period__c, Email_Address_for_Invoices__c , ID,Name, First_Invoice__c, PO_Number__c, PO_Required__c, AccountId,Account.Name, Amount,Total_Payment__c, Invoices_Created__c, Bills_Created__c,    
                   (Select ID, Engagement_Start_Date__c, Engagement_End_Date__c, Weekly_Bill_Rate__c, Total_Payment__c, TotalPrice,
                        Talent_Name__c, Talent_Username__c, Engagement_Duration_weeks__c, Weekly_Talent_Rate__c 
                        , Customer_Hourly_Bill_Rate__c, Hours_Week__c,ProductCode,bank_fee__c, Talent_Hourly_Pay_Rate__c
                        From OpportunityLineItems 
                        Where Product_Type__C!=:Torc_Constants__c.getInstance().Hiring_Product__c
                        Order By Engagement_Start_Date__c)
            From Opportunity Where Id=:opp.Id];
            usePayRateToInvoice = opp.Use_Pay_Rate_To_Invoice__c;
            if(opp.Invoice_To_Randstad_Account__c != NULL)
            {
                act = getAccount([Select ID from Account Where Name=:opp.Invoice_To_Randstad_Account__c LIMIT 1].id);
                actNameInDescription = opp.Account.Name;
            }
            else    
                act = getAccount(opp.AccountId);
            
            localReferralAct = getAccount(ContstantsSetup.QBCOn.InternalBillCustomerRef.value);    
            searchText = act.Name; 
            invoicingPeriod = opp.Invoicing_Period__c;
            invoicingUnit = opp.Invoicing_Unit__c;
        }
        else 
        {
            if(operationOn=='INTERNAL')
            {
                InternalPlacement = [SELECT Category__c , Bill_Prefix__c, Id, Torc_user__r.Name, Name, Torc_User__c, Engagement_Duration_weeks__c, Talent_Hourly_Pay_Rate__c, User_Name__c,
                                    Engagement_End_Date__c, Hours_Week__c, Weekly_Talent_Rate__c, Engagement_Start_Date__c 
                                    from Internal_Placement__c WHERE id=:recordId];
                localReferralAct = act = getAccount(ContstantsSetup.QBCOn.InternalBillCustomerRef.value);
               
            }
            else
            {
                vacation= [SELECT Id, Name, Engagement_Start_Date__c, Engagement_Duration_weeks__c, Hours_Week__c, 
                            Engagement_End_Date__c, Weekly_Talent_Rate__c, Torc_user__r.Name,
                            Torc_User__c, Opportunity__c, Internal_Placement__c, 
                            Shift_To_Date__c, Shift_To_End_Date__c, User_Name__c, 
                            Weekly_Bill_Rate__c,Talent_Hourly_Pay_Rate__c,Customer_Hourly_Bill_Rate__c,
                            Internal_Placement__r.Category__c,Internal_Placement__r.Bill_Prefix__c, Opportunity__r.Torc_External_Id__c,
                            Opportunity__r.Invoice_To_Randstad_Account__c,Opportunity__r.Email_Address_for_Invoices__c,Opportunity__r.PO_Number__c,Opportunity__r.PO_Required__c,Opportunity__r.AccountId,
                            Opportunity__r.Use_Pay_Rate_To_Invoice__c,Opportunity__r.invoicing_Period__c,opportunity__r.invoicing_Unit__c,Opportunity__r.Account.Name,
                            QB_Bills_Updated__c, QB_Invoice_Updated__c
                            From Engagement_Vacation__c
                            Where id=:recordId];
                internalPlacement = vacation.Internal_Placement__r;  
                opp = vacation.Opportunity__r;  
                id actId;
                if(opp!=NULL)
                {
                    invoicingPeriod = opp.invoicing_Period__c;
                    InvoicingUnit = opp.invoicing_Unit__c;
                    if(opp.Invoice_To_Randstad_Account__c!=NULL)
                        actNameInDescription = opp.Account.Name;
                    usePayRateToInvoice = opp.Use_Pay_Rate_To_Invoice__c;    
                }
                actId = vacation.Opportunity__c!=NULL?(vacation.Opportunity__r.Invoice_To_Randstad_Account__c!=NULL?
                            [Select ID from Account Where Name=:opp.Invoice_To_Randstad_Account__c LIMIT 1].id 
                            :vacation.Opportunity__r.AccountId):ContstantsSetup.QBCOn.InternalBillCustomerRef.value;
                act = getAccount(actId);          
            }                                                           
        }  
        resetup();        
    }
    public void resetup()
    {
        forTransactionFee=false;
        mismatchedInvoicingEmail = '';
        existingInvoices = new List<QBAccountingService.QBInvoice>();
        existingBills = new List<QBAccountingService.QBBill>();
        existinglocalReferralBills = new List<QBAccountingService.QBBill>();
        ContstantsSetup = NEW QBContstantsSetup();
        masterCRMIDFieldNumber = Integer.valueOf(ContstantsSetup.QBCOn.MASTERCRMIDDefinitionID)-1;
        torcUserList = new List<Torc_User__c>();      
        Invoices = New List<QBAccountingService.QBInvoice>();
        Bills = new List<QBAccountingService.QBBill>();
        localReferralBills = new List<QBAccountingService.QBBill>();
        customers = new List<QBAccountingService.QBCustomer>();
        vendors = new List<QBAccountingService.QBVendor>();
        SearchDone= false;
        Step='';
        set<string> userNames = new set<string>();
        set<string> userNamesOnlyBILLS = new set<string>();
        system.debug(operationon);
        if(operationon=='REFERRAL')
        {
            lstreferalBonuses=[SELECT ID, referral_Payment_Created__c, referrer_Payment_Created__c, Referred_To__r.Quick_Books_vendor_Id__c,Referred_by__r.Quick_Books_vendor_Id__c,
                                        Payment_Week__c, Referral_Amount__c, Referrer_Amount__c,
                                        Referred_By__c, Referred_By__r.Name,Referred_By__r.Full_Name__c,
                                        Referred_To__c, Referred_To__r.Name,Referred_To__r.Full_Name__c
                                       FROM  Referral_Bonus__c WHERE (referral_Payment_Created__c=FALSE OR referrer_Payment_Created__c=FALSE)];        
            for(Referral_Bonus__c rb:lstreferalBonuses)
            {
                if(!rb.referral_Payment_Created__c)
                {
                    userNames.add(rb.Referred_To__r.Name.toLowercase());  
                    userNamesOnlyBILLS.add(rb.Referred_To__r.Name.toLowercase());    
                }    
                if(!rb.referrer_Payment_Created__c) 
                {
                    userNames.add(rb.Referred_By__r.Name.toLowercase()); 
                    userNamesOnlyBILLS.add(rb.Referred_By__r.Name.toLowercase());    
                }    
            } 
            system.debug(userNames);  
            system.debug(userNamesOnlyBILLS);  
                                                     
        }
        else if(operationon=='OPP')
        {
            if(opp.PO_Required__c=='Yes' && (opp.PO_Number__c==NULL || opp.PO_Number__c.length()<=1))
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please update a valid PO Number on Opportunity.'));
                return;
            }
            if(act.Invoice_Group_Type__c==NULL)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please update a Invoice Group Type on account.'));
                return;
            }
            for(OpportunityLineItem oli:opp.OpportunityLineItems)
            {
                if(oli.ProductCode=='Transaction Fee')
                    forTransactionFee = true;
                if(oli.Talent_Username__c!=NULL && oli.Talent_Username__c!='')
                {
                    userNames.add(oli.Talent_Username__c.toLowercase()); 
                    userNamesOnlyBILLS.add(oli.Talent_Username__c.toLowercase()); 
                }
                else if(oli.ProductCode!='Transaction Fee')
                {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:All Lineitems should have UserName populated.'));
                    return;
                }    
                if(oli.Weekly_Talent_Rate__c==NULL || oli.Weekly_Talent_Rate__c==0)
                {
                    if(oli.ProductCode!='Transaction Fee')
                    {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:'+oli.Talent_Username__c+' Should have member payment rate.'));
                        return;
                     }
                }
            }
            system.debug(userNames); 
            system.debug(userNamesOnlyBILLS); 
                                                      
        }    
        else If(OperationOn=='INTERNAL')
        {
            userNames.add(internalPlacement.Torc_user__r.Name.toLowerCase());
            userNamesOnlyBILLS.add(internalPlacement.Torc_user__r.Name.toLowerCase());
        }
        else
        {
            if((vacation.Hours_Week__c == NULL || vacation.Hours_Week__c <0) ||(vacation.Talent_Hourly_Pay_Rate__c == NULL || vacation.Talent_Hourly_Pay_Rate__c ==0) )
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please add Hours/Week and Talent Rate in Vacation.'));
                return;
            }
            if(vacation.Opportunity__c!=NULL && (vacation.Customer_Hourly_Bill_Rate__c == NULL || vacation.Customer_Hourly_Bill_Rate__c ==0))
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please Customer Rate in Vacation.'));
                return;
            }            
            userNames.add(vacation.Torc_user__r.Name.toLowerCase());
            userNamesOnlyBILLS.add(vacation.Torc_user__r.Name.toLowerCase());
            system.debug(userNames);   
            system.debug(userNamesOnlyBILLS);   
                                                     
        }
        
         boolean nonQBVandor=false;
         system.debug('--For Resetup---');
         system.debug(userNames); 
         system.debug(userNamesOnlyBILLS); 
                                                   
         If(OperationOn=='INTERNAL' || OperationOn=='OPP')
         {
             system.debug('--For Resetup OPP/INTERNAL REFERRAL---');
             vendorIdsListLocalreferralBIL = new set<string>();
             torcuserList =[Select ID, Email__c,External_Id__c, given_name__c, family_Name__c, Name, Quick_Books_vendor_Id__c, Quickbooks_Vendor__c,
                              (Select ID, Referred_By__c,
                                  Referred_by__r.Email__c,Referred_by__r.External_Id__c, Referred_by__r.given_name__c, Referred_by__r.family_Name__c, Referred_by__r.Name, Referred_by__r.Quick_Books_vendor_Id__c, Referred_by__r.Quickbooks_Vendor__c,
                                  referral_Payment_Created__c, referrer_Payment_Created__c, Payment_Week__c,
                                  Referred_To__c, Referred_To__r.Quick_Books_vendor_Id__c,Referred_To__r.Name, Referrer_Amount__c,Referral_Amount__c,
                                  Referred_To__r.Full_Name__c,Referred_By__r.Full_Name__c
                               FROM Referral_Bonus__r 
                               WHERE (referral_Payment_Created__c=FALSE OR referrer_Payment_Created__c= FALSE))
                              from Torc_user__c where Name in:userNames];
             lstreferalBonuses = new List<referral_Bonus__c>();
             system.debug(torcuserList);
             for(Torc_user__c tu:torcuserList)
             {
                 lstreferalBonuses.addAll(tu.Referral_Bonus__r);
                 system.debug(tu.Referral_Bonus__r);
                 for(Referral_Bonus__c rb: tu.Referral_Bonus__r)
                 {
                     Torc_user__c tu1=rb.Referred_by__r;
                     userNames.add(tu1.Name.toLowercase());
                     if(tu.Quick_Books_vendor_Id__c!=null)
                         vendorIdsListLocalreferralBIL.add(tu.Quick_Books_vendor_Id__c); 
                     if(tu1.Quick_Books_vendor_Id__c!=null)
                         vendorIdsListLocalreferralBIL.add(tu1.Quick_Books_vendor_Id__c); 
                 }   
             }
             system.debug(vendorIdsListLocalreferralBIL);
             system.debug(lstreferalBonuses);
          }   
         torcuserList =[Select ID, Email__c,External_Id__c, given_name__c, family_Name__c, Name, Quick_Books_vendor_Id__c, Quickbooks_Vendor__c from Torc_user__c where Name in:userNames];
         mapTotcusers = new Map<string,Torc_user__c> ();
         vendorIdsListINV=new set<string>();
         vendorIdsListBIL=new set<string>();
         vendorIdsListONLYBIL=new set<string>();
         if(forTransactionFee)
             vendorIdsListINV.add('TRANSACTIONFEE');    
         for(Torc_user__c tu:torcuserList)
         {
             mapTotcusers.put(tu.Name.toLowercase(),tu);
             if(tu.Quick_Books_vendor_Id__c==null)
             {
                 string s=tu.id;
                 s=s.right(12); 
                 vendorIdsListINV.add(s);  
                 nonQBVandor = true;
             }
             else
             {
                 vendorIdsListINV.add(tu.Quick_Books_vendor_Id__c);  
                 vendorIdsListBIL.add(tu.Quick_Books_vendor_Id__c); 
                 if(userNamesOnlyBILLS.contains(tu.Name.toLowerCase()))
                     vendorIdsListONLYBIL.add(tu.Quick_Books_vendor_Id__c);  
             }   
         }
         for(string s:userNames)
         {
             if(mapTotcusers.get(s)==NULL)
             {
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Invalid User -'+s+'. User is not part of your system.'));
                 return;       
             }
         }
        if(act.QuickBooks_Id__c==NULL)
        {
            Step = 'ACT';
            Return;
        }
        MasterCRMIDs = OperationOn=='REFERRAL'?setupMasterCRMIDForReferral(vendorIdsListINV,act):setupMasterCRMID(vendorIdsListINV,act); 
        MasterCRMIDsNew = OperationOn=='REFERRAL'?setupMasterCRMIDForReferral(vendorIdsListINV,act):setupMasterCRMID(vendorIdsListINV,act); 
        
        If(OperationOn=='INTERNAL' || OperationOn=='OPP')
            MasterCRMIDs.addAll(setupMasterCRMIDForReferral(vendorIdsListLocalreferralBIL,localreferralact));
        if(nonQBVandor && !(skipnonQBvendors))
        {
            Step = 'VEN';
            if(operationOn=='OPP' || (operationOn=='VACATION' && vacation.Opportunity__c!=NULL))
                GeneratInvoice();
            return;
        }
        Step = 'INV';  
        
        if(operationOn=='OPP' || (operationOn=='VACATION' && vacation.Opportunity__c!=NULL))
            GeneratInvoice();
        else
            GeneratBills();
        
    }    
    Date invRangeStart = null;
    Date invRangeEnd = null;
    Date billRangeStart = null;
    Date billRangeEnd = null;
    Public void GeneratInvoice()
    {
        GeneratInvoiceWithInvoicedate(null);
    }
    Public void GeneratInvoiceWithInvoicedate(Map<string,Date> firstDateMap)
    {
        invRangeStart = invRangeEnd = NULL;
        totalInvoiceAmount = 0;
        Map<string,Map<Date, QBAccountingService.QBInvoice>> MasterInvoicemap = new Map<string,Map<Date, QBAccountingService.QBInvoice>>();
        Date firstD,lastD;
        if(firstDateMap==NULL)firstDateMap=new Map<string,Date>();
        List<BillInvoiceraper> lstBillInvoicerapers;
        if(OperationOn=='OPP')
            lstBillInvoicerapers = getBillInvoiceRapers(Opp.OpportunityLineItems);
        else if(OperationOn=='VACATION')
            lstBillInvoicerapers = getBillInvoiceRapers(vacation);    
        for(BillInvoiceraper ol: lstBillInvoicerapers)
        {
            if(firstD==NULL || firstD>ol.Engagement_Start_Date)
                firstD = ol.Engagement_Start_Date;
            if(lastD==NULL || lastD>ol.Engagement_End_Date)
                lastD = ol.Engagement_End_Date;    
            string venId = forTransactionFee?'TRANSACTIONFEE':mapTotcusers.get(ol.talent_Username.tolowerCase()).Quick_Books_Vendor_Id__c;
            if(venId==NULL || venId=='')
            {
                venId = forTransactionFee?'TRANSACTIONFEE':mapTotcusers.get(ol.talent_Username.tolowerCase()).id;
            }
            string masterId = findMasterCRMId(act,venId);
            Date fd = firstDateMap.get(masterId);
            system.debug(fd);
            fd = CreateInvoiceForLineItem(ol,MasterInvoicemap,fd,masterId);
            system.debug(fd);
            firstDateMap.put(masterId,fd);
            
        }
        firstD= getFirstdayOfWeek(firstD).adddays(-13);
        lastD = getFirstdayOfWeek(lastD).adddays(22);
        invRangeStart = firstD.adddays(-21);
        invRangeEnd = lastD.adddays(7);
        generateMondayTimeLine(firstd,lastD);
        Invoices = New List<QBAccountingService.QBInvoice>();
        for(String s:MasterInvoicemap.keyset())
            for(Date d:MasterInvoicemap.get(s).keyset())
                invoices.add(MasterInvoicemap.get(s).get(d));
        if(!forTransactionFee)        
            GeneratBills();
    }
    public static date getfirstdateforMonthlySaturday(Date dt)
    {
        dt = getFirstDayOfweek(dt);
        system.debug(dt);
        return dt;
    }
    public static date getlastdateforMonthlySaturday(Date dt)
    {
        dt = getFirstDayOfweek(dt.adddays(1)).adddays(-1);
        system.debug(dt);        
        return dt;
    }
    
    Public Date CreateInvoiceForLineItem(BillInvoiceraper ol, Map<string,Map<Date, QBAccountingService.QBInvoice>> MasterInvoicemap,date initialDate,string masterId)
    {
        Integer DaysInBill = 14;
        Map<String,String> paymentTerms = getpaymentTerms(false,ContstantsSetup);
        if(MasterInvoicemap.get(masterId)==NULL)
            MasterInvoicemap.put(masterId,New Map<Date, QBAccountingService.QBInvoice>());
        Map<Date, QBAccountingService.QBInvoice> Invoicemap = MasterInvoicemap.get(masterId);
        Date firstDate =  ol.Engagement_Start_Date;
        Date lastDate =  ol.Engagement_End_Date;   
        
        if(invoicingPeriod=='Monthly')
        {
            firstDate = getFirstdayOfMonth(firstDate);
            lastDate = getFirstdayOfMonth(lastDate).addMonths(1).adddays(-1);
        }
        else if(invoicingPeriod=='Monthly-Saturday')
        {
            firstDate = getFirstdayOfMonth(firstDate);
            lastDate = getFirstdayOfWeek(lastDate).addDays(6);
        }
        else
        {
            firstDate = getFirstdayOfWeek(firstDate).adddays(1);
            lastDate = getFirstdayOfWeek(lastDate).adddays(DaysInBill+1);
        }
        boolean moveOneWeek = false;
        if(invoicingPeriod!='Monthly' && invoicingPeriod!='Monthly-Saturday')
        {
            if(initialDate!=NULL)
            {
                if(math.Mod(Math.Abs(initialDate.daysbetween(firstDate))/7,2)==1)
                    firstDate=firstDate.adddays(-7); 
            }  
            else if(operationOn !='VACATION' && opp.First_Invoice__c =='One Week')
            {
                firstDate=firstDate.adddays(-7);
            }
            else if(operationOn !='VACATION' && opp.First_Invoice__c =='Three Week')
            {
                moveOneWeek = true;
            }
        }
        system.debug(initialDate + '      '+ firstDate);
        Integer WeekCount = 0;
        while(firstDate <= lastDate)
        {
            system.debug('firstDate:'+firstDate);
            Date dateOfNextBill = firstDate.Adddays((2 - math.Mod(WeekCount,2))*7);
            
            if(invoicingPeriod=='Monthly' || invoicingPeriod=='Monthly-Saturday')
            {
                dateOfNextBill = ol.type=='TF'?firstDate: firstDate.addMonths(1).adddays(-1);
            }
            
            if(initialDate==null) initialDate = dateOfNextBill;
            system.debug(WeekCount+'----'+firstDate +' ----- '+ dateOfNextBill);
            Date localFirstDate = firstDate.adddays(-1);
            Date localFirstDate1=localFirstDate;
            Date locallastDate = firstDate.adddays(5);
            Date localLastDate1=localLastDate;
            if(invoicingPeriod=='Monthly')
            {
                localFirstDate = firstDate;
                localFirstDate1=localFirstDate;
                locallastDate = firstDate.addmonths(1).adddays(-1);
                localLastDate1=localLastDate;
            }
            else if(invoicingPeriod=='Monthly-Saturday')
            {
                localFirstDate = getfirstdateforMonthlySaturday(firstDate);
                localFirstDate1=localFirstDate;
                locallastDate = firstDate.addmonths(1).adddays(-1);
                localLastDate = getlastdateforMonthlySaturday(locallastDate);
                localLastDate1=localLastDate;
            }

            system.debug('1111>>>>>'+localFirstDate +' ----- '+ locallastDate);
            if(localFirstDate<ol.Engagement_Start_Date)
            {
                localFirstDate = ol.Engagement_Start_Date;
            }
            if(locallastDate > ol.Engagement_End_Date)
            {
                locallastDate = ol.Engagement_End_Date;
            }
            system.debug('2222>>>>>'+localFirstDate +' ----- '+ locallastDate);
            Integer workingDays = getWorkingDays(localFirstDate,locallastDate);
            
            if(workingDays>0)
            {
                if(Invoicemap.get(dateOfNextBill)==NULL)
                {
                    QBAccountingService.QBInvoice qb= new QBAccountingService.QBInvoice();
                    qb.TxnDate = DateToString(dateOfNextBill);
                    qb.CustomerRef = new QBAccountingService.QBNameValue();
                    qb.CustomerRef.Name = act.Quickbooks_Customer__c;
                    qb.CustomerRef.value = act.Quickbooks_Id__c;
                    if(opp.Email_Address_for_Invoices__c!=NULL && opp.Email_Address_for_Invoices__c!='')
                    {
                        qb.BillEmail = new QBAccountingService.QBEmailAddress();
                        qb.BillEmail.Address = opp.Email_Address_for_Invoices__c;
                    }    
                    qb.SalesTermRef = new QBAccountingService.QBNameValue();
                    qb.SalesTermRef.name = act.Payment_terms__c;
                    qb.SalesTermRef.value = paymentTerms.get(act.Payment_terms__c);
                    qb.Line=new List<QBAccountingService.QBInvoiceLine>();
                    qb.CustomerMemo = new QBAccountingService.QBOnlyValue();
                    qb.CustomerMemo.value=ContstantsSetup.QBCOn.CustomerMemo;
                    qb.CustomField = new List<QBAccountingService.QBCustomField>();
                    qb.CustomField.add(new QBAccountingService.QBCustomField());
                    qb.CustomField[0].DefinitionId = ContstantsSetup.QBCOn.CRMIDDefinitionID;
                    qb.CustomField[0].StringValue= (opp.Torc_External_Id__c==null ||opp.Torc_External_Id__c=='')?opp.id:opp.Torc_External_Id__c;
                    qb.CustomField[0].Name='CRMID';
                    qb.CustomField[0].Type='StringType';
                    qb.CustomField.add(new QBAccountingService.QBCustomField());
                    qb.CustomField[1].DefinitionId=ContstantsSetup.QBCOn.MASTERCRMIDDefinitionID;
                    qb.CustomField[1].StringValue=masterId;
                    qb.CustomField[1].Name='MASTERCRMID';
                    qb.CustomField[1].Type='StringType';
                    qb.CustomField.add(new QBAccountingService.QBCustomField());
                    qb.CustomField[2].DefinitionId=ContstantsSetup.QBCOn.PONumberDefinitionID;
                    qb.CustomField[2].StringValue=Opp.PO_Number__c;
                    if(actNameInDescription!=NULL && actNameInDescription!='')
                        qb.CustomField[2].StringValue = actNameInDescription;
                    qb.CustomField[2].Name='PO Number';
                    qb.CustomField[2].Type='StringType';
                    Invoicemap.put(dateOfNextBill,qb);
                }
                QBAccountingService.QBInvoice qb= Invoicemap.get(dateOfNextBill);
                QBAccountingService.QBInvoiceLine qbli = new QBAccountingService.QBInvoiceLine();
                qbli.SalesItemLineDetail = new QBAccountingService.QBLineItemDetail();
                
                qbli.SalesItemLineDetail.ItemRef = new QBAccountingService.QBNameValue();
                qbli.SalesItemLineDetail.ItemRef.name = usepayratetoInvoice?ContstantsSetup.QBCOn.rdInvoicecategory.Name:  ContstantsSetup.QBCOn.InvoiceItemRef.Name;
                qbli.SalesItemLineDetail.ItemRef.value = usepayratetoInvoice?ContstantsSetup.QBCOn.rdInvoicecategory.value: ContstantsSetup.QBCOn.InvoiceItemRef.value;
                
                qbli.LineNum = qb.line.size()+1;
                qbli.DetailType = 'SalesItemLineDetail';
                
                string Description = getInvoiceLineDescription(ol.Talent_Name ,localFirstDate1,localLastDate1); 
                if(ol.type=='TF')
                    Description = ol.referdescription;                   
                qbli.Description = Description;
                system.debug(Description);
                qbli.SalesItemLineDetail.Qty = 0;
                qbli.SalesItemLineDetail.UnitPrice = ol.Bill_Rate;
                qbli.SalesItemLineDetail.Qty +=   (invoicingUnit=='Hour'?(workingDays/5.0*ol.Hours_Week):workingDays/5.0);                    
                decimal amt = qbli.SalesItemLineDetail.Qty * qbli.SalesItemLineDetail.UnitPrice;
                qbli.Amount = amt;
                totalInvoiceAmount += (qbli.SalesItemLineDetail.Qty * qbli.SalesItemLineDetail.UnitPrice);
                boolean exists = false;
                for(QBAccountingService.QBInvoiceLine oldl:qb.Line)
                {
                    exists = oldL.trymergeLineItem(qbli);
                    if(exists)
                        break;
                }
                if(!exists)
                    qb.Line.add(qbli);                           
            }
            if(invoicingPeriod=='Monthly' || invoicingPeriod=='Monthly-Saturday')
                firstDate = firstDate.addMonths(1);
            else    
                firstDate = firstDate.adddays(7);
            WeekCount+=1;
        }
        return initialDate;
    }
    public static string getInvoiceLineDescription(string talentName, Date localFirstDate1, Date localLastDate1)
    {
        return talentName +'  ' +DateToStringMDY(localFirstDate1) +' - ' +  DateToStringMDY(localLastDate1);                    
    }
    public void UpsertInvoiceinQB()
    {
        Boolean manualDocNumber = Torc_Constants__c.getInstance().Manual_Doc_Number__c;
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(QBAccountingService.QBInvoice invoice : ExistingInvoices)
        {
            if(invoice.selectedRow==TRUE)
            {
                if(invoice.BillEmail==NULL)
                    invoice.BillEmail = new QBAccountingService.QBEmailAddress();
                if(invoice.BillEmail.Address != opp.Email_Address_for_Invoices__c)    
                {
                    invoice.isEdited=true;
                    invoice.BillEmail.Address = opp.Email_Address_for_Invoices__c;
                }
            }
            if(invoice.id==NULL && manualDocNumber ==TRUE)
            {
                Latestinvoicenumber++;
                invoice.DocNumber = string.valueOf(Latestinvoicenumber);
            }
            if((invoice.id==NULL || invoice.isEdited==TRUE) && invoice.selectedRow==TRUE)
            {
                 invoice.deletZeroLines();
                 invoice.ShipAddr=new QBAccountingService.QBAddress();
                 QB_API_Call__c qb = new  QB_API_Call__c(Name='invoice',Input__c = removeAttributes(JSON.serialize(invoice)));
                 if(invoice.line.size()==0)
                     qb.Delete__c = true;
                 lst.add(qb);
            }     
        }
        if(lst.size()>0)
        {
            if(OperationOn=='OPP')
            {
                opp.Invoices_Created__c=true;
                update opp;
            }    
            if(OperationOn=='VACATION')
            {
                vacation.QB_Invoice_Updated__c=true;
                update vacation;
            } 
            QBOpportunitySetup.CallQBAPI(lst);
        }  
        mismatchedInvoicingEmail = '';  
    }
    public List<QBAccountingService.QBInvoice> getInvoiceListForUpdate()
    {
        List<QBAccountingService.QBInvoice>  l=new List<QBAccountingService.QBInvoice> ();
        for(QBAccountingService.QBInvoice invoice : ExistingInvoices)
        {
            if(invoice.id==NULL || invoice.isEdited==TRUE)
                 l.add(invoice);
        }
        return l;
    }
    Public List<QBAccountingService.QBInvoice> existingInvoices{get;set;}
    public string mismatchedInvoicingEmail{get;set;}
    public Long latestInvoiceNumber{get;set;}
    public Long getLatestinvoiceNumber()
    {
        Long linvN=0;
        string query= 'select DocNumber from Invoice where DocNumber != \' \' Order By DocNumber DESC MaxResults 1 ';
        system.debug(query);
        JSONParser jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseInvoice res=(QBAccountingService.QBResponseInvoice)jp.readValueAs(QBAccountingService.QBResponseInvoice.class);
        system.debug(res);
        if(res.QueryResponse!=NULL && res.QueryResponse.Invoice!=NULL)
        {
            for(QBAccountingService.QBInvoice inv:res.QueryResponse.Invoice)
            {
                 linvN =  Long.valueof(inv.DocNumber);
            }
        }

        query= 'select DocNumber from CreditMemo where DocNumber != \' \' Order By DocNumber DESC MaxResults 1 ';
        system.debug(query);
        jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseCreditMemo resCM=(QBAccountingService.QBResponseCreditMemo)jp.readValueAs(QBAccountingService.QBResponseCreditMemo.class);
        system.debug(resCM);
        if(resCM.QueryResponse!=NULL && resCM.QueryResponse.CreditMemo!=NULL)
        {
            for(QBAccountingService.QBCreditMemo inv:resCM.QueryResponse.CreditMemo)
            {
                 Long l2 =  Long.valueof(inv.DocNumber);
                 if(l2>linvN)
                     linvN = l2;
            }
        }  
        
        return linvN;   
    }
    Public void SearchExistingInvoices()
    {
        mismatchedInvoicingEmail = '';
        set<string> mismatchedInvoicingEmailSet=new set<string>();
        if(opp.Email_Address_For_Invoices__c==NULL)opp.Email_Address_For_Invoices__c='';
        ExistingInvoiceSum =0;
        string accountNo = act.QuickBooks_id__c;
        
        latestInvoiceNumber=getLatestinvoiceNumber();        
        
        //try
        {            
            Date sd = invRangestart;
            Date ed = InvRangeEnd;
            string query= 'SELECT * FROM Invoice Where CustomerRef = \'' + accountNo+'\' ';
            if(loadAllinvoices==false)
                query = query +' AND TxnDate >= \''+ DateToString(sd) +'\'';
                //query = query +' AND TxnDate >= \''+ DateToString(sd) +'\' AND TxnDate <= \'' + DateToString(ed) +'\'';
             query = query +' Order By TxnDate MAXResults 1000';    
            system.debug(query);
            JSONParser jp = QBAccountingService.runQuery(query);
            existingInvoices = new List<QBAccountingService.QBInvoice>();
            Map<string,Date> MasterCRMTODate = new Map<string,Date>();
            Map<string,QBAccountingService.QBInvoice> existingInvoicemap = new Map<string,QBAccountingService.QBInvoice>();
            QBAccountingService.QBResponseInvoice res=(QBAccountingService.QBResponseInvoice)jp.readValueAs(QBAccountingService.QBResponseInvoice.class);
            system.debug(res);
            system.debug(MasterCRMIDs);
            system.debug(MasterCRMIDsNew);
            
            if(res.QueryResponse!=NULL && res.QueryResponse.Invoice!=NULL)
            {
                for(QBAccountingService.QBInvoice inv:res.QueryResponse.Invoice)
                {
                    system.debug(inv);
                    string existingemail='';
                    if(inv.BillEmail!=NULL && inv.BillEmail.Address!=NULL)
                        existingemail = inv.BillEmail.Address;
                    if(opp.Email_Address_For_Invoices__c.toLowercase()!= existingemail)
                    {
                        if(existingemail=='')existingemail='<BLANK>';
                        mismatchedInvoicingEmailSet.add(existingemail.toLowerCase());
                    }   
                    
                    if(inv.CustomField!=NULL)
                    {
                        boolean addInMCR=false;
                        boolean addInPON = false;
                        string cfStr='';
                        if(actNameInDescription ==NULL || actNameInDescription=='')
                            addInPON = true;
                        for(QBAccountingService.QBCustomField cf:inv.CustomField)
                        {
                            system.debug(cf);
                            if(cf.Name=='MASTERCRMID' && MasterCRMIDs.contains(cf.StringValue))
                            {
                                cfStr = cf.StringValue;
                                addInMCR = true;
                            }
                            if(cf.Name=='PO Number' && addInPON==false && cf.StringValue ==actNameInDescription)
                            {
                                addInPON = true;
                            }
                        }
                        if(addInMCR && addInPON)
                        {
                            existingInvoices.add(inv);
                            MasterCRMTODate.put(cfStr,StringToDate(inv.TxnDate));
                            existingInvoicemap.put(cfStr+'-'+inv.TxnDate,inv);
                        }
                        
                    } 
                }
            }    
            for(string s:mismatchedInvoicingEmailSet)
                mismatchedInvoicingEmail+=((mismatchedInvoicingEmail==''?'':', ')+s);
            system.debug(existingInvoices);
            if((OperationOn=='VACATION' && vacation.QB_Invoice_Updated__c==FALSE) || (operationOn=='OPP' && Opp.Invoices_Created__c==FALSE))
            {
                GeneratInvoiceWithInvoicedate(MasterCRMTODate);
                for(QBAccountingService.QBInvoice inv:invoices)
                {
                    string k='';
                    for(QBAccountingService.QBCustomField cf:inv.CustomField)
                    {
                        if(cf.Name=='MASTERCRMID' && MasterCRMIDs.contains(cf.StringValue))
                        {
                            k=cf.StringValue+'-'+inv.TxnDate;
                            break;
                        }
                    }
                    QBAccountingService.QBInvoice exInv = existingInvoicemap.get(k);
                    if(exInv==NULL || k=='' ||(forTransactionFee==true && exinv.EmailStatus=='EmailSent'))
                    {
                        existingInvoices.add(inv);
                        if(StringToDate(inv.TxnDate) >=Date.Today())
                            inv.selectedRow=True;
                        else 
                            inv.selectedRow=false;   
                    }        
                    else
                    {
                        system.debug('......Merging Start........');
                        system.debug(exInv);
                        system.debug(inv);
                        exinv.mergeLines(inv.Line);
                        system.debug('......Merging Merged........');
                        system.debug(exInv);
                        system.debug('......Merging Ends........');
                        if(StringToDate(exInv.TxnDate) >=Date.Today())
                            exInv.selectedRow=True;
                        
                    }    
                } 
                sortList(existingInvoices);   
            }    
            for(QBAccountingService.QBInvoice exInv:existingInvoices)
            {
                ExistingInvoiceSum+=exInv.gettotalAmount(); 
            } 
        }
    }















//---------BILL OPERATION-----------------------------------------------------------------------------------------------------------------

    
    public static string getBillLineDescription(Account act, Date localFirstDate1, Date localLastDate1)
    {
        return act.QuickBooks_Customer__c +' ' +DateToStringMDY(localFirstDate1) +' - ' +  DateToStringMDY(localLastDate1);                    
    }
    public static string getreferalDescription(Referral_Bonus__c ol,boolean isrefferer)
    {
        return 'Torc Referral';
        //return isrefferer?
        //    'Referral Bonus For :'+ol.Referred_To__r.Name:
        //    'Referred By Bonus :'+ol.Referred_By__r.Name;
    }
    public class BillInvoiceRaper
    {
        public string type{get;set;}
        public date Engagement_Start_Date;
        public string referdescription;
        public date Engagement_End_Date;
        public String talent_Username;
        public string Talent_Name;
        public Decimal Weekly_Talent_Rate;
        public Decimal Bill_Rate;
        public decimal Hours_Week;
        private void setuptalentrateByTransferP(decimal talentTransferPricePercent)
        {
            if(Bill_Rate!=NULL && Bill_Rate!=0 
                    && talentTransferPricePercent!=NULL && talentTransferPricePercent!=0 && talentTransferPricePercent!=1)
            {
                Bill_Rate = (Bill_Rate/(1-(talentTransferPricePercent/100))).setScale(2);
            }
        }
        public BillInvoiceRaper(Referral_Bonus__c ol,boolean isrefferer, decimal talentTransferPricePercent)
        {
            type='R';
            Engagement_Start_Date=ol.Payment_Week__c;
            Engagement_End_Date=ol.Payment_Week__c;
            referdescription = QBOpportunitySetup.getreferalDescription(ol,isrefferer);
            if(isrefferer)
            {
                talent_Username=ol.Referred_By__r.Name;
                Talent_Name = ol.Referred_By__r.Full_Name__c;
                Weekly_Talent_Rate = ol.Referrer_Amount__c;
            }
            else
            {
                talent_Username=ol.Referred_To__r.Name;
                Talent_Name = ol.Referred_To__r.Full_Name__c;
                Weekly_Talent_Rate = ol.Referral_Amount__c;
            }
            setuptalentrateByTransferP(talentTransferPricePercent);
        }
        public BillInvoiceRaper(OpportunityLineItem ol,string invUnit, boolean usePayRateToInvoice1, decimal talentTransferPricePercent)
        {
            type='O';
            Engagement_Start_Date=ol.Engagement_Start_Date__c;
            Engagement_End_Date=ol.Engagement_End_Date__c;
            talent_Username=ol.talent_Username__c;
            Talent_Name = ol.Talent_Name__c;
            Weekly_Talent_Rate = ol.Weekly_Talent_Rate__c;
            Hours_Week = ol.Hours_Week__c;
            if(usePayRateToInvoice1)
                Bill_Rate = (invUnit=='Hour'?ol.Talent_Hourly_Pay_Rate__c : ol.Weekly_Talent_Rate__c);
            else
                Bill_Rate = (invUnit=='Hour'?ol.Customer_Hourly_Bill_Rate__c : ol.Weekly_Bill_Rate__c);
            setuptalentrateByTransferP(talentTransferPricePercent);
        }
        public BillInvoiceRaper(OpportunityLineItem ol,string invUnit,string transactionFeeOperationType, decimal talentTransferPricePercent)
        {
            type='TF';
            Engagement_Start_Date=ol.Engagement_Start_Date__c;
            Engagement_End_Date=ol.Engagement_End_Date__c;
            talent_Username=ol.talent_Username__c;
            Talent_Name = ol.Talent_Name__c;
            Weekly_Talent_Rate = 0;
            Hours_Week = 1;
            if(invUnit=='Hour')
                Bill_Rate = ol.Customer_Hourly_Bill_Rate__c;
            else
                Bill_Rate = ol.Weekly_Bill_Rate__c;
            DateTime dt = Datetime.newInstance(Engagement_Start_Date.year(),Engagement_Start_Date.month(),1);
            string f = dt.format('MMMM yyyy');
            
            if(transactionFeeOperationType=='OVERALL')
            {
                Bill_Rate = (Bill_Rate/0.07).Round();
                referdescription = f +' Payment';
            }
            if(transactionFeeOperationType=='TRANSACTIONFEEONLY')
            {
                referdescription =  f+ ' Transaction Fee';
            }
            if(transactionFeeOperationType=='BANKFEEONLY')
            {
                Bill_Rate = ol.bank_fee__c;
                referdescription =  f+ ' Bank Fee';
            }
            setuptalentrateByTransferP(talentTransferPricePercent);
        }
        public BillInvoiceRaper(Internal_Placement__c ol, decimal talentTransferPricePercent)
        {
            type='I';
            Engagement_Start_Date=ol.Engagement_Start_Date__c;
            Engagement_End_Date=ol.Engagement_End_Date__c;
            talent_Username=ol.Torc_user__r.Name;
            Talent_Name = ol.user_Name__c;
            Weekly_Talent_Rate = ol.Weekly_Talent_Rate__c;
            Bill_Rate=0;
            setuptalentrateByTransferP(talentTransferPricePercent);
        }
        public BillInvoiceRaper(Engagement_Vacation__c ol,boolean isStart,string invUnit, boolean usePayRateToInvoice1, decimal talentTransferPricePercent)
        {
            type='V';
            talent_Username=ol.Torc_user__r.Name;
            talent_name = ol.User_Name__c;
            Hours_Week = ol.Hours_Week__c;
            if(isStart)
            {
                Engagement_Start_Date=ol.Engagement_Start_Date__c;
                Engagement_End_Date=ol.Engagement_End_Date__c;
                Weekly_Talent_Rate = ol.Weekly_Talent_Rate__c*-1;
                if(usePayRateToInvoice1)
                    Bill_Rate = (invUnit=='Hour'?ol.Talent_Hourly_Pay_Rate__c : ol.Weekly_Talent_Rate__c) *-1;
                else
                    Bill_Rate = (invUnit=='Hour'?ol.Customer_Hourly_Bill_Rate__c : ol.Weekly_Bill_Rate__c)*-1;
            }
            else
            {
                Engagement_Start_Date=ol.Shift_To_Date__c;
                Engagement_End_Date=ol.Shift_To_End_Date__c;
                Weekly_Talent_Rate = ol.Weekly_Talent_Rate__c;
                if(usePayRateToInvoice1)
                    Bill_Rate = (invUnit=='Hour'?ol.Talent_Hourly_Pay_Rate__c : ol.Weekly_Talent_Rate__c);
                else
                    Bill_Rate = (invUnit=='Hour'?ol.Customer_Hourly_Bill_Rate__c : ol.Weekly_Bill_Rate__c);
            } 
            setuptalentrateByTransferP(talentTransferPricePercent);   
        }
    }
    Public List<BillInvoiceRaper> getBillInvoiceRapers(List<Referral_Bonus__c> lol)
    {
        List<BillInvoiceRaper> l=new List<BillInvoiceRaper>();
        for(Referral_Bonus__c ol:lol)
        {
            if(ol.referrer_Payment_Created__c== FALSE)
                l.add(new BillInvoiceRaper(ol,true, talentTransferPricePercent));
            if(ol.referral_Payment_Created__c==FALSE)
                l.add(new BillInvoiceRaper(ol,false, talentTransferPricePercent));
        }
        return l;    
    }
    Public List<BillInvoiceRaper> getBillInvoiceRapers(List<OpportunityLineItem> lol)
    {
        List<BillInvoiceRaper> l=new List<BillInvoiceRaper>();
        for(OpportunityLineItem ol:lol)
        {
            if(ol.ProductCode=='Transaction Fee')
            {
                 l.add(new BillInvoiceRaper(ol,InvoicingUnit,'OVERALL', talentTransferPricePercent));
                 l.add(new BillInvoiceRaper(ol,InvoicingUnit,'TRANSACTIONFEEONLY', talentTransferPricePercent));
                 l.add(new BillInvoiceRaper(ol,InvoicingUnit,'BANKFEEONLY', talentTransferPricePercent));
            }
            else
                l.add(new BillInvoiceRaper(ol,InvoicingUnit,usePayRateToInvoice, talentTransferPricePercent));
        }
        return l;    
    }
    
    Public List<BillInvoiceRaper> getBillInvoiceRapers(Internal_Placement__c ip)
    {
        List<BillInvoiceRaper> l=new List<BillInvoiceRaper>();
        l.add(new BillInvoiceRaper(ip, talentTransferPricePercent));
        return l;    
    }
    Public List<BillInvoiceRaper> getBillInvoiceRapers(Engagement_Vacation__c ip)
    {
        List<BillInvoiceRaper> l=new List<BillInvoiceRaper>();
        l.add(new BillInvoiceRaper(ip,true,InvoicingUnit,usePayRateToInvoice, talentTransferPricePercent));
        l.add(new BillInvoiceRaper(ip,false,InvoicingUnit,usePayRateToInvoice, talentTransferPricePercent));
        return l;    
    }
    
    
    Public void GeneratBills()
    {
        Bills = NEW List<QBAccountingService.QBBill>();
        localReferralBills = NEW List<QBAccountingService.QBBill>();
        GeneratBillsWithBilldate(Bills,false,act);
        if(OperationON=='OPP' || OperationON=='INTERNAL')
            GeneratBillsWithBilldate(localReferralBills,true,localreferralact);
    }
    Public void GeneratBillsWithBilldate(List<QBAccountingService.QBBill> xBills,boolean islocalreferral,Account xact)
    {
        system.debug('In GenerateBill'+islocalreferral);
        system.debug(xBills);
        system.debug(mapTotcusers);
        if(Step == 'VEN') return;
        Integer DaysInBill = 7; 
        Map<String,String> InternalBillCategory = getInternalBillCategory();
        totalMemberPayment = 0;
        Map<string,Map<Date, QBAccountingService.QBBill>> PlacementBillmap = New Map<string,Map<Date, QBAccountingService.QBBill>>();
        List<BillInvoiceRaper> lspBillInvoiceRapers;
        if(OperationOn=='OPP')
        {
            if(islocalreferral)
                lspBillInvoiceRapers = getBillInvoiceRapers(lstreferalBonuses);
            else    
                lspBillInvoiceRapers = getBillInvoiceRapers(Opp.OpportunityLineItems);
        }
        else if(OperationOn=='INTERNAL')
        {
            if(islocalreferral)
                lspBillInvoiceRapers = getBillInvoiceRapers(lstreferalBonuses);
            else    
                lspBillInvoiceRapers = getBillInvoiceRapers(InternalPlacement);    
        }
        else if(OperationOn=='VACATION')
            lspBillInvoiceRapers = getBillInvoiceRapers(vacation);  
        else if(OperationOn=='REFERRAL')
        {
            lspBillInvoiceRapers = getBillInvoiceRapers(lstreferalBonuses);            
        }
        system.debug(lspBillInvoiceRapers);
        for(BillInvoiceRaper ol: lspBillInvoiceRapers)
        {
            system.debug(ol);
            Date firstDate=ol.Engagement_Start_Date;
            Date lastDate=ol.Engagement_End_Date;
            string memberId = mapTotcusers.get(ol.talent_Username.tolowerCase()).Quick_Books_Vendor_Id__c;
            if(memberId==NULL || memberId.trim()=='') continue;
            string masterId = findMasterCRMId(xact,memberId);
            if(operationon=='REFERRAL' || isLocalreferral)masterId='REFERRAL:'+memberId;
            if(PlacementBillmap.get(memberId)==NULL)
               PlacementBillmap.put(memberId,New Map<Date, QBAccountingService.QBBill>()); 
            Map<Date, QBAccountingService.QBBill> Billmap = PlacementBillmap.get(memberId);
            
            firstDate = getFirstdayOfWeek(firstDate).adddays(1);
            lastDate = getFirstdayOfWeek(lastDate).adddays(8);
            
            if(OperationOn=='INTERNAL' || OperationOn=='REFERRAL')
            {
                generateMondayTimeLine(firstDate,lastDate);
            }
            
            billRangeStart = firstDate.Adddays(-7);
            billRangeEnd = lastDate.Adddays(7);
            Boolean oneWeekEarly=false;
            string venId = mapTotcusers.get(ol.talent_Username.tolowerCase()).Quick_Books_Vendor_Id__c;
            system.debug(venId+'-'+firstDate+'-'+lastDate);
            while(firstDate <= lastDate)
            {
                Date dateOfBill = (operationon=='REFERRAL' || isLocalreferral)?ol.Engagement_Start_Date:   getBillDate(firstDate.adddays(5));
                Date dueDateOfBill = getBillDueDate(firstDate.adddays(5),lstPaymentDates);
                system.debug(firstDate+'---'+dateOfBill+'----'+dueDateOfBill);
                Date localFirstDate = firstDate.adddays(-1);
                Date localFirstDate1=localFirstDate;
                Date locallastDate = firstDate.adddays(5);
                Date localLastDate1=localLastDate;
                
                if(localFirstDate<ol.Engagement_Start_Date)
                {
                    localFirstDate = ol.Engagement_Start_Date;
                }
                if(locallastDate > ol.Engagement_End_Date)
                {
                    locallastDate = ol.Engagement_End_Date;
                }
                Integer workingDays = getWorkingDays(localFirstDate,locallastDate);
                system.debug(workingDays);
                if(workingDays>0 || isLocalreferral || operationon=='REFERRAL')
                {                
                    if(billMap.get(dateOfBill)==NULL)
                    {
                        QBAccountingService.QBBill qb= new QBAccountingService.QBBill();
                        qb.docNumber='[BILL_NUMBER_SFDC]';
                        qb.TxnDate = DateToString(dateOfBill);
                        qb.DueDate = DateToString(DuedateOfBill);
                        qb.VendorRef = new QBAccountingService.QBNameValue();
                        qb.VendorRef.Name = mapTotcusers.get(ol.Talent_Username.tolowerCase()).QuickBooks_Vendor__c;
                        qb.VendorRef.value = mapTotcusers.get(ol.talent_Username.tolowerCase()).Quick_Books_Vendor_Id__c;
                        qb.SalesTermRef = new QBAccountingService.QBNameValue();
                        //qb.SalesTermRef.Name='Net 15'; 
                        //qb.SalesTermRef.value = paymentTerms.get(qb.SalesTermRef.Name);                        
                        qb.Line = NEW List<QBAccountingService.QBBillLine>();
                        qb.PrivateNote = masterId;
                        xBills.add(qb);
                        Billmap.put(dateOfBill,qb);
                    }    
                    QBAccountingService.QBBill qb= Billmap.get(dateOfBill);
                    
                    QBAccountingService.QBBillLine qbli = new QBAccountingService.QBBillLine();
                    qbli.DetailType = 'AccountBasedExpenseLineDetail';
                    qbli.AccountBasedExpenseLineDetail = new QBAccountingService.QBAccountBasedExpenseLineDetail();

                    qbli.AccountBasedExpenseLineDetail.AccountRef = new QBAccountingService.QBNameValue();
                    if(operationon=='REFERRAL' || isLocalreferral)
                    {
                        string brc = Torc_Constants__c.getInstance().referral_Bonus_Category__c;
                        qbli.AccountBasedExpenseLineDetail.AccountRef.name= brc;
                        qbli.AccountBasedExpenseLineDetail.AccountRef.value=InternalBillCategory.get(brc);
                    }  
                    else if(operationon=='OPP' || (operationon=='VACATION' && vacation.Opportunity__c!=NULL))
                    {
                        qbli.AccountBasedExpenseLineDetail.AccountRef.name= usepayratetoInvoice?    ContstantsSetup.QBCOn.rdBillCategory.Name:     ContstantsSetup.QBCOn.BillItemRef.Name;
                        qbli.AccountBasedExpenseLineDetail.AccountRef.value=usepayratetoInvoice?    ContstantsSetup.QBCOn.rdBillCategory.Value:    ContstantsSetup.QBCOn.BillItemRef.Value;
                    }
                    else if(operationon=='INTERNAL'  || (operationon=='VACATION' && vacation.Internal_Placement__C!=NULL))
                    {
                        qbli.AccountBasedExpenseLineDetail.AccountRef.name=internalPlacement.Category__c;
                        qbli.AccountBasedExpenseLineDetail.AccountRef.value=InternalBillCategory.get(internalPlacement.Category__c);
                    }
                   
                    qbli.AccountBasedExpenseLineDetail.CustomerRef = new QBAccountingService.QBNameValue();
                    qbli.AccountBasedExpenseLineDetail.CustomerRef.name=xact.Quickbooks_Customer__c;
                    qbli.AccountBasedExpenseLineDetail.CustomerRef.value=xact.Quickbooks_Id__c;
                    
                   //talentTransferPricePercent
                    
                    qbli.Amount = (operationon=='REFERRAL'|| isLocalreferral)? ol.Weekly_Talent_Rate : ol.Weekly_Talent_Rate * (workingDays/5.0);
                    totalMemberPayment += qbli.amount;
                    string Description = getBillLineDescription(xact,localFirstDate1,localLastDate1);   
                    if(operationon=='INTERNAL' || (operationon=='VACATION' && vacation.Internal_Placement__c!=NULL))
                    {
                        Description= xact.QuickBooks_Customer__c+' '+
                              ((InternalPlacement.Bill_Prefix__c!=NULL && InternalPlacement.Bill_Prefix__c!='')?InternalPlacement.Bill_Prefix__c+' ':'')+
                              DateToStringMDY(localFirstDate1) +' - ' +  DateToStringMDY(localLastDate1);                                                      
                    }
                    if(operationon=='REFERRAL' || isLocalreferral)
                    {
                        Description = ol.referdescription;
                    }
                    
                    qbli.Description = Description;
                    if(qb.Line.size()==0)
                        qb.Line.add(qbli); 
                    else
                    {
                        boolean exists = false;
                        for(QBAccountingService.QBBillLine oldl:qb.Line)
                        {
                            exists = oldL.trymergeLineItem(qbli);
                            if(exists)
                                break;
                        }
                        if(!exists)
                            qb.Line.add(qbli);                           
                    } 
                    system.debug(qb);
                    if(isLocalreferral || operationon=='REFERRAL') break;
                }
                firstDate = firstDate.adddays(7);
                
            }
        }
    }
    public List<QBAccountingService.QBBill> getBillListForUpdate()
    {
        List<QBAccountingService.QBBill>  l=new List<QBAccountingService.QBBill> ();
        for(QBAccountingService.QBBill invoice : ExistingBills)
        {
            if(invoice.id==NULL || invoice.isEdited==TRUE)
                 l.add(invoice);
        }
        return l;
    }
    
    Public List<QBAccountingService.QBBill> existingBills{get;set;}
    public List<QBAccountingService.QBBill> existinglocalReferralBills{get;set;}
    Public void SearchExistingBills()
    {
        ExistingBillSum =0;
        existingBills = new List<QBAccountingService.QBBill>();
        system.debug(vendorIdsListBIL);
        //ExistingBillSum = SearchExistingBillsLocal(vendorIdsListBIL,act.QuickBooks_id__c, ExistingBills,bills,false);
        ExistingBillSum = SearchExistingBillsLocal(vendorIdsListONLYBIL,act.QuickBooks_id__c, ExistingBills,bills,false);
    }
    Public void SearchExistingLocalreferralBills()
    {
        ExistingLocalreferralBillSum = 0;
        existinglocalReferralBills = new List<QBAccountingService.QBBill>();
        system.debug(vendorIdsListLocalreferralBIL);
        ExistingLocalreferralBillSum = SearchExistingBillsLocal(vendorIdsListLocalreferralBIL,localReferralact.QuickBooks_id__c, existinglocalReferralBills,Localreferralbills,true);
    }
    Public Decimal SearchExistingBillsLocal(set<string>xvendorIdsListBIL,string accountNo, List<QBAccountingService.QBBill> xExistingBills,List<QBAccountingService.QBBill> xBills, boolean isLocalreferral)
    {
        Decimal xExistingBillSum=0;
        if(xVendorIdsListBIL.size()==0)
            return xExistingBillSum;
         
        try
        {            
            Date sd = invRangestart;
            Date ed = InvRangeEnd;
            string vids='';
            for(string s:xVendorIdsListBIL)
                vids = vids+ (vids=='' ? '' : ',') + '\'' + s+ '\'';
            string query= 'SELECT * FROM Bill Where VendorRef IN ('+vids+')'; 
            
            if(loadAllbills==false && !(isLocalreferral))
                query = query +' AND TxnDate >= \''+ DateToString(sd) +'\'';
                
                //query = query +' AND TxnDate >= \''+ DateToString(sd) +'\' AND TxnDate <= \'' + DateToString(ed) +'\'';
            query +=' Order By DocNumber,TxnDate MAXRESULTS 1000';
                        
            system.debug(query);
            JSONParser jp = QBAccountingService.runQuery(query);
            Map<String,QBAccountingService.QBBill> existingBillMap = new Map<String,QBAccountingService.QBBill>();
            
            
            QBAccountingService.QBResponseBill res=(QBAccountingService.QBResponseBill)jp.readValueAs(QBAccountingService.QBResponseBill.class);
            system.debug(res);
            system.debug(MasterCRMIDs);
            system.debug(isLocalreferral);
            system.debug(operationon);
            
            if(res.QueryResponse!=NULL && res.QueryResponse.Bill!=NULL)
            {
                for(QBAccountingService.QBBill inv:res.QueryResponse.Bill)
                {
                    system.debug(isLocalreferral+'==='+operationon+'=='+inv.privateNote);    
                    if((isLocalreferral || operationon=='REFERRAL') && inv.privateNote!=NULL && inv.privateNote.left(9)!='REFERRAL:')
                        continue;
                    if((isLocalreferral==FALSE && operationon!='REFERRAL') && inv.privateNote!=NULL && inv.privateNote.left(9)=='REFERRAL:')
                        continue;
                    if(MasterCRMIDs.contains(inv.privateNote))
                    {
                        xExistingBills.add(inv);
                        string k = inv.TxnDate+'-'+ inv.VendorRef.value;
                        existingBillMap.put(k,inv);
                    } 
                }
            }    
            system.debug(xexistingBills);
            if(OperationOn=='INTERNAL' || (operationOn=='VACATION' && vacation.QB_Bills_Updated__c ==FALSE) || operationOn=='REFERRAL' || (OperationOn=='OPP' && Opp.Bills_Created__c==FALSE) || isLocalreferral)
            {
                for(QBAccountingService.QBbill inv:xBills)
                {
                    string k = inv.TxnDate+'-'+ inv.VendorRef.value;
                    QBAccountingService.QBBill exInv = existingBillMap.get(k);
                    if(exInv==NULL)
                    {
                        xexistingBills.add(inv);
                        inv.selectedRow=True;
                        inv.selectedRow = StringToDate(inv.TxnDate) >=Date.Today();
                    }    
                    else
                    {
                        exinv.mergeLines(inv.Line);
                        if(StringToDate(exInv.TxnDate) >=Date.Today())
                            exInv.selectedRow=True;
                    }    
                }
                sortBillList(xexistingBills);
                for(QBAccountingService.QBBill exInv:xexistingBills)
                    xExistingBillSum+=exInv.gettotalAmount();    
            }    
        }
        catch(exception e)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
        }
        return xExistingBillSum;
    }
    public void UpsertBillsinQB()
    {
        UpsertBillsinQBLocal(ExistingBills,false);
        
    }
    public void UpsertLocalreferralBillsinQB()
    {
        UpsertBillsinQBLocal(existinglocalReferralBills,true);
    }
    public void UpsertBillsinQBLocal(List<QBAccountingService.QBBill>xExistingBills,boolean islocalrefferel)
    {
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        //string groupName = UserInfo.getUserId() + dateTime.now();
        set<string> REFERRALupdates=new set<string>();
        for(QBAccountingService.QBBill invoice : xExistingBills)
        {
            if((invoice.id==NULL || invoice.isEdited==TRUE) && invoice.selectedRow==TRUE)
            {
                 invoice.deletZeroLines();
                 QB_API_Call__c qb = new  QB_API_Call__c( Name='bill',Input__c = removeAttributes(JSON.serialize(invoice)));
                 if(invoice.line.size()==0)
                     qb.Delete__c = true;
                 lst.add(qb);
                 if(operationOn=='REFERRAL' ||islocalrefferel)
                 {
                     for(QBAccountingService.QBBillLine qbli: invoice.Line)
                     {
                         REFERRALupdates.add(invoice.vendorRef.value+'-'+qbli.Description);
                     }
                 }
            }     
        }
        system.debug(REFERRALupdates);
        if(lst.size()>0)
        {
            if(OperationOn=='OPP' && !islocalrefferel)
            {
                opp.Bills_Created__c=true;
                update opp;
            }
            if(OperationOn=='VACATION' && !islocalrefferel)
            {
                vacation.QB_Bills_Updated__c=true;
                update vacation;
            } 
            List<referral_Bonus__c> upsertlst=new List<referral_Bonus__c>();
            if(REFERRALupdates.size()>0)
            {
                for(referral_Bonus__c rb: lstreferalBonuses)
                {
                    boolean addit=false;
                    string referdescription = rb.Referred_by__r.Quick_Books_vendor_Id__c+'-'+QBOpportunitySetup.getreferalDescription(rb,true);
                    if(REFERRALupdates.contains(referdescription))
                    {
                        rb.referrer_Payment_Created__c = true;addit=true;
                    }
                    referdescription = rb.Referred_to__r.Quick_Books_vendor_Id__c+'-'+QBOpportunitySetup.getreferalDescription(rb,false);
                    if(REFERRALupdates.contains(referdescription))
                    {
                        rb.referral_Payment_Created__c = true;addit=true;
                    }
                    if(addit)
                        upsertlst.add(rb);  
                }
                if(upsertlst.size()>0)
                    update upsertlst;
            }   
            QBOpportunitySetup.CallQBAPI(lst);
        }    
    }
    
    
    
    
    
    
    ////---------------------------------------**************************************************
    public boolean getShowUpdateInvoice()
    {
        If((OperationOn=='OPP' && Opp.Invoices_Created__c)|| (OperationOn=='VACATION' && vacation.QB_Invoice_Updated__c))
            return false;
            
        for(QBAccountingService.QBInvoice invoice : ExistingInvoices)
            if(invoice.id==NULL || invoice.isEdited == TRUE)
                 return true;
        return false;
    }
    public boolean getShowUpdateBills()
    {
        If((OperationOn=='OPP' && Opp.Bills_Created__c)|| (OperationOn=='VACATION' && vacation.QB_bills_Updated__c))
            return false;    
        for(QBAccountingService.QBBill invoice : ExistingBills)
            if(invoice.id==NULL || invoice.isEdited == TRUE)
                 return true;
        return false;
    }
    Public static Date getBilldate(Date weekendDate)
    {
        Date weekStartDate = weekendDate.adddays(-6);
        if(weekStartDate.Month()==weekendDate.Month())
            return weekEnddate;
        Date fdayOfMonth=Date.newInstance(weekendDate.year(),weekendDate.Month(),1);   
        if(weekEndDate.Day()>=4)
           return weekEndDate;     
        else
            return fdayOfMonth.adddays(-1);
    }
    Public static Date getBillDuedate(Date weekendDate, List<Payment_Date__c> lstPaymentDates)
    {
        Date SequenceDate=null;
        for(Payment_Date__c pd:lstPaymentDates)
        {
            if(weekendDate>pd.Date__c)
                sequenceDate = pd.Date__c;
            else
                break;    
        }
        integer daysBet = sequenceDate.daysBetween(weekendDate);
        integer weeksbet = daysBet/14;
        return sequenceDate.adddays(weeksBet*14+14);
    }
    public static Date getInvoicingDateForWeek(Date dt)
    {
        system.debug(dt);
        dt=getFirstDayOfWeek(dt).adddays(6);
        system.debug(dt);
        Date newDt = date.newInstance(dt.year(),dt.Month()+1,1);
        //newDt=getFirstDayOfWeek(newDt);
        //if(newDt.month()==dt.Month())
        //    newDt=newDt.adddays(7);
        system.debug(newdt);
        return newdt;
    }
    public void uncheckPastInvoices()
    {
        for(QBAccountingService.QBInvoice exInv:existingInvoices)
        {
            if(StringToDate(exInv.TxnDate) <Date.Today())
                exInv.selectedRow=false;
        } 
    }
    public void sortList(List<QBAccountingService.QBInvoice> lst)
    {
        for(integer i=0;i<lst.size()-1;i++)
        {
            for(integer j=i+1;j<lst.size();j++)
            {
                if(lst[i].txnDate > lst[j].TxnDate)
                {
                    QBAccountingService.QBInvoice qbi=lst[i];
                    lst[i]=lst[j];
                    lst[j]=qbi;
                }
            }
        }
    }
    public void uncheckPastBills()
    {
        for(QBAccountingService.QBBill exInv:existingBills)
        {
            if(StringToDate(exInv.TxnDate) <Date.Today())
                exInv.selectedRow=false;
        } 
    }
    public void sortBillList(List<QBAccountingService.QBBill> lst)
    {
        for(integer i=0;i<lst.size()-1;i++)
        {
            for(integer j=i+1;j<lst.size();j++)
            {
                if(lst[i].txnDate > lst[j].TxnDate)
                {
                    QBAccountingService.QBBill qbi=lst[i];
                    lst[i]=lst[j];
                    lst[j]=qbi;
                }
            }
        }
    }
    public void toggleskipnonQBvendors()
    {
        skipnonQBvendors = !skipnonQBvendors;
        resetup();
    }
    public Account getAccount(id actId)
    {
        Account a =  [SELECT  Torc_External_Id__c,Talent_Transfer_Price__c ,Invoice_Group_Type__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, 
                          BillingLongitude, BillingGeocodeAccuracy, BillingAddress, 
                          ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingLatitude, 
                          ShippingLongitude, ShippingGeocodeAccuracy, ShippingAddress, 
                          Phone, Copy_Billing_Address_to_Shipping_Address__c,
                          Id, Name, QuickBooks_Id__c, Payment_terms__c, 
                          Invoicing_Contact__c, Invoicing_Contact__r.FirstName,Quickbooks_Customer__c,
                          Invoicing_Contact__r.LastName,Invoicing_Contact__r.Email
                  FROM Account Where ID = :actId]; 
        talentTransferPricePercent =   a.Talent_Transfer_Price__c!=NULL?  a.Talent_Transfer_Price__c: talentTransferPricePercent;
        return a;          
    }
    public static Set<string> setupMasterCRMID(Set<string> qbUserIds,Account act)
    {
        Set<string> l=new Set<string>();
        string idK = (act.Torc_External_Id__c==null || act.Torc_External_Id__c=='')?act.id:act.Torc_External_Id__c;
        if(act.Invoice_Group_Type__c=='Combined-Account')
        {
            l.add(idK);
        }    
        if(act.Invoice_Group_Type__c=='Individual-Account')
        {
            for(string s:qbUserIds)
            {
                l.add(idK+'-'+s.right(12));
            }
        }    
        return l;
    }
    public static Set<string> setupMasterCRMIDForReferral(Set<string> qbUserIds,Account act)
    {
        Set<string> l=new Set<string>();
        for(string s:qbUserIds)
        {
            l.add('REFERRAL:'+s.right(12));
        }
        return l;
    }
    public static string findMasterCRMID(Account act, string qbUserId)
    {
        string idK = (act.Torc_External_Id__c==null || act.Torc_External_Id__c=='')?act.id:act.Torc_External_Id__c;
        if(act.Invoice_Group_Type__c=='Combined-Account')
            return idK;
        if(act.Invoice_Group_Type__c=='Individual-Account')
            return idK+'-'+qbUserId.right(12);
        return '';    
    }
    Public void SaveOpportunityChanges()
    {
        update opp;
        setupWithRecord();
    }
    Public void UncheckBill()
    {
        Update new Opportunity(id=opp.id,Bills_Created__c=false);
        setupWithRecord();
    }
    Public void UncheckInvoice()
    {
        Update new Opportunity(id=opp.id,Invoices_Created__c=false);
        setupWithRecord();
    }
    ////---------------------------------------**************************************************
    public void updateBillingAddressAndterms(QBAccountingService.QBCustomer customer)
    {
        customer.DisplayName = act.Name;
        customer.CompanyName = act.Name;
        Map<String,String> paymentTerms=getpaymentTerms(false,ContstantsSetup);
        customer.billAddr = new QBAccountingService.QBAddress();
        customer.shipAddr = new QBAccountingService.QBAddress();
        if(act.Payment_terms__c!=NULL)
        {
            customer.SalesTermRef = new QBAccountingService.QBNameValue();
            customer.SalesTermRef.name = act.Payment_terms__c;
            customer.SalesTermRef.value = paymentTerms.get(act.Payment_terms__c);
        }
        customer.billAddr.Line1 = act.BillingStreet;
        customer.billAddr.City = act.BillingCity;
        customer.billAddr.PostalCode = act.BillingPostalCode;
        customer.billAddr.Country = act.BillingCountry;
        customer.billAddr.CountrySubDivisionCode = act.BillingState;
        if(act.Copy_Billing_Address_to_Shipping_Address__c)
        {
            customer.shipAddr.Line1 = act.BillingStreet;
            customer.shipAddr.City = act.BillingCity;
            customer.shipAddr.PostalCode = act.BillingPostalCode;
            customer.shipAddr.Country = act.BillingCountry;
            customer.shipAddr.CountrySubDivisionCode = act.BillingState;
        }
        else
        {
            customer.shipAddr.Line1 = act.ShippingStreet;
            customer.shipAddr.City = act.ShippingCity;
            customer.shipAddr.PostalCode = act.ShippingPostalCode;
            customer.shipAddr.Country = act.ShippingCountry;
            customer.shipAddr.CountrySubDivisionCode = act.ShippingState;
        }
    }
    Public void updatAccount()
    {
        string query= 'SELECT * FROM Customer Where Id = \''+Act.Quickbooks_Id__c +'\'';
        system.debug(query);
        JSONParser jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseCustomer res=(QBAccountingService.QBResponseCustomer)jp.readValueAs(QBAccountingService.QBResponseCustomer.class);
        if(res.QueryResponse!=NULL && res.QueryResponse.customer!=NULL && res.QueryResponse.customer.size()>0)
        {
            system.debug(res.QueryResponse.customer[0]);
            updateBillingAddressAndterms(res.QueryResponse.customer[0]);
            QBAccountingService.QBCustomer customer = QBAccountingService.createCustomerinQb(res.QueryResponse.customer[0]);
            system.debug(customer);
        }    
    }
    Public void CreateAccountInQB()
    {
    
        if(act.Payment_terms__c==NULL)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please make sure account has Payment terms.'));
            return;
        }
        QBAccountingService.QBCustomer customer = new QBAccountingService.QBCustomer();
        customer.Active=True;
        updateBillingAddressAndterms(customer);
        customer = QBAccountingService.createCustomerinQb(customer);
        act.Quickbooks_Id__c = customer.Id;
        act.Quickbooks_Customer__c = customer.DisplayName;
        update act;
        resetup();
    }
    Public void Search()
    {
        try
        {
            Map<String,String> paymentTerms=getpaymentTerms(true,ContstantsSetup);
            QBCustomeridToUpdate=null;
            SearchDone = false;    
            string query= 'SELECT * FROM Customer Where DisplayName Like \'%'+searchText +'%\'';
            JSONParser jp = QBAccountingService.runQuery(query);
            customers = new List<QBAccountingService.QBCustomer>();
            QBAccountingService.QBResponseCustomer res=(QBAccountingService.QBResponseCustomer)jp.readValueAs(QBAccountingService.QBResponseCustomer.class);
            if(res.QueryResponse!=NULL && res.QueryResponse.customer!=NULL)
            {
                customers = res.QueryResponse.Customer;
                if(customers.size()>0)
                    SearchDone = true;
                for(QBAccountingService.QBCustomer c:customers)
                {
                    if(c.SalesTermRef!=NULL)
                        c.SalesTermRef.name = paymentTerms.get(c.SalesTermRef.value);
                }        
            }    
        }
        catch(exception e)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
        }
    }
    Public void SearchVendor()
    {
        try
        {
            QBvendoridToUpdate=null;
            SearchDone = false;    
            string query= 'SELECT * FROM Vendor Where DisplayName != \'_\' ';
            if(fnSearch!='' && fnSearch!=NULL)
                query += ' AND GivenName Like \'%'+fnSearch +'%\'';
            if(lnSearch!='' && lnSearch!=NULL)
                query += ' AND FamilyName Like \'%'+lnSearch +'%\'';    
                
            JSONParser jp = QBAccountingService.runQuery(query);
            vendors = new List<QBAccountingService.QBVendor>();
            QBAccountingService.QBResponseVendor res=(QBAccountingService.QBResponseVendor)jp.readValueAs(QBAccountingService.QBResponseVendor.class);
            if(res.QueryResponse!=NULL && res.QueryResponse.vendor!=NULL)
            {
                vendors = res.QueryResponse.vendor;
                if(vendors.size()>0)
                    SearchDone = true;    
            }    
        }
        catch(exception e)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
        }
    }
    public void cleanupVandors()
    {
        vendors.clear();
        QBvendoridToUpdate = null;
        TorcmemberidToUpdate = null;
    }
    Public void CreateQBVendor()
    {
        if(TorcmemberidToUpdate==NULL || TorcmemberidToUpdate=='')
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select Member.'));
            return;
        }
        for(Torc_user__c tu: torcUserList)
        {
            if(tu.id==TorcmemberidToUpdate)
            {
                QBAccountingService.QBVendor qb = new QBAccountingService.QBVendor();
                qb.PrimaryEmailAddr = new QBAccountingService.QBEmailAddress();
                qb.PrimaryEmailAddr.address = tu.Email__c;
                qb.CompanyName = ContstantsSetup.QBCOn.VendorCompanyName;
                qb.GivenName = tu.given_name__c;
                qb.FamilyName = tu.family_Name__c;
                //qb.DisplayName = tu.Email__c;                
                qb.Active = true;
                qb.PrintOnCheckName = tu.name;
                qb.AcctNum = tu.External_Id__c;
                qb = QBAccountingService.createVendorinQb(qb);
                tu.Quick_Books_vendor_Id__c = qb.Id;
                tu.Quickbooks_Vendor__c = qb.DisplayName;
                
                update tu;
                cleanupVandors();
                resetup();
                return;
            }
        }
    }
    Public void MapMemberToExtsingQBVendor()
    {
        if(QBvendoridToUpdate==null || QBvendoridToUpdate=='' || TorcmemberidToUpdate==NULL || TorcmemberidToUpdate=='')
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select vendor/Member to map.'));
            return;
        }
        for(Torc_user__c tu: torcUserList)
        {
            if(tu.id==TorcmemberidToUpdate)
            {
                for(QBAccountingService.QBVendor customer : vendors)
                {
                    if(customer.Id==QBvendoridToUpdate)
                    {
                        tu.Quick_Books_vendor_Id__c = customer.Id;
                        tu.Quickbooks_Vendor__c = customer.DisplayName;
                        update tu;
                        cleanupVandors();
                        resetup();
                        return;
                    }
                }
            }
        }
    }
    
    public string fnSearch{get;set;}
    public string lnSearch{get;set;}  
    public string QBvendoridToUpdate{get;set;}    
    public string TorcmemberidToUpdate{get;set;}    
    public void pageToken()
    {
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
    }
    public static String removeAttributes(string inp)
    {
        system.debug(inp);
        inp=inp.replace('"isEdited":true,','').replace('"isEdited":false,','').replace('"isEdited":null,','');
        inp=inp.replace('"selectedRow":true,','').replace('"selectedRow":false,','').replace('"selectedRow":null,','');
        system.debug(inp);
        return inp;
    }
    Public String searchText{get;set;}
    public List<QBAccountingService.QBCustomer> customers{get;set;}
    public List<QBAccountingService.QBVendor> vendors{get;set;}
    public string QBCustomeridToUpdate{get;set;}
    
    Public void MapAccountToExtsingQBCustomer()
    {
        if(QBCustomeridToUpdate==null || QBCustomeridToUpdate=='')
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select account to map.'));
            return;
        }
        for(QBAccountingService.QBCustomer customer : customers)
        {
            if(customer.Id==QBCustomeridToUpdate)
            {
                act.Quickbooks_Id__c = customer.Id;
                act.Quickbooks_Customer__c = customer.DisplayName;
                if(customer.SalesTermRef!=NULL)
                    act.Payment_terms__c = customer.SalesTermRef.name;
                update act;
                resetup();
                return;
            }
        }
    }
    Public static string DateToString(Date dt)
    {
        string month = string.valueOf(dt.Month());
        string day = string.valueOf(dt.Day());
        return Dt.year()+'-'+month.LeftPad(2,'0')+'-'+Day.LeftPad(2,'0');
    }
    public static date StringToDate(String dts)
    {
        List<String>l=dts.split('-');
        return Date.newInstance(Integer.valueOf(l[0]),Integer.valueOf(l[1]),Integer.valueOf(l[2]));
    }
    Public static string DateToStringMDY(Date dt)
    {
        string month = string.valueOf(dt.Month());
        string day = string.valueOf(dt.Day());
        return month+'/'+Day+'/'+Dt.year();
    }
    public static Date getfirstDayOfWeek(Date dt)
    {
        string wday = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('EEE');
        integer addday =(wDay=='Sun'?0:(wDay=='Mon'?1:(wDay=='Tue'?2:(wDay=='Wed'?3:(wDay=='Thu'?4:(wDay=='Fri'?5:6))))));
        dt=dt.adddays(addday*-1);
        return dt;
    }
    public static Date getfirstDayOfMonth(Date dt)
    {
        return date.newInstance(dt.year(),dt.Month(),1);
    }
    public static Integer getWorkingDays(Date fromDt, Date toDt)
    {
        integer num = 0;
        while(fromDt <=toDt)
        {
            string wday = DateTime.newInstance(fromDt.year(),fromDt.month(),fromDt.day()).format('EEE');
            num += (wDay=='Sun' || wDay=='Sat')?0:1;
            fromDt=fromDt.adddays(1);
        }    
        return num;
    }
    public static Map<String,String> getpaymentTerms(boolean valToName, QBContstantsSetup ContstantsSetup)
    {
        Map<String,String> paymentTerms=new Map<String,String>();
        for(QBContstantsSetup.keyval kw: ContstantsSetup.QBCOn.paymentTerms)
        {
            IF(!valToName)
                paymentTerms.Put(kw.Name,kw.value);
            else
                paymentTerms.Put(kw.value,kw.Name);
        }
        return paymentTerms;
    }
    public Map<String,String> getInternalBillCategory()
    {
        Map<String,String> ibcr=new Map<String,String>();
        for(QBContstantsSetup.keyval kw: ContstantsSetup.QBCOn.internalBillCategory)
        {
            ibcr.Put(kw.Name,kw.value);
        }
        return ibcr;
    }
    Public List<String> MondayTimeLine{get;set;}
    Public void generateMondayTimeLine(Date f, Date t)
    {
        MondayTimeLine=new List<string>();
        while(f<=t)
        {
            MondayTimeLine.add(String.valueOf(f.Month()).LeftPad(2,'0')+'/'+String.valueOf(f.Day()).LeftPad(2,'0'));    
            f=f.adddays(7);
        }
    }
    public static void updateVacationRecord(Engagement_Vacation__c ev)
    {
        if(ev.Opportunity__c!=NULL)
        {
            for(OpportunityLineItem ol:[Select ID,Talent_Hourly_Pay_Rate__c, Customer_Hourly_Bill_Rate__c,Hours_Week__c, Placement__c, Placement__r.Last_Working_Day__c
                                        from OpportunityLineItem 
                                        where OpportunityId=:ev.Opportunity__c AND Torc_User__c = :ev.Torc_User__c AND placement__c!=NULL AND Placement__r.Last_Working_Day__c!=NULL])
            {
                if(ev.Talent_Hourly_Pay_Rate__c == NULL)
                    ev.Talent_Hourly_Pay_Rate__c = ol.Talent_Hourly_Pay_Rate__c;
                if(ev.Customer_Hourly_Bill_Rate__c == NULL)
                    ev.Customer_Hourly_Bill_Rate__c = ol.Customer_Hourly_Bill_Rate__c;
                if(ev.Hours_Week__c == NULL)    
                    ev.Hours_Week__c = ol.Hours_Week__c;
                ev.placement__c = ol.Placement__c;
                if(ev.Shift_To_Date__c==NULL)
                    ev.Shift_To_Date__c = ol.Placement__r.Last_Working_Day__c.adddays(1);
            }                            
        }
        if(ev.Internal_Placement__c!=NULL)
        {
            for(Internal_Placement__c ol:[Select ID,Talent_Hourly_Pay_Rate__c,Hours_Week__c,Placement__c,Placement__r.Last_Working_Day__c
                                        from Internal_Placement__c 
                                        where Id=:ev.Internal_Placement__c AND Torc_User__c = :ev.Torc_User__c])
            {
                if(ev.Talent_Hourly_Pay_Rate__c == NULL)
                    ev.Talent_Hourly_Pay_Rate__c = ol.Talent_Hourly_Pay_Rate__c;
                ev.Customer_Hourly_Bill_Rate__c = null;
                if(ev.Hours_Week__c == NULL)    
                    ev.Hours_Week__c = ol.Hours_Week__c;
                ev.placement__c = ol.Placement__c;
                ev.Shift_To_Date__c = ol.Placement__r.Last_Working_Day__c.adddays(1);
            }                            
        }
    }
    public static void CallQBAPI(List<QB_API_call__c> lst)
    {
        if(lst.size()!=0)
        {
            QB_Api_call_master__c mas = new QB_Api_call_master__c();
            insert mas;
            mas=[Select ID,Unique_Id__c from QB_Api_call_master__c Where id=:mas.id];
            for(QB_API_call__c a:lst)
            {
                a.QB_API_Call_Master__c = mas.id;
                a.Group__c = mas.Unique_id__c;
            }
            insert lst;   
            QBAPICallBatch.ProcessNow(mas.Unique_id__c);  
        }
    }   
}