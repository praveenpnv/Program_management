public class QBAccountingService 
{    
    public QBHttpService service = null;   
    public QBAccountingService(String token, boolean isProd) 
    {
        this.service = new QBHttpService(isProd);
        this.service.setAccessToken('bearer', token);
    }
    public QBAccountingService(String token, String realmId,boolean isProd) 
    {
        this.service = new QBHttpService(realmId,isProd);
        this.service.setAccessToken('bearer', token);
    }
    Public static JSONParser runQuery(string sql)
    {
        QB_Auth__c qbauth =[Select Id, Access_Token__c, realm_Id__c, Production__c,Access_Token_Expires_In__c from QB_Auth__c where Active__c=TRUE LIMIT 1];
        QBAccountingService qba = new QBAccountingService(qbauth.Access_Token__c, qbauth.realm_Id__c, qbAuth.Production__c);
        string body = qba.service.query(sql);  
        system.debug(body);  
        JSONParser jp = JSON.createParser(body);
        return jp;    
    }
    Public static QBHttpService getQBHttpService()
    {
        QB_Auth__c qbauth =[Select Id, Access_Token__c, realm_Id__c, Production__c,Access_Token_Expires_In__c from QB_Auth__c where Active__c=TRUE LIMIT 1];
        return new QBHttpService(qbauth.Access_Token__c, qbauth.realm_Id__c, qbAuth.Production__c);
    }
    Public static string createinQb(string typ, string JSONS)
    {
        QBHttpService qb = getQBHttpService();
        return qb.postObject(typ,JSONS);
    }
    
    Public static QBCustomer createCustomerinQb(QBCustomer customer)
    {
        string resp = createinQb('customer',JSON.serialize(customer));
        JSONParser jp = JSON.createParser(resp);
        QBResponseCustomerSingle customerres=(QBResponseCustomerSingle)jp.readValueAs(QBResponseCustomerSingle.class);
        return customerres.customer;
    }
    Public static QBvendor createVendorinQb(QBvendor vendor)
    {
        string resp = createinQb('vendor',JSON.serialize(vendor));
        JSONParser jp = JSON.createParser(resp);
        QBResponsevendorSingle vendorres=(QBResponsevendorSingle)jp.readValueAs(QBResponsevendorSingle.class);
        return vendorres.vendor;
    }
    
    
    public class QBResponseInvoiceSingle
    {
        public QBInvoice Invoice;
        public String time_x;
    }
    public class QBResponseCustomerSingle
    {
        public QBCustomer Customer;
        public String time_x;
    }
    public class QBResponseCustomer
    {
        public QBQueryResponseCustomer QueryResponse;
        public String time_x;
    }
    public class QBQueryResponseCustomer 
    {
        public QBCustomer[] Customer{get;set;}
        public Integer startPosition;
        public Integer maxResults;
    }
    public class QBCustomer 
    {
        public string SyncToken{get;set;}
        public QBNameValue SalesTermRef{get;set;}
        //public boolean Job{get;set;}
        public String Id{get;set;}   //1
        public QBCurrency CurrencyRef;
        public QBMetadata MetaData;
        public QBAddress BillAddr{get;set;}
        public QBAddress ShipAddr{get;set;}
        //public string GivenName{get;set;}   //1
        public string CompanyName{get;set;}   //1
        //public string FamilyName{get;set;}   //1
        public string DisplayName{get;set;}   //1
        public boolean Active{get;set;}   //1
        //public Decimal Balance{get;set;}
        //public Decimal BalanceWithJobs{get;set;}
        Public QBFreeFormNumber PrimaryPhone{get;set;}
        Public QBEmailAddress PrimaryEmailAddr{get;set;}
    }
    public class QBAddress 
    {
        public String Id;   //2
        public String Line1;    //4581 Finch St.
        public String City; //Bayshore
        public String CountrySubDivisionCode;   //CA
        public String PostalCode;   //94326
        //public String Lat;  //INVALID
        //public String Long_x; //INVALID
        public String Country;
    }
    
    public class QBCurrency 
    {
        public String value;    //USD
        public String name; //United States Dollar
    }
    public class QBMetadata 
    {
        public String CreateTime;   //2017-06-22T16:48:43-07:00
        public String LastUpdatedTime;  //2017-06-29T13:39:32-07:00
    }
    public class QBFreeFormNumber 
    {
        public String FreeFormNumber;   //(650) 555-3311
    }
    public class QBEmailAddress 
    {
        public String Address{get;set;}  //Birds@Intuit.com
    }
    public class QBURI 
    {
        public String URI;
    }
    
    public class QBResponseCreditMemo
    {
        public QBQueryResponseCreditMemo QueryResponse;
        public String time_x;
    }
    public class QBQueryResponseCreditMemo
    {
        public QBCreditMemo[] CreditMemo{get;set;}
        public Integer startPosition;
        public Integer maxResults;
        public Integer totalCount;
    }
    Public class QBCreditMemo
    {
        public string DocNumber{get;set;}
    }    
    
    public class QBResponseInvoice
    {
        public QBQueryResponseInvoice QueryResponse;
        public String time_x;
    }
    public class QBQueryResponseInvoice
    {
        public QBInvoice[] Invoice{get;set;}
        public QBInvoice[] CreditMemo{get;set;}
        public Integer startPosition;
        public Integer maxResults;
        public Integer totalCount;
    }
    Public class QBInvoice
    {
        public QBInvoice()
        {
            isEdited=false;
            selectedRow=true;
            ShipAddr = new QBAddress();
        }
        public string SyncToken{get;set;}
        public boolean isEdited{get;set;}
        public boolean selectedRow{get;set;}
        public string EmailStatus{get;set;}
        public string Id{get;set;}
        public string TxnDate{get;set;}
        public string DocNumber{get;set;}
        public QBCurrency CurrencyRef;
        public QBNameValue SalesTermRef{get;set;}
        Public QBEmailAddress BillEmail{get;set;}
        Public QBNameValue CustomerRef{get;set;}
        Public List<QBCustomField> CustomField{get;set;}
        Public Decimal TotalAmt{get;set;}
        Public List<QBInvoiceLine> Line{get;set;}
        //public string PrivateNote{get;set;}
        public QBOnlyValue CustomerMemo{get;set;}
        public QBAddress ShipAddr{get;set;}
        
        public string getCustomFieldVal(string fldName)
        {
            if(CustomField!=NULL)
            {
                for(QBCustomField cf:CustomField)
                    if(cf.Name==fldName)
                        return cf.StringValue;
            }
            return '';
        }
        public void setCustomFieldVal(string fldName,string newVal)
        {
            if(CustomField!=NULL)
            {
                for(QBCustomField cf:CustomField)
                    if(cf.Name==fldName)
                        cf.StringValue = newVal;
            }
        }
        
        
        
        
        public string getMasterCrmIdVal()
        {
            return getCustomFieldVal('MASTERCRMID');
        }
        public void setMasterCrmIdVal(string newVal)
        {
            setCustomFieldVal('MASTERCRMID',newVal);
        }
        Public List<QBInvoiceLine> getSalesLine()
        {
            List<QBInvoiceLine> L = new List<QBInvoiceLine>();
            for(QBInvoiceLine a:Line)
                if(a.DetailType!='SubTotalLineDetail')
                    l.add(a);
            return L;        
        }
        Public void deletZeroLines()
        {
             List<QBInvoiceLine> LineNew=new List<QBInvoiceLine>();
             for(QBInvoiceLine l:Line)
                 if(l.Amount!=0 && l.Amount!=NULL && l.DetailType !='SubTotalLineDetail')
                     LineNew.add(l);
             line=lineNew;        
        }
        public string getUpdateStyle()
        {
            integer editCount=0;
            integer DeleteCount=0;
            Integer totalValid=0;
            integer addCount=0;
            for(QBInvoiceLine l:Line)
                if(l.DetailType !='SubTotalLineDetail')
                {
                     if(l.Amount==0 || l.Amount==NULL)
                         deleteCount++;
                     else
                         totalValid++;    
                     if(l.IsEdited==TRUE)
                         editCount++;
                     if(l.id==null)
                         addCount++;    
                 }        
            return Id==NULL?'#aff5af':(totalValid==0?'#f9c7c7':(editCount>0 || addCount>0?'yellow':'white'));
        }
        public decimal gettotalAmount()
        {
            Decimal total=0;
            for(QBInvoiceLine nL:Line)
            {
                if(nl.DetailType !='SubTotalLineDetail')
                    total +=nl.Amount;
            }
            return total;
        }
        Public void mergeLines(List<QBInvoiceLine> newLines)
        {
            isEdited=true;
            for(QBInvoiceLine nL:newLines)
            {
                boolean exists=false;
                for(QBInvoiceLine oL:Line)
                {
                    exists = ol.trymergeLineItem(nl);
                    if(exists)
                    {
                        ol.isEdited=true;
                        break;
                    }
                }
                if(!exists)
                {
                    Line.add(nL);
                }
            }
            sortLines();
        }
        Public void sortLines()
        {
            for(integer i=0;i<line.size();i++)
            {
                for(integer j=i+1;j<line.size();j++)
                {
                    if(line[j].Description<line[i].Description)
                    {
                        QBInvoiceLine a=Line[i];
                        line[i]=line[j];
                        line[j]=a;
                    }
                }
            }
            integer x=1;
            for(integer j=0;j<line.size();j++)
            {
                if(line[j].DetailType !='SubTotalLineDetail')
                    line[j].LineNum=x++;
            }
        }
    }
    Public class QBOnlyValue
    {
        public string value{get;set;}
    }
    public class QBDeliveryInfo
    {
         public string DeliveryType{get;set;}   
         public string DeliveryTime{get;set;}
    }
    public class QBCustomField
    {
        public string DefinitionId {get;set;}
        public string Name{get;set;}
        public string Type{get;set;}
        public string StringValue{get;set;}
    }
    public class QBInvoiceLine
    {
        public boolean isEdited{get;set;}
        public string Description{get;set;}
        public string DetailType{get;set;}
        public Integer LineNum{get;set;}
        public Decimal Amount{get;set;}
        public string Id{get;set;}
        Public QBLineItemDetail SalesItemLineDetail{get;set;}
        public string getUpdateStyle()
        {
            return id==NULL?'#aff5af':(Amount==0?'#f9c7c7':(isEdited==TRUE?'yellow':'white'));
        }
        public boolean trymergeLineItem(QBInvoiceLine nl)
        {
            boolean exists = false;
            system.debug (Description+'===='+nL.Description+'======='+(Description == nL.Description));
            if(Description==NULL)Description='';
            if(nL.Description==NULL)nL.Description='';
            
            if(Description.replace(' ','') == nL.Description.replace(' ',''))
            {
                system.debug('here1');
                IF(SalesItemLineDetail!=NULL && 
                    nl.SalesItemLineDetail!=NULL)
                {                            
                    system.debug('here2');
                    if(SalesItemLineDetail.Qty == nl.SalesItemLineDetail.Qty 
                        || SalesItemLineDetail.UnitPrice == nl.SalesItemLineDetail.UnitPrice
                        || SalesItemLineDetail.UnitPrice == nl.SalesItemLineDetail.UnitPrice*-1)
                    {
                        system.debug('here3');
                        exists = true;
                        Amount += nl.Amount;        
                        if(SalesItemLineDetail.Qty == nl.SalesItemLineDetail.Qty)
                            SalesItemLineDetail.UnitPrice += nl.SalesItemLineDetail.UnitPrice;
                        else if(SalesItemLineDetail.UnitPrice == nl.SalesItemLineDetail.UnitPrice*-1)
                            SalesItemLineDetail.Qty -= nl.SalesItemLineDetail.Qty;
                        else
                            SalesItemLineDetail.Qty += nl.SalesItemLineDetail.Qty;   
                    }
                }    
            } 
            return exists;   
        }
    }
    public class QBLineItemDetail
    {
        public Decimal Qty{get;set;}
        public Decimal UnitPrice{get;set;}
        Public QBNameValue TaxCodeRef{get;set;}
        Public QBNameValue ItemRef{get;set;}
    }
    Public class QBNameValue
    {
        Public string name{get;set;}
        public string value{get;set;}
    }
    Public class QBPrivateNote
    {
        public QBPrivateNote()
        {
            Members=new List<String>();
        }
        Public string CRMID{get;set;}
        Public List<string>Members{get;set;}
    }
    
    public class QBResponseVendor
    {
        public QBQueryResponseVendor QueryResponse;
        public String time_x;
    }
    public class QBQueryResponseVendor
    {
        public QBVendor[] Vendor{get;set;}
    }
    Public class QBVendor
    {
        public string Id{get;set;}
        public QBEmailAddress PrimaryEmailAddr{get;set;}
        public string GivenName{get;set;}
        public string DisplayName{get;set;}
        public string FamilyName{get;set;}
        public string PrintOnCheckName{get;set;}
        public boolean Active{get;set;}
        public string AcctNum{get;set;}
        public string CompanyName{get;set;}
    }
    public class QBResponseVendorSingle
    {
        public QBvendor Vendor;
        public String time_x;
    }
    
    
    public class QBEntityRef
    {
        public string value{get;set;}
        public string name{get;set;}
        public string type{get;set;} //Vendor
    }
    
    //---------------------------------------------------------------------------------------------
    public class QBResponseBill
    {
        public QBQueryResponseBill QueryResponse;
        public String time_x;
    }
    public class QBQueryResponseBill
    {
        public QBBill[] Bill{get;set;}
        public QBBill[] VendorCredit{get;set;}
        public integer startPosition{get;set;}
        public integer maxResults{get;set;}
        public integer totalCount{get;set;}
    }
    Public class QBBill
    {
        public QBBill()
        {
            isEdited=false;
            selectedRow=true;
        }
        public boolean selectedRow{get;set;}
        public string SyncToken{get;set;}
        public boolean isEdited{get;set;}
        public string Id{get;set;}
        
        public QBNameValue VendorRef{get;set;}
        //public QBNameValue APAccountRef{get;set;}
        public string TxnDate{get;set;}
        public string DueDate{get;set;}
        public QBNameValue SalesTermRef{get;set;}
        public string DocNumber{get;set;}
        public string PrivateNote{get;set;}
        Public List<QBBillLine> Line{get;set;}
        
        
        Public void deletZeroLines()
        {
             List<QBBillLine> LineNew=new List<QBBillLine>();
             for(QBBillLine l:Line)
                 if(l.Amount!=0 && l.Amount!=NULL)// && l.DetailType !='SubTotalLineDetail'
                     LineNew.add(l);
             line=lineNew;        
        }
        public string getUpdateStyle()
        {
            integer editCount=0;
            integer DeleteCount=0;
            Integer totalValid=0;
            integer addCount=0;
            for(QBBillLine l:Line)
                if(l.DetailType !='SubTotalLineDetail')
                {
                     if(l.Amount==0 || l.Amount==NULL)
                         deleteCount++;
                     else
                         totalValid++;    
                     if(l.IsEdited==TRUE)
                         editCount++;
                     if(l.id==null)
                         addCount++;    
                 }        
            return Id==NULL?'#aff5af':(totalValid==0?'#f9c7c7':(editCount>0 || addCount>0?'yellow':'white'));
        }
        
        Public void mergeLines(List<QBBillLine> newLines)
        {
            isEdited=true;
            for(QBBillLine nL:newLines)
            {
                boolean exists=false;
                for(QBBillLine oL:Line)
                {
                    exists = ol.trymergeLineItem(nl);
                    if(exists)
                    {
                        ol.isEdited=true;
                        break;
                    }
                }
                if(!exists)
                {
                    Line.add(nL);
                }
            }
            //deletZeroLines();
        }
        public decimal gettotalAmount()
        {
            Decimal total=0;
            for(QBBillLine nL:Line)
            {
                    total +=nl.Amount;
            }
            return total;
        }
        
    }
    public class QBBillLine
    {
        public boolean isEdited{get;set;}
        public string Id{get;set;}
        public string Description{get;set;}
        public Decimal Amount{get;set;}
        public string DetailType{get;set;}//AccountBasedExpenseLineDetail
        public Decimal LineNum{get;set;}
        //public QBItemBasedExpenseLineDetail ItemBasedExpenseLineDetail{get;set;}
        public QBAccountBasedExpenseLineDetail AccountBasedExpenseLineDetail{get;set;}
        public string getUpdateStyle()
        {
            return id==NULL?'#aff5af':(Amount==0?'#f9c7c7':(isEdited==TRUE?'yellow':'white'));
        }
        public boolean trymergeLineItem(QBBillLine nl)
        {
            boolean exists = false;
            if(Description == nL.Description)
            {
                /*IF(ItemBasedExpenseLineDetail!=NULL && nl.ItemBasedExpenseLineDetail!=NULL)
                {                            
                    if(ItemBasedExpenseLineDetail.Qty == nl.ItemBasedExpenseLineDetail.Qty 
                        || ItemBasedExpenseLineDetail.UnitPrice == nl.ItemBasedExpenseLineDetail.UnitPrice
                        || ItemBasedExpenseLineDetail.UnitPrice == nl.ItemBasedExpenseLineDetail.UnitPrice*-1)
                    {
                        exists = true;
                        Amount += nl.Amount;        
                        if(ItemBasedExpenseLineDetail.Qty == nl.ItemBasedExpenseLineDetail.Qty)
                            ItemBasedExpenseLineDetail.UnitPrice += nl.ItemBasedExpenseLineDetail.UnitPrice;
                        else if(ItemBasedExpenseLineDetail.UnitPrice == nl.ItemBasedExpenseLineDetail.UnitPrice*-1)
                            ItemBasedExpenseLineDetail.Qty -= nl.ItemBasedExpenseLineDetail.Qty;
                        else
                            ItemBasedExpenseLineDetail.Qty += nl.ItemBasedExpenseLineDetail.Qty;   
                    }
                }*/
                if(AccountBasedExpenseLineDetail!=NULL &&  nl.AccountBasedExpenseLineDetail!=NULL &&
                    AccountBasedExpenseLineDetail.AccountRef!=NULL &&  nl.AccountBasedExpenseLineDetail.AccountRef!=NULL &&
                    AccountBasedExpenseLineDetail.AccountRef.value == nl.AccountBasedExpenseLineDetail.AccountRef.value
                )   
                {
                    exists = true;
                    Amount += nl.Amount;
                }
            } 
            return exists;   
        }
    }
    /*public class QBItemBasedExpenseLineDetail
    {
        public QBNameValue ItemRef{get;set;}
        public Decimal UnitPrice{get;set;}
        public Decimal Qty {get;set;}
        public QBNameValue CustomerRef{get;set;}
    }*/
    public class QBAccountBasedExpenseLineDetail
    {
        public QBNameValue AccountRef{get;set;}
        public String BillableStatus{get;set;}
        public QBNameValue CustomerRef{get;set;}
    }
    public class QBResponseBillPayment
    {
        public QBBillPayment billpayment{get;set;}
    }
    public class QBBillPayment
    {
        public string SyncToken{get;set;}
        public string Id{get;set;}
        public QBNameValue VendorRef{get;set;}
        public Decimal TotalAmt{get;set;}
        public string PayType{get;set;}
        public string DocNumber{get;set;}
        public string PrivateNote{get;set;}
        public string TxnDate{get;set;}
        public QBBillPaymentCheck CheckPayment{get;set;}
        Public List<QBBillPaymentLine> Line{get;set;}
    }
    public class QBBillPaymentCheck
    {
        public QBNameValue BankAccountRef{get;set;}
    }
    public class QBBillPaymentLine
    {
        public Decimal Amount{get;set;}
        public List<QBLinkedTxn> LinkedTxn{get;set;}
    }
    public class QBLinkedTxn
    {
        public string TxnId{get;set;}
        public string TxnType{get;set;}
        public string TxnLineId{get;set;}
    }
   
    Public class QBPurchase
    {
        public string SyncToken{get;set;}
        public string Id{get;set;}
        public QBNameValue AccountRef{get;set;}
        public QBEntityRef EntityRef{get;set;}
        //public QBNameValue PaymentMethodRef{get;set;}
        public string TxnDate{get;set;}
        public string PrivateNote{get;set;}
        public string PaymentType{get;set;}
        public Decimal TotalAmt{get;set;}
        Public List<QBPurchaseLine> Line{get;set;}
    }
    public class QBPurchaseLine
    {
        public string DetailType{get;set;}//AccountBasedExpenseLineDetail
        public string Id{get;set;}
        public string Description{get;set;}
        public Decimal Amount{get;set;}
        public QBAccountBasedPurchaseLineDetail AccountBasedExpenseLineDetail{get;set;}
    }
    public class QBAccountBasedPurchaseLineDetail
    {
        public QBNameValue AccountRef{get;set;}
        public String BillableStatus{get;set;}
    }
}