public class QBBulkInvoiceUpdate
{
    Public QBContstantsSetup ContstantsSetup{get;set;}
    public string descriptionFilter{get;set;}
    public void pageToken()
    {
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
    }
    /*public class lineData
    {
        public lineData()
        {
            weekEndingDate=new Dummy_Object__c();
        }
        public string vendorName{get;set;}
        public string vendorId{get;set;}
        public string newDescription{get;set;}
        Public Dummy_Object__c weekEndingDate{get;set;}
    }*/
    public class DataRow
    {
        public boolean duplicate{get;set;}
        public QBAccountingService.QBInvoice Invoice{get;set;}
        public boolean isDocNumberSet{get;set;}
        public string NewMASTERCRMID{get;set;}
        public string NewPONumber{get;set;}
        public Dummy_Object__c newTxndate{get;set;}
        //Public map< Decimal,lineData> lineDataMap{get;set;}
        public boolean getEditable()
        {
            return !(Invoice.EmailStatus == 'EmailSent');
        }
        public DataRow(QBAccountingService.QBInvoice b)
        {
            duplicate = false;
            Invoice=b;
            isDocNumberSet = (Invoice.docNumber==NULL || invoice.DocNumber==NULL)?false:true;
            if(invoice.salesTermRef ==null)
                invoice.SalesTermRef = new QBAccountingService.QBNameValue();
            NewMASTERCRMID=Invoice.getMasterCrmIdVal();
            NewPONumber = Invoice.getCustomFieldVal('PO Number');
            
            //lineDataMap = new map< Decimal,lineData>();
            newTxndate = new Dummy_Object__c();
        }
        public void deletezerorows()
        {
            for(QBAccountingService.QBInvoiceLine l:Invoice.Line)
            {
                if(l.DetailType !='SubTotalLineDetail')
                    l.Amount = l.SalesItemLineDetail.Qty * l.SalesItemLineDetail.UnitPrice;
            }
            Invoice.deletZeroLines();
        }
    }
    Public string step{get;set;}
    public List<DataRow> lstDataRow{get;set;}
    public Dummy_Object__c fromDate{get;set;}
    public Dummy_Object__c toDate{get;set;}
    Public Account act{get;set;}
    Public List<Payment_Date__c> lstPaymentDates;
    
    public List<SelectOption> getpaymenttermsOptions()
    {
        Map<String,String> paymentTerms = QBOpportunitySetup.getpaymentTerms(false,ContstantsSetup);
        List<SelectOption> ifPicklist = new List<SelectOption> ();
        ifPicklist.add(new SelectOption('','-None-'));
        for(string s:paymentTerms.keyset())
        {
            ifPicklist.add(new SelectOption(paymentTerms.get(s),s));
        }
        return ifPickList;
    }
    public QBBulkInvoiceUpdate()
    {
        descriptionFilter = '';
        ContstantsSetup = NEW QBContstantsSetup();
        step = 'SELACT';
        fromDate = new Dummy_Object__c();
        toDate = new Dummy_Object__c();
        lstDataRow = new List<DataRow>();
        act=null;
        lstPaymentDates=[Select Date__c from Payment_Date__c Order By Date__c];
        if(ApexPages.currentPage().getParameters().get('id')!='' && ApexPages.currentPage().getParameters().get('id')!=NULL)
        {
            fromDate.Account__c = ApexPages.currentPage().getParameters().get('id');
        }
    }
    public string filterFor{get;set;}
    public void filterForDeleteInvoice()
    {
        filterFor='DELETE';
        filterForInvoice();
    }
    public void filterForUpdateInvoice()
    {
        filterFor='UPDATE';
        filterForInvoice();
    }
    public void filterForCrossCheck()
    {
        filterFor='CROSSCHECK';
        filterForInvoice();
    }
    public void filterForInvoice()
    {
        Date sd = fromDate.Date__c;
        Date ed = toDate.Date__c;
        string accountQBId='';
        string vendorQBId='';
        if(fromDate.Account__c!=NULL)
        {
            for(Account act1:[SELECT id,Torc_External_id__c,QuickBooks_Customer__c, Invoice_Group_Type__c,QuickBooks_Id__c from Account WHERE ID=:fromDate.Account__c])
            {
                act = act1;
                if(act1.QuickBooks_Id__c ==NULL || act1.QuickBooks_Id__c =='' || act1.Invoice_Group_Type__c==NULL)
                {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please update account QB ID and Invoice Group on Account First.'));
                    return;
                }                
                accountQBId = act.Quickbooks_Id__c;
            }
        }
        else
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please select account First.'));
            return;
        }
        //step = filterFor=='UPDATE'?'RAW':'SAVE';
        step = 'SAVE';
        Set<string> qbUserIds=new Set<string>();
        qbUserIds.add(vendorQBId);
        Set<string> masterCRMIds= QBOpportunitySetup.setupMasterCRMID(qbUserIds,act);
        string MASTERCRMID= '';
        for(string s:masterCRMIds)
            MASTERCRMID = s;
        string query= 'SELECT * FROM Invoice Where CustomerRef = \''+accountQBId+'\''; 
        if(sd!=NULL)
            query = query +' AND TxnDate >= \''+ QBOpportunitySetup.DateToString(sd) +'\' ';
        if(ed!=NULL)    
            query = query +' AND TxnDate <= \'' + QBOpportunitySetup.DateToString(ed) +'\'';
        query +=' Order By TxnDate,DocNumber maxResults 1000';
        lstDataRow.clear();
        system.debug(query);
        JSONParser jp = QBAccountingService.runQuery(query);
        Map<String,QBAccountingService.QBInvoice> existingInvoiceMap = new Map<String,QBAccountingService.QBInvoice>();
        QBAccountingService.QBResponseInvoice res=(QBAccountingService.QBResponseInvoice)jp.readValueAs(QBAccountingService.QBResponseInvoice.class);
        system.debug(res);
        set<string> torcuserNameSet = new set<string>();
        DataRow lastRow= null;
        if(res.QueryResponse!=NULL && res.QueryResponse.Invoice!=NULL)
        {
            for(QBAccountingService.QBInvoice inv:res.QueryResponse.Invoice)
            {
                DataRow bdr = new DataRow(inv);
                if(inv.BillEmail==NULL)
                   inv.BillEmail = new QBAccountingService.QBEmailAddress();
                boolean addit=true;
                if(descriptionFilter!=NULL && descriptionFilter.trim()!='')
                {
                    addit = false;
                    for(QBAccountingService.QBInvoiceLine l: bdr.Invoice.line)
                    {
                        if(l.Amount!=0 && l.Amount!=NULL && l.DetailType !='SubTotalLineDetail')
                        {
                            if(l.Description!=NULL && l.Description.toLowercase().IndexOf(descriptionFilter.toLowercase())>=0)
                            {
                                addit=true;
                                break;
                            }    
                        }
                    }
                }
                if(addit)
                {
                    lstDataRow.add(bdr); 
                    if(lastRow!=NULL && lastRow.Invoice.TxnDate==bdr.Invoice.TxnDate && lastRow.NewMASTERCRMID==bdr.NewMASTERCRMID)
                    {
                       lastRow.duplicate =  bdr.duplicate = true;
                    }
                    lastRow = bdr;
                }    
            }
        }
        if(filterFor=='CROSSCHECK')
        {
            List<DataRow> lstDataRow1=new List<DataRow>();
            for(DataRow dr:lstDataRow)
            {
                if(dr.duplicate)
                    lstDataRow1.add(dr);
            }
            lstDataRow=lstDataRow1;
        }
    }
    public void SaveUpdate()
    {
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(DataRow inv : lstDataRow)
        {
            QBAccountingService.QBInvoice invoice =inv.invoice;
            if(invoice.selectedRow==TRUE)
            {
                invoice.ShipAddr=new QBAccountingService.QBAddress();
                invoice.setMasterCrmIdVal(inv.newMasterCRMID);
                invoice.setCustomFieldVal('PO Number',inv.NewPONumber);
                inv.deletezerorows();
                QB_API_Call__c qb = new  QB_API_Call__c(Name='invoice',Input__c = QBOpportunitySetup.removeAttributes(JSON.serialize(invoice)));
                lst.add(qb);
            }     
        }
        if(lst.size()>0)
        {
            QBOpportunitySetup.CallQBAPI(lst);
            step = 'SELECT';    
        }
        else
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Select Rows to delete.'));
            return;
        }    
    }
    public void SaveDelete()
    {
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(DataRow inv : lstDataRow)
        {
            QBAccountingService.QBInvoice invoice =inv.invoice;
            if(invoice.selectedRow==TRUE)
            {
                 QB_API_Call__c qb = new  QB_API_Call__c(Delete__c=true, Name='invoice',Input__c = QBOpportunitySetup.removeAttributes(JSON.serialize(invoice)));
                 lst.add(qb);
            }     
        }
        if(lst.size()>0)
        {
            QBOpportunitySetup.CallQBAPI(lst);
            step = 'SELECT';    
        }
        else
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Select Rows to delete.'));
            return;
        }    
    }
}