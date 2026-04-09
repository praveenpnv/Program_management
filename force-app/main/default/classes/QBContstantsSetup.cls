Public class QBContstantsSetup
{
    Public class keyval
    {
        Public keyval(string n, string v)
        {
            name=n;
            value=v;
        }
        Public string name{get;set;}
        Public string value{get;set;}
    }
    Public class QBCOnstants
    {
        Public QBCOnstants()
        {
            paymentTerms=new List<keyval>();
            
            paymentTerms.add(new  keyval('Due on receipt','12'));
            paymentTerms.add(new  keyval('Net 10','17'));
            paymentTerms.add(new  keyval('Net 15','13'));
            paymentTerms.add(new  keyval('Net 30','14'));
            paymentTerms.add(new  keyval('Net 60','15'));
            internalBillCategory=new List<keyval>();
            internalBillCategory.add(new  keyval('Capitalized Software Development Costs','179'));
            internalBillCategory.add(new  keyval('Advertising & marketing','12'));
            internalBillCategory.add(new  keyval('Legal & accounting services','45'));
            internalBillCategory.add(new  keyval('Recruiting:Community','181'));
            
            
            
            InternalBillCustomerRef = new keyval('Torc LLC','0018B00000Nj33S');
            CheckPayment = new keyval('Cash on hand','178');
            BillItemRef = new keyval('Cost of Goods Sold','171');
            InvoiceItemRef = new keyval('Services','23');
            VendorCompanyName = 'Torc Freelancer Community';
            CRMIDDefinitionID='1';
            MASTERCRMIDDefinitionId='2';
            PONumberDefinitionId='3';
            
            ExpenseEntityRef  = new keyval('Payment Rails CA Inc','43');
            ExpenseAccountRef = new keyval('General business expenses:Bank fees & service charges','105');
            QubikaExpensePaymentAccountRef  = new keyval('Cash on hand','178');
            QubikaExpenseLineItemCategoryRef = new keyval('Bank Charges','140');
            
            rdInvoicecategory  = new keyval('Intercompany Services','43');
            rdBillCategory  = new keyval('500-005 COGS Intercompany Revenue','43');
            
        }
        Public List<keyval>paymentTerms{get;set;}
        Public List<keyval>internalBillCategory{get;set;}
        Public String CRMIDDefinitionID{get;set;}
        Public String MASTERCRMIDDefinitionId{get;set;}
        Public String PONumberDefinitionId{get;set;}
        public keyval BillItemRef{get;set;} 
        public keyval InternalBillCustomerRef{get;set;} 
        public keyval InvoiceItemRef{get;set;} 
        public string VendorCompanyName{get;set;}
        public String customerMemo{get;set;}
        public keyval CheckPayment{get;set;} 
        
        public keyval ExpenseEntityRef{get;set;} 
        public keyval ExpenseAccountRef{get;set;} 
        
        public keyval rdInvoicecategory{get;set;} 
        public keyval rdBillcategory{get;set;} 
        

        public keyval QubikaExpenseLineItemCategoryRef{get;set;}         
        public keyval QubikaExpensePaymentAccountRef{get;set;} 
        
        
        
        
    }
    public QB_Auth__c qbAuth{get;set;}
    public QBCOnstants QBCOn{get;set;}
    public QBContstantsSetup()
    {
        QBCOn = new QBCOnstants();
        for(QB_Auth__c qb:[SELECT ID,Constants__c from QB_Auth__c where Active__c=true])
        {
            qbAuth=qb;
            QBCOn = new QBCOnstants();
            if(qb.Constants__c!=NULL && qb.Constants__c!='')
            {
                JSONParser jp = JSON.createParser(qb.Constants__c);
                QBCOn=(QBCOnstants)jp.readValueAs(QBCOnstants.class);
                if(QBCon.QubikaExpenseLineItemCategoryRef==NULL)
                    QBCon.QubikaExpenseLineItemCategoryRef=new keyval('','');
                if(QBCon.QubikaExpensePaymentAccountRef==NULL)
                    QBCon.QubikaExpensePaymentAccountRef=new keyval('','');  
                if(QBCon.rdInvoicecategory     ==NULL)
                   QBCon.rdInvoicecategory  =new keyval('','');  
                if(QBCon.rdBillcategory     ==NULL)
                   QBCon.rdBillcategory  =new keyval('','');     
                
            }
        }
    }
    Public void Save()
    {
        qbAuth.Constants__c = JSON.serialize(QBCOn);
        update qbAuth;
    }
}