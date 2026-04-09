public class QBBulkBillUpdate
{
    public void pageToken()
    {
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
    }
    public class DataRow
    {
        public QBAccountingService.QBBill Bill{get;set;}
        public boolean getEditable()
        {
            return QBOpportunitySetup.StringToDate(bill.duedate) > Date.today();
        }
        public DataRow(QBAccountingService.QBBill b)
        {
            bill=b;
        }
    }
    Public string step{get;set;}
    public List<DataRow> lstDataRow{get;set;}
    public Dummy_Object__c fromDate{get;set;}
    public Dummy_Object__c toDate{get;set;}
    Public Torc_User__c torcUser{get;set;}
    public QBBulkBillUpdate()
    {
        step = 'SELACT';
        fromDate = new Dummy_Object__c();
        toDate = new Dummy_Object__c();
        lstDataRow = new List<DataRow>();
        torcUser=null;
        if(ApexPages.currentPage().getParameters().get('id')!='' && ApexPages.currentPage().getParameters().get('id')!=NULL)
        {
            fromDate.Torc_user__c = ApexPages.currentPage().getParameters().get('id');
        }
    }
    public string filterFor{get;set;}
    public void filterForDeleteBill()
    {
        filterFor='DELETE';
        filterForBill();
    }
    public void filterForUpdateBill()
    {
        filterFor='UPDATE';
        filterForBill();
    }
    public void filterForBill()
    {
        lstDataRow.clear();
        Date sd = fromDate.Date__c;
        Date ed = toDate.Date__c;
        string vendorQBId='';
        if(fromDate.Torc_User__c!=NULL)
        {
            for(Torc_User__c tu:[SELECT id,Quick_Books_Vendor_Id__c from Torc_User__c WHERE ID=:fromDate.Torc_User__c])
            {
                torcUser = tu;
                if(tu.Quick_Books_Vendor_Id__c ==NULL || tu.Quick_Books_Vendor_Id__c =='')
                {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please update QB ID Torc User First.'));
                    return;
                }                
                vendorQBId = tu.Quick_Books_Vendor_Id__c;
            }
        }
        step = 'SAVE';
        string query= 'SELECT * FROM Bill ';
        string cond ='';
        if(vendorQBId!=NULL && vendorQBID!='')
            cond =' WHERE VendorRef = \''+vendorQBID+'\''; 
        if(sd!=NULL)
            cond = cond +' '+  (cond==''?'WHERE':'AND') + ' TxnDate >= \''+ QBOpportunitySetup.DateToString(sd) +'\' ';
        if(ed!=NULL)
            cond = cond +' '+  (cond==''?'WHERE':'AND') + ' TxnDate <= \''+ QBOpportunitySetup.DateToString(ed) +'\' ';    
        query =query + cond + ' Order By TxnDate,DocNumber';
        lstDataRow.clear();
        system.debug(query);
        JSONParser jp = QBAccountingService.runQuery(query);
        QBAccountingService.QBResponseBill res=(QBAccountingService.QBResponseBill)jp.readValueAs(QBAccountingService.QBResponseBill.class);
        if(res.QueryResponse!=NULL && res.QueryResponse.bill!=NULL)
        {
            for(QBAccountingService.QBBill inv:res.QueryResponse.bill)
            {
                DataRow bdr = new DataRow(inv);
                lstDataRow.add(bdr);
            }    
        }
    }
    public void SaveUpdate()
    {
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(DataRow inv : lstDataRow)
        {
            QBAccountingService.QBBill bill =inv.bill;
            if(bill.selectedRow==TRUE)
            {
                QB_API_Call__c qb = new  QB_API_Call__c(Name='bill',Input__c = QBOpportunitySetup.removeAttributes(JSON.serialize(bill)));
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
            QBAccountingService.QBBill bill =inv.bill;
            if(bill.selectedRow==TRUE)
            {
                 QB_API_Call__c qb = new  QB_API_Call__c(Delete__c=true, Name='bill',Input__c = QBOpportunitySetup.removeAttributes(JSON.serialize(bill)));
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