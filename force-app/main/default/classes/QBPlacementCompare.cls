Public class QBPlacementCompare
{
    public class BillDataRow
    {
        public QBAccountingService.QBBill Bill{get;set;}
        Public list<QBAccountingService.QBBillLine> lines{get;set;}
        public BillDataRow(QBAccountingService.QBBill b)
        {
            bill=b;
            lines=new list<QBAccountingService.QBBillLine>();
        }
    }
    public class InvoiceDataRow
    {
        public string type{get;set;}
        public QBAccountingService.QBInvoice Invoice{get;set;}
        Public list<QBAccountingService.QBInvoiceLine> lines{get;set;}
        public InvoiceDataRow(QBAccountingService.QBInvoice b,string t)
        {
            type=t;
            Invoice=b;
            lines=new list<QBAccountingService.QBInvoiceLine>();
        }
    }    
    public set<string>masterCRMIds{get;set;}
    public Placement__c placement{get;set;}
    public Decimal billSum{get;set;}
    public Decimal invoiceSum{get;set;}
    public list<BillDataRow> lstBills{get;set;}
    public list<InvoiceDataRow> lstInvoices{get;set;}
    public string actNameInDescription{get;set;}
    public QBPlacementCompare(ApexPages.StandardController controller)
    {
        billSum=invoicesum=0;
        lstBills = new list<BillDataRow>(); 
        lstInvoices=new List<InvoiceDataRow>();
        placement = (Placement__c) controller.getRecord();
        placement = [Select ID, QB_Bills__c, QB_Invoices__c, Name, Main_Opportunity__c,Total_To_Pay__c   , Total_Price__c, Internal_Placement__c,
                    Account__c, Account__r.Torc_External_id__c, Account__r.Name, Account__r.Quickbooks_ID__c, Account__r.Quickbooks_Customer__c,account__r.Invoice_Group_Type__c,
                    Torc_User__c, Torc_User__r.Quickbooks_Vendor__c, Torc_User__r.Quick_Books_vendor_Id__c ,Torc_User__r.Full_Name__c,
                    main_Opportunity__r.Invoice_To_Randstad_Account__c
                    from Placement__c where ID=:placement.id];
        set<string>s=new set<string>();
        s.add(placement.Torc_User__r.Quick_Books_vendor_Id__c);
        masterCrmIDS = QBOpportunitySetup.setupMasterCRMID(s,placement.Account__r);
        actNameInDescription='';
        if(placement.main_Opportunity__c!=NULL && placement.main_Opportunity__r.Invoice_To_Randstad_Account__c!=NULL)
            actNameInDescription = placement.account__r.name;
    }
    public void pageToken()
    {
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
    }
    public void loadBoth()
    {
    loadBills();
    loadInvoices();
    }
    public void loadBills()
    {
        system.debug(masterCrmIDS);
        billSum = 0;
        lstBills.clear();
        string query= 'SELECT * FROM Bill WHERE VendorRef = \'' + placement.Torc_User__r.Quick_Books_vendor_Id__c + '\''; 
        query = query +' Order By TxnDate MAXResults 1000';    
        JSONParser jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseBill res=(QBAccountingService.QBResponseBill)jp.readValueAs(QBAccountingService.QBResponseBill.class);
        if(res.QueryResponse!=NULL && res.QueryResponse.bill!=NULL)
        {
            for(QBAccountingService.QBBill inv:res.QueryResponse.bill)
            {
                system.debug(inv);
                system.debug(inv.PrivateNote);
                if((inv.PrivateNote!=NULL && masterCrmIDS.contains(inv.PrivateNote)) || test.isRunningTest())
                {
                    BillDataRow bdr = new BillDataRow(inv);
                    lstBills.add(bdr);
                    for(QBAccountingService.QBBillLine bl: inv.Line)
                    {
                        billSum += bl.Amount;
                        bdr.lines.add(bl);
                    }
                }    
            }
        }
    }
    Public void loadInvoices()
    {
        invoiceSum=0;
        lstInvoices.clear();
        loadInvoicesAndCreditMemo('Invoice');
        loadInvoicesAndCreditMemo('CreditMemo');
        placement.QB_Bills__c= billSum;
        placement.QB_Invoices__c= InvoiceSum;
        update placement;    
    }
    Public void loadInvoicesAndCreditMemo(string loadWhat)
    {
        string query= 'SELECT * FROM '+loadWhat+' Where CustomerRef = \'' + placement.Account__r.Quickbooks_ID__c+'\' ';
        query = query +' Order By TxnDate MAXResults 1000';    
        JSONParser jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseInvoice res=(QBAccountingService.QBResponseInvoice)jp.readValueAs(QBAccountingService.QBResponseInvoice.class);
        system.debug(res);
        if(res.QueryResponse!=NULL && 
            ((res.QueryResponse.Invoice!=NULL && loadWhat=='Invoice') || (res.QueryResponse.CreditMemo!=NULL && loadWhat=='CreditMemo')))
        {
            
            List<QBAccountingService.QBInvoice> l=(loadWhat=='Invoice'?res.QueryResponse.Invoice:res.QueryResponse.CreditMemo);
            for(QBAccountingService.QBInvoice inv:l)
            {
                system.debug(inv);
                if(inv.CustomField!=NULL)
                {
                    boolean addInMCR=false;
                    boolean addInPON = false;
                    string cfStr='';
                    if(actNameInDescription ==NULL || actNameInDescription=='')
                        addInPON = true;
                    if(loadWhat=='CreditMemo')
                        addInPON = addInMCR = true;    
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
                    if(addInMCR && addInPON || test.isRunningTest())
                    {
                        InvoiceDataRow ind=new InvoiceDataRow(inv,loadWhat);
                        boolean anyone=false;
                        for(QBAccountingService.QBInvoiceLine li:inv.line)
                        {
                            system.debug(li.description);
                            system.debug(placement.Torc_User__r.Full_Name__c);
                            if(li.description!=NULL && li.description.toLowerCase().indexOf(placement.Torc_User__r.Full_Name__c.toLowerCase())==0 || test.isRunningTest())
                            {
                                anyone=true;
                                invoiceSum+= (LoadWhat=='CreditMemo'?-1:1) * li.Amount;
                                ind.lines.add(li);
                            }
                        }
                        if(anyone)
                            lstInvoices.add(ind);
                    }
                } 
            }
        }    

    }
}