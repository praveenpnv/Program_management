Public class TrolleyPayments
{
    public string showRowsType{get;set;}
    public string showAccounts{get;set;}
    public set<string> showAccountSet{get;set;}
    public List<SelectOption> getshowAccountOptions()
    {
        List<SelectOption> ifPicklist = new List<SelectOption> ();
        ifPicklist.add(new SelectOption('All','All'));
        for(string s:showAccountSet)
            ifPicklist.add(new SelectOption(s,s));    
        return ifPickList;
    }
    
    public List<SelectOption> getShowTypes()
    {
        List<SelectOption> ifPicklist = new List<SelectOption> ();
        ifPicklist.add(new SelectOption('All','All'));
        ifPicklist.add(new SelectOption('Error','Error'));
        ifPicklist.add(new SelectOption('Non-Error','Non-Error'));
        return ifPickList;
    }
    public List<DataRow> getshowableRows()
    {
        List<DataRow> l=new List<DataRow>();
        for(DataRow dr:lstDataRow)
        {
            if(showRowsType=='All' 
                || (showRowsType=='Error' && dr.getIsError() && dr.rowType!='sum') 
                || (showRowsType=='Non-Error' && (dr.getIsError()==FALSE || (dr.rowType=='sum' && dr.nonErrorRowCount()>0))))
            {
                if(showAccounts=='All' || dr.accounts.contains(showAccounts) || dr.rowType=='sum')
                    l.add(dr);
            } 
        }
        return l;
    }
    
    public void pageToken()
    {
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
    }
    public class processedRow
    {
        public Trolley_Invoice__c tinv{get;set;}
        public Torc_User__c torcuser{get;set;}
        public Trolley_recipient__c trolleyuser{get;set;}
        public List<Trolley_Invoice_Line_Item__c> lstpayment{get;set;}
        public string getrealName()
        {
            if(trolleyuser.Name==trolleyuser.Full_Name__c)
                return trolleyuser.Full_Name__c;
            else
                return trolleyuser.Name+' ('+trolleyuser.Full_Name__c+')';    
        }
        public processedRow(DataRow dr)
        {
            torcUser = dr.torcuser;
            trolleyuser = dr.recipient;
            
            lstpayment = new List<Trolley_Invoice_Line_Item__c>();
            tinv = new Trolley_Invoice__c();
            tinv.Trolley_Recipient__c = dr.recipient.id;
            tInv.Cover_Fee__c = false;
            tinv.Torc_user__c =dr.torcUser.id;
            if(trolleyuser.Payout_Method__c!='paypal')
                tinv.Cover_Fee__c = dr.torcuser.Auto_Set_Cover_Charges__c;
            
        }
        public decimal getTotal()
        {
            Decimal tot=0;
            for(Trolley_Invoice_Line_Item__c b: lstPayment)
            {
                tot +=b.Amount__c;
            }
            return tot;
        }
    }
    public class DataRow
    {
        public string rowType{get;set;}
        public string existingPaymentStatus{get;set;}
        public set<string>accounts{get;set;}
        public string getaccountNames()
        {
            return String.join(new List<String>(accounts), ',');
        }
        public void setupAccountNames()
        {
            accounts=new set<string>();
            if(TorcUser!=NULL && TorcUser.placements__r.size()>0)
                for(Placement__c p:TorcUser.placements__r)
                    accounts.add(p.Account__r.name);
        }
        public decimal getTotal()
        {
            Decimal tot=0;
            if(rowType=='sum')
            {
                for(DataRow d: rowshere)
                {
                    if(d.chk)
                    {
                        for(QBAccountingService.QBBillLine bLine: d.bill.line)
                         {
                             tot +=bLine.Amount;
                         }
                         
                    }
                }
            }
            return tot;
        }
        public List<DataRow> rowsHere{get;set;}
        public integer nonErrorRowCount()
        {
            integer i=0;
            if(rowType=='sum')
            {
                for(DataRow d: rowshere)
                {
                    if(!d.getisError())
                        i++;
                }
            }
            return i;
        }
        public DataRow()
        {
            rowType='sum';
            chk = false;
            recipient=null;
            torcUser=null;
            existingPaymentStatus='';
            rowsHere = new List<DataRow>();
            accounts=new set<string>();
        }
        public DataRow(QBAccountingService.QBBill b)
        {
            rowType = 'bill';
            chk = false;
            bill=b;
            recipient=null;
            torcUser=null;
            existingPaymentStatus='';
            dummy = new Dummy_Object__c();
            accounts=new set<string>();
        }
        public QBAccountingService.QBBill bill{get;set;}
        Public Trolley_Recipient__c recipient{get;set;}
        Public Torc_user__c torcUser{get;set;}
        Public Dummy_Object__c dummy{get;set;}
        public boolean chk{get;set;}
        public boolean getIsError()
        {
            return torcUser==NULL || recipient==NULL || existingPaymentStatus!='' || recipient.status__c!='active'; 
        }
       
        public boolean updateTorcUser()
        {
            if(dummy.Torc_user__c==NULL)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please select torc user.'));
                return false;
            }
            Torc_User__c tu=[Select ID,Quick_Books_vendor_Id__c,QuickBooks_vendor__c from Torc_User__c Where Id=:dummy.Torc_user__c];
            if(tu.Quick_Books_vendor_Id__c!=NULL && tu.Quick_Books_vendor_Id__c!='')
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Selected User already Mapped to someone else.'));
                return false;
            }
            tu.Quick_Books_vendor_Id__c = bill.vendorref.value;
            tu.QuickBooks_vendor__c =bill.VendorRef.Name;
            update tu;
            return true;                                     
        }
         public List<Trolley_Invoice_Line_Item__c> getPaymentRecord()
         {
             List<Trolley_Invoice_Line_Item__c> ltp=new List<Trolley_Invoice_Line_Item__c>();
                 for(QBAccountingService.QBBillLine bLine: bill.line)
                 {
                     Trolley_Invoice_Line_Item__c tp=new Trolley_Invoice_Line_Item__c();
                     tp.amount__c = bLine.Amount;
                     tp.Torc_user__c=torcuser.id;
                     tp.Trolley_Recipient__c = recipient.id;
                     tp.Quickbooks_payment_Json__c = JSON.serialize(bill);
                     tp.QB_Bill_Id__c = bill.id;
                     tp.QB_Bill_line_Id__c = bLine.id;
                     tp.description__c = bLine.description==null?'':bLine.description.left(90);
                     ltp.add(tp);
                 }    
             return ltp;
         }
    }
    public string forUpdateId{get;set;}
    public void updateTorcuser()
    {
        for(DataRow bdr:lstDatarow)
        {
            if(bdr.rowType=='bill' && bdr.bill.id==forUpdateId)
            {
                if(bdr.updateTorcUser())
                    refresh();
                return;    
            }
        }
    }
    Public List<Payment_Date__c> lstPaymentDates;
    public List<DataRow> lstDataRow{get;set;}
    public Dummy_Object__c fromDate{get;set;}
    public Dummy_Object__c toDate{get;set;}
    public boolean coverFees{get;set;}     
    public TrolleyPayments()
    {
        showAccountSet = new set<string>();
        showAccounts='All';
        maxCount=Integer.ValueOf(Torc_Constants__c.getInstance().Max_payments__c);
        everythingCome = true;
        nextStartPosition=1;
        showRowsType='All';
        showProcessed = coverFees = false;
        fromDate = new Dummy_Object__c();
        toDate = new Dummy_Object__c();
        lstDataRow = new List<DataRow>();
        lstPaymentDates=[Select Date__c from Payment_Date__c Order By Date__c];
        Date weekendDate= QBOpportunitySetup.getFirstdayOfWeek(Date.today()).adddays(-2);
        weekendDate = QBOpportunitySetup.getBillDuedate(weekendDate, lstPaymentDates);
        if(weekendDate<Date.today())
            weekendDate=weekendDate.adddays(14);
        fromDate.Date__c = weekendDate;
        toDate.Date__c = weekendDate;
    }
    public integer maxCount=500;
    public integer nextStartPosition{get;set;}
    public boolean everythingCome{get;set;}
    public void filter()
    {
        lstDataRow.clear();
        nextStartPosition=1;
        everythingCome = true;
        filterNowPass();
    }
    public void filterNowPass()
    {
        Map<string,DataRow> docNumberMap=new Map<string,DataRow>();
        filterNowPass2('Bill',docNumberMap);
        filterNowPass2('vendorcredit',docNumberMap);
    }
    public void filterNowPass2(string billOrCredit,Map<string,DataRow> docNumberMap)
    {
        
        Date sd = fromDate.Date__c;
        Date ed = toDate.Date__c;
        string dateFilter = billOrCredit!='Bill'?'TxnDate':'DueDate';
        
        string query= 'SELECT * FROM '+billOrCredit+' Where '+dateFilter+' >= \''+ QBOpportunitySetup.DateToString(sd) +'\' ';
        query = query +' AND '+dateFilter+' <= \'' + QBOpportunitySetup.DateToString(ed) +'\'';
    
        if(billOrCredit=='Bill')
            query = query +' AND Balance > \'0\' ';
        query +=' Order By VendorRef,TxnDate,DocNumber MAXRESULTS '+maxCount;
        system.debug(query);
        JSONParser jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseBill res=(QBAccountingService.QBResponseBill)jp.readValueAs(QBAccountingService.QBResponseBill.class);
        string existingvenId ='';
        List<DataRow> listOfSameVendor=new List<DataRow>();
        List<QBAccountingService.QBBill>lstItems = res.QueryResponse==NULL?NULL :(billOrCredit=='Bill'?res.QueryResponse.Bill:res.QueryResponse.VendorCredit);
        if(res.QueryResponse!=NULL && lstItems!=NULL)
        {
            nextStartPosition =   res.QueryResponse.startPosition +res.QueryResponse.maxresults;
            if(maxCount ==res.QueryResponse.totalCount)
            {
                everythingCome = false; 
            }
            for(QBAccountingService.QBBill bill:lstItems)
            {
                if(billOrCredit=='vendorcredit')
                {
                    if(docNumberMap.get(bill.DocNumber)!=NULL)
                    {
                        for(QBAccountingService.QBBillLine bLine: bill.line)
                            bLine.amount = bLine.Amount*-1;
                        docNumberMap.get(bill.DocNumber).bill.line.addAll(bill.line);
                    }    
                }
                else
                {
                    if(bill.VendorRef.Value!=existingvenId)
                    {
                        if(existingvenId!='')
                        {
                            DataRow bdrTot = new DataRow();        
                            bdrTot.rowsHere = listOfSameVendor;
                            lstDataRow.add(bdrTot);
                        }
                        listOfSameVendor  =new List<DataRow>();
                        existingvenId = bill.VendorRef.Value;
                    }
                    DataRow bdr = new DataRow(bill);
                    docNumberMap.put(bill.Docnumber,bdr);
                    lstDataRow.add(bdr);
                    listOfSameVendor.add(bdr);
               }    
            }
            if(existingvenId!='' && billOrCredit=='bill')
            {
                DataRow bdrTot = new DataRow();        
                bdrTot.rowsHere = listOfSameVendor;
                lstDataRow.add(bdrTot);
            }
        }
        refresh();
    }
    public void refresh()
    {
        set<string> keyreceipient = new set<string>();
        set<string> qbbillIds=new set<string>();
        showAccountSet.clear();
        showAccounts='All';

        for(DataRow bdr:lstDatarow)
        {
            if(bdr.rowType=='bill')
            {
                keyreceipient.add(bdr.bill.VendorRef.value);
                qbbillIds.add(bdr.bill.id);
            }
        }
        map<string,trolley_Invoice_Line_Item__c> existingLines = new map<string,trolley_Invoice_Line_Item__c>();
        for(trolley_Invoice_Line_Item__c inl:[Select ID,QB_Bill_Id__c,Trolley_Invoice__r.Payment_Status__c 
                                                    From trolley_Invoice_Line_Item__c 
                                                    Where QB_Bill_Id__c in:qbbillIds
                                                    AND Trolley_Invoice__r.Payment_Status__c not in ('deleted','failed')])
        {
            existingLines.put(inl.QB_Bill_Id__c,inl);
        }                                                    
        
        
        Map<string,Torc_User__c> mapqbtoTorcUser=new Map<string,Torc_User__c>();
        set<id> tuIds=new set<id>();
        
        for(Torc_user__c tu : [Select ID, Auto_Set_Cover_Charges__c, external_Id__c, Full_Name__c, Given_name__c,Family_Name__c,Email__c, Quick_Books_vendor_Id__c
                                ,(Select Id, Payout_method__c, referenceId__c,Name,Full_Name__c,Status__c from Trolley_Recipients__r)
                                ,(Select id, Account__c,Account__r.Name from Placements__r Where Active__c=TRUE order by Createddate DESC LIMIT 3)
                                 FROM Torc_user__c Where Quick_Books_vendor_Id__c in:keyreceipient])
        {
            mapqbtoTorcUser.put(tu.Quick_Books_vendor_Id__c,tu);
            tuIds.add(tu.id);
        }
        for(DataRow dr:lstDataRow)
        {
            if(dr.rowType=='bill')
            {
                dr.TorcUser = mapqbtoTorcUser.get(dr.bill.VendorRef.value);
                if(dr.TorcUser!=NULL && dr.TorcUser.Trolley_Recipients__r.size()>0)
                    dr.recipient = dr.TorcUser.Trolley_Recipients__r[0];
                dr.setupAccountNames();
                showAccountSet.addAll(dr.accounts);
                if(existingLines.get(dr.bill.id)!=NULL)
                {
                    dr.existingPaymentStatus = existingLines.get(dr.bill.id).Trolley_Invoice__r.Payment_Status__c;
                }    
            }
        }
    }
    Public List<ProcessedRow> processedRows{get;set;}
    public boolean showProcessed{get;set;}
    public Trolley_Batch__c trolleyBatch{get;set;}
    public void back()
    {
        showProcessed=false;
    } 
    public decimal totalPayment{get;set;}
    public void next()
    {
        totalPayment = 0;
        trolleyBatch = new Trolley_Batch__c();
        processedRows=new List<ProcessedRow>();
        Map<string,ProcessedRow> mapRecToTP = new Map<string,ProcessedRow>();
        Date BiggestDate=Date.newInstance(1990,1,1);
        for(dataRow dr : lstDataRow)
        {
            if(dr.chk)
            {
                if(mapRecToTP.get(dr.recipient.id)==NULL)
                {
                    ProcessedRow newRec = new ProcessedRow(dr);
                    mapRecToTP.put(dr.recipient.id,newRec);
                    processedRows.add(newRec);
                }
                mapRecToTP.get(dr.recipient.id).lstPayment.addAll(dr.getPaymentRecord());
                Date dueDate = QBOpportunitySetup.StringToDate(dr.bill.DueDate);
                if(DueDate > BiggestDate)
                    BiggestDate = Duedate;
                showProcessed = true;    
            }
        }
        if(processedRows.size()==0)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select atleast one valid row.'));
        }
        else
        {
            DateTime dt = DateTime.newInstance(BiggestDate.year(),BiggestDate.Month(),BiggestDate.day());
            trolleyBatch.Description__c = 'Payouts due on '+dt.format('dd MMMM yyyy');
            for(string repid:mapRecToTP.keyset())
            {
                string memo='';
                for(Trolley_Invoice_Line_Item__c tp:mapRecToTP.get(repId).lstPayment)
                {
                    memo = memo +(memo==''?'':', ')+tp.Description__c;
                }
                memo=memo.left(90);
                mapRecToTP.get(repid).tinv.memo__c = memo;
                totalPayment += mapRecToTP.get(repId).getTotal();
            }
        }
    }
    public Pagereference CreatePaymentsInTrolleyNew()
    {
        insert trolleyBatch;
        List<Trolley_Invoice__c> lstInv = new List<Trolley_Invoice__c>();
        integer passNumber = 0;
        integer rows = 0;
        for(processedRow pr:processedRows)
        {
            pr.tInv.Trolley_Batch__c = trolleyBatch.id;
            pr.tInv.pass_Number__c = passNumber;
            rows++;
            if(rows>= Torc_Constants__c.getInstance().Trolley_Payment_batch_Size__c)
            {
                rows=0;
                passNumber++;
            }
            lstInv.add(pr.tInv);
        }
        insert lstInv;
        List<Trolley_Invoice_Line_Item__c> lstpaymentsINV = new List<Trolley_Invoice_Line_Item__c >();
        
        for(processedRow pr:processedRows)
        {
            for(Trolley_Invoice_Line_Item__c tp:pr.lstPayment)
            {
                tp.Trolley_Batch__c = trolleyBatch.id;
                tp.Trolley_Invoice__c = pr.tInv.id;
            }
            lstpaymentsINV.addAll(pr.lstPayment);
        } 
        insert lstpaymentsINV;
        TrolleyAPICallQueue.runProcess(trolleyBatch.id);
        return new Pagereference('/'+trolleyBatch.id);
    }

    Public void reloadRecipient()
    {
        loadRecipient();
        refresh();
    }
    Public static void loadRecipient()
    {
        TrolleyReceipientQueue.runProcess(test.isRunningTest());
    }
    public void dummyCall()
    {
    }
}