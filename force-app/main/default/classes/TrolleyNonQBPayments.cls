Public class TrolleyNonQBPayments
{
    public string showRowsType{get;set;}
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
                || (showRowsType=='Error' && dr.getIsError()) 
                || (showRowsType=='Non-Error' && dr.getIsError()==FALSE))
            {
                l.add(dr);
            } 
        }
        return l;
    }
    public class processedRow
    {
        public Non_Torc_payment__c externalplacement{get;set;}
        public Trolley_Invoice__c tinv{get;set;}
        public Non_Torc_User__c nontorcuser{get;set;}
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
            externalplacement = dr.extBill;
            nontorcuser = dr.nontorcuser;
            trolleyuser = dr.recipient;            
            lstpayment = new List<Trolley_Invoice_Line_Item__c>();
            tinv = new Trolley_Invoice__c();
            tinv.Trolley_Recipient__c = dr.recipient.id;
            tInv.Cover_Fee__c = true;
            tinv.non_Torc_user__c =dr.nontorcUser.id;
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
        public DataRow(Non_Torc_payment__c b,Trolley_Recipient__c tp)
        {
            chk = false;
            extbill=b;
            recipient=tp;
            nontorcUser = b.Non_Torc_user__r;
            dummy = new Dummy_Object__c();
        }
        
        public Non_Torc_payment__c extbill{get;set;}
        Public Trolley_Recipient__c recipient{get;set;}
        Public non_Torc_user__c nontorcUser{get;set;}
        Public Dummy_Object__c dummy{get;set;}
        public boolean chk{get;set;}
        public string geterrormsg()
        {
            return
                recipient==NULL?'No trolley recipient':
                recipient.status__c!='active'?'Trolley recipient inactive':
                nontorcuser.Quick_Books_vendor_Id__c==NULL || nontorcuser.Quick_Books_vendor_Id__c ==''?'QB Not Setup':'';
                
        }
        public boolean getIsError()
        {
            return recipient==NULL || recipient.status__c!='active' || nontorcuser.Quick_Books_vendor_Id__c==NULL || nontorcuser.Quick_Books_vendor_Id__c ==''; 
        }
         public List<Trolley_Invoice_Line_Item__c> getPaymentRecord()
         {
             List<Trolley_Invoice_Line_Item__c> ltp=new List<Trolley_Invoice_Line_Item__c>();
             Trolley_Invoice_Line_Item__c tp=new Trolley_Invoice_Line_Item__c();
             tp.amount__c = extbill.Total_Amount__c;
             tp.Non_Torc_user__c=nontorcuser.id;
             tp.Trolley_Recipient__c = recipient.id;
             Datetime dt=Datetime.newinstance(extBill.For_Month__c.year(),extBill.For_Month__c.month(),1);
             tp.description__c = nonTorcuser.Account__r.Name + ' Payout '+dt.format('MMMM yyyy');
             ltp.add(tp);
             return ltp;
         }
    }
    public List<Non_Torc_payment__c> lstExternalPlacement{get;set;}
    Public List<Payment_Date__c> lstPaymentDates;
    public List<DataRow> lstDataRow{get;set;}    
    public TrolleyNonQBPayments(ApexPages.StandardController controller)
    {
        lstDataRow = new List<DataRow>();
        EngagementOpportunity=(Opportunity) controller.getRecord(); 
        filter();
    }
    public void filter()
    {
        showRowsType='All';
        lstDataRow.clear();
        refresh();
    }
    public void refresh()
    {
        EngagementOpportunity = [Select ID,CloseDate,Account.Name,
                            (SELECT Id, Name, For_Month__c, Account__c, Payment_Created__c, Non_Torc_User__r.Account__r.Name,
                                    Total_Amount__c, Friendly_Name__c, Talent_Username__c, 
                                    Non_Torc_User__c, Non_Torc_User__r.Quick_Books_vendor_Id__c, Non_Torc_User__r.Quickbooks_Vendor__c,
                                    Non_Torc_User__r.External_Id__c
                                    ,Non_Torc_User__r.Name,Non_Torc_user__r.Custom_Memo_On_Payment__c
                             from Non_Torc_payments__r Where  Payment_Created__c=FALSE)
                             FROM Opportunity where id =:EngagementOpportunity.id];
                             
                             
                             /*,Non_Torc_User__r.Multi_Account_Payment__c, 
                                    Non_Torc_User__r.First_Payment_AccountID__c, 
                                    Non_Torc_User__r.Second_Payment_AccountID__c,
                                    Non_Torc_User__r.First_Payment_Account_Percent__c*/
                             
        lstExternalPlacement=EngagementOpportunity.Non_Torc_payments__r;
        showProcessed  = false;
        Set<id> nonTorcIds = new set<id>();
        for(Non_Torc_payment__c ep:lstExternalPlacement)
        {
            nonTorcIds.add(ep.Non_Torc_user__c);
        }
        Map<id, Trolley_Recipient__c > trMap=new Map<id, Trolley_Recipient__c >();
        for(Trolley_Recipient__c tr:[Select ID, Payout_Method__c,Full_Name__c, 
                                        Non_Torc_User__c,referenceId__C, Status__c,Name 
                                        from Trolley_Recipient__c 
                                        where Non_Torc_User__c in:nonTorcIds])
        {
            trMap.put(tr.Non_Torc_User__c,tr);
        }
        for(Non_Torc_payment__c ep: lstExternalPlacement)
        {
            DataRow bdr = new DataRow(ep,trMap.get(ep.Non_Torc_user__c));                    
            lstDataRow.add(bdr);
        }
    }
    Public List<ProcessedRow> processedRows{get;set;}
    public boolean showProcessed{get;set;}
    public Trolley_Batch__c trolleyBatch{get;set;}
    public Opportunity EngagementOpportunity{get;set;}
    public void back()
    {
        showProcessed=false;
    } 
    public decimal totalPayment{get;set;}
    public void next()
    {
        totalPayment = 0;
        trolleyBatch = new Trolley_Batch__c();
        trolleyBatch.For_Non_Torc_User__c = true;
        processedRows=new List<ProcessedRow>();
        Map<string,ProcessedRow> mapRecToTP = new Map<string,ProcessedRow>();
        for(dataRow dr : lstDataRow)
        {
            if(dr.chk)
            {
                    ProcessedRow newRec = new ProcessedRow(dr);
                    mapRecToTP.put(dr.recipient.id,newRec);
                    processedRows.add(newRec);
                    newRec.lstPayment.addAll(dr.getPaymentRecord());
                    showProcessed = true;    
            }
        }
        if(processedRows.size()==0)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select atleast one valid row.'));
        }
        else
        {
        
            DateTime dt = date.today();
            trolleyBatch.Description__c = EngagementOpportunity.Account.Name + ' Payouts due on '+dt.format('dd MMMM yyyy');
            for(string repid:mapRecToTP.keyset())
            {
                string memo='';
                for(Trolley_Invoice_Line_Item__c tp:mapRecToTP.get(repId).lstPayment)
                {
                    memo = memo +(memo==''?'':', ')+tp.Description__c;
                }
                if(mapRecToTP.get(repid).nonTorcuser.Custom_Memo_On_Payment__c!=NULL && mapRecToTP.get(repid).nonTorcuser.Custom_Memo_On_Payment__c!='')
                        memo = mapRecToTP.get(repid).nonTorcuser.Custom_Memo_On_Payment__c;
                mapRecToTP.get(repid).tinv.memo__c = memo;
                totalPayment += mapRecToTP.get(repId).getTotal();
            }
            showProcessed=true;
        }
    }
    public Pagereference CreatePaymentsInTrolleyNew()
    {
        insert trolleyBatch;
        List<Trolley_Invoice__c> lstInv = new List<Trolley_Invoice__c>();
        List<Non_Torc_payment__c> extPList=new List<Non_Torc_payment__c>();
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
            extPList.add(new Non_Torc_payment__c(id=pr.externalPlacement.id, Payment_Created__c =true));
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
        upsert extPList;
        TrolleyAPICallQueue.runProcess(trolleyBatch.id);
        return new Pagereference('/'+trolleyBatch.id);
    }
    Public void reloadRecipient()
    {
        loadRecipient();
    }
    Public static void loadRecipient()
    {
        TrolleyReceipientQueue.runProcess(test.isRunningTest());
    }
    public void dummyCall()
    {
    }
}