global class TrolleyAPICallBatch implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    public id batchIdToUse;
    public integer passNumberToUse;
    Public TrolleyAPICallBatch(id batchId, integer pNumber)
    {
        batchIdToUse = batchId;
        passNumberToUse = pNumber;
    }
    global Database.QueryLocator start( Database.BatchableContext bc )
    { 
        system.debug('----IN START OF BATCH-------'+passNumberToUse);
        Trolley_Batch__c tb = [Select ID, Trolley_Id__c,Description__c FROM Trolley_Batch__c WHERE id=:batchIdToUse];
        IF(tb.Trolley_Id__c==NULL || tb.Trolley_Id__c=='')
        {
            system.debug('----CREATINg BATCH IN TROLLEY-------');    
            TrolleyService.T_batch bch = new TrolleyService.T_batch();
            bch.description = tb.Description__c;
            TrolleyService.t_batchResponse tbr =  TrolleyService.CreateBatch(bch);
            tb.Trolley_Id__c = tbr.batch.id;  
            update tb;
        }    
        string s = 'Select ID  FROM Trolley_Invoice__c WHERE Trolley_Batch__c =:batchIdToUse AND Pass_Number__c = :passNumberToUse ';
        return Database.getQueryLocator(s);
    }
    global void execute(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
        
        system.debug('----IN EXECUTE OF BATCH-------'+lstRecord.size());
        
        for(sObject sobj:lstrecord)
        {
            system.debug(sobj);
            Trolley_Invoice__c tb = (Trolley_Invoice__c)sobj;
            tb=[Select id, Name, Memo__c, Cover_Fee__c, trolley_Invoicing_Payment_Id__c, Trolley_Id__c, Trolley_Recipient__r.referenceId__c,Trolley_Recipient__r.external_id__c,Trolley_batch__c,Trolley_batch__r.Trolley_Id__c ,
                        (Select Description__c,Amount__c, Trolley_Id__c from Trolley_Invoice_Line_Items__r)
                        FROM Trolley_Invoice__c WHERE id=:tb.id];
            system.debug(tb);            
            TrolleyService.T_Invoice tInv = new TrolleyService.T_Invoice();
            tinv.recipientId = tb.Trolley_Recipient__r.external_id__c;
            tInv.lines = new List<TrolleyService.t_invoiceline>();    
            tInv.externalId = tb.id;
            //tInv.description = tb.Memo__c;
            tInv.invoicenumber = tb.Name;
            Map<id, Trolley_Invoice_Line_Item__c> mapPayments=new Map<id, Trolley_Invoice_Line_Item__c>();
            for(Trolley_Invoice_Line_Item__c tp:tb.Trolley_Invoice_Line_Items__r)
            {
                mapPayments.put(tp.id,tp);
                TrolleyService.t_invoiceline p = new TrolleyService.t_invoiceline();
                 p.quantity='1';
                 p.unitAmount = new TrolleyService.t_amount();
                 p.unitAmount.value = string.valueOf(tp.Amount__c);
                 p.unitAmount.currency_x ='USD';
                 p.externalId=tp.id;
                 p.description = tp.description__c;
                 tInv.lines.add(p);
            }
            system.debug(tInv);
            TrolleyService.t_invoiceResponse invResp = TrolleyService.CreateInvoice(tInv);
            system.debug(invResp);
            for(TrolleyService.t_invoiceline p:invResp.invoice.lines)
            {
                if(!test.isrunningTest())
                    mapPayments.get(p.externalId).Trolley_id__c = p.id;
            }
            tb.Trolley_Id__c = invResp.invoice.id;
            
            TrolleyService.t_invoicePayment tinp=new TrolleyService.t_invoicePayment();
            tinp.batchid=tb.Trolley_batch__r.Trolley_Id__c;
            tinp.ids = new List<TrolleyService.t_id>();
            TrolleyService.t_id tstid = new TrolleyService.t_id(tb.Trolley_Id__c);
            //tstid.memo=tb.memo__c;
            tinp.ids.add(tstid);
            system.debug(tinp);
            TrolleyService.t_invoicePaymentResponse resp = TrolleyService.createInvoicePayment(tinp);
            tb.trolley_Invoicing_Payment_Id__c = resp.invoicePayment.paymentId;
            
            TrolleyService.T_paymentUpdate tpu = new TrolleyService.T_paymentUpdate();
            tpu.memo = tb.memo__c;
            tpu.CoverFees = tb.Cover_Fee__c;
            tpu.externalId = tb.id;
            TrolleyService.updatePayment(tpu,tb.Trolley_batch__r.Trolley_Id__c,tb.trolley_Invoicing_Payment_Id__c);
            update tb;
            update mapPayments.values();
            system.debug(invResp);
        }
    }
    global void finish(Database.BatchableContext bc)
    {
        system.debug('----IN FINISH-------');
    }
    public static void processQBBillPayment(id batchId)
    {
    }
    public static void getQBBillPaymentJson(string BillJSON, Map<string,QBAccountingService.QBBillPayment> mapVendorToBillPay,QBContstantsSetup ContstantsSetup)
    {
        
        JSONParser jp = JSON.createParser(BillJSON);
        QBAccountingService.QBBill bill = (QBAccountingService.QBBill)jp.readValueAs(QBAccountingService.QBBill.class);
        
        QBAccountingService.QBBillPayment billpayment = mapVendorToBillPay.get(bill.VendorRef.value);
        if(billpayment==NULL)
        {
            billpayment = new QBAccountingService.QBBillPayment();
            billpayment.VendorRef = bill.VendorRef;
            billpayment.PayType='Check';
            billpayment.TxnDate = QBOpportunitySetup.DateToString(Date.today());
            billpayment.CheckPayment = new QBAccountingService.QBBillPaymentCheck();
            billpayment.CheckPayment.BankAccountRef = new QBAccountingService.QBNameValue();
            billpayment.CheckPayment.BankAccountRef.Name =ContstantsSetup.QBCOn.CheckPayment.Name;
            billpayment.CheckPayment.BankAccountRef.value=ContstantsSetup.QBCOn.CheckPayment.value;
            billpayment.Line= new List<QBAccountingService.QBBillPaymentLine>();
            billpayment.TotalAmt=0;
            mapVendorToBillPay.put(bill.VendorRef.value,billpayment);
        }    
        billpayment.TotalAmt+=bill.gettotalAmount();        
        QBAccountingService.QBBillPaymentLine pLine = new QBAccountingService.QBBillPaymentLine();
        billpayment.Line.add(pLine);
        pLine.Amount = bill.gettotalAmount();
        pLine.LinkedTxn = new List<QBAccountingService.QBLinkedTxn>();
        QBAccountingService.QBLinkedTxn qbT = new QBAccountingService.QBLinkedTxn();
        pLine.LinkedTxn.add(qbt);
        qbt.TxnId = bill.id;
        qbt.TxnType = 'bill';
        return;
    }
    public static QBAccountingService.QBPurchase createNonTorcExpense(Trolley_Invoice__c inv, QBContstantsSetup ContstantsSetup)
    {
        string description = inv.Recipient_Name__c+' '+ inv.Trolley_Invoicing_Payment_id__c + ' '  + inv.memo__c;
        return createCoverExpense(inv.Amount__c,description,ContstantsSetup,true,inv.QB_Id__c,inv.QB_Vendor_Name__c);
    }
    public static QBAccountingService.QBPurchase createCoverExpense(Trolley_Invoice__c inv, QBContstantsSetup ContstantsSetup)
    {
        string description = inv.Trolley_Invoicing_Payment_id__c + ' ' + inv.Recipient_Name__c+' ' + inv.memo__c;
        return createCoverExpense(inv.fee__c,description,ContstantsSetup,false,null,null);
    }

    public static QBAccountingService.QBPurchase createCoverExpense(Decimal fee, string description, QBContstantsSetup ContstantsSetup, boolean isNonTorc,string qbId, string qbName)
    {
        QBAccountingService.QBPurchase purchase = new QBAccountingService.QBPurchase();
        purchase.TxnDate = QBOpportunitySetup.DateToString(Date.today());
        purchase.PaymentType = 'Cash';
        purchase.TotalAmt = fee;
        purchase.AccountRef = new QBAccountingService.QBNameValue();
        purchase.EntityRef =new QBAccountingService.QBEntityRef();
        purchase.EntityRef.type= 'Vendor';
        purchase.Line = new List<QBAccountingService.QBPurchaseLine>();
        purchase.Line.add(new QBAccountingService.QBPurchaseLine());
        purchase.privateNote = purchase.Line[0].Description = Description;
        purchase.Line[0].AccountBasedExpenseLineDetail = new QBAccountingService.QBAccountBasedPurchaseLineDetail();
        purchase.Line[0].AccountBasedExpenseLineDetail.AccountRef = new QBAccountingService.QBNameValue();
        
        if(!isNonTorc)
        {
            purchase.AccountRef.Name = ContstantsSetup.QBCOn.CheckPayment.Name;
            purchase.AccountRef.Value = ContstantsSetup.QBCOn.CheckPayment.Value; 
            purchase.EntityRef.name= ContstantsSetup.QBCOn.ExpenseEntityRef.Name;
            purchase.EntityRef.value= ContstantsSetup.QBCOn.ExpenseEntityRef.value;
            purchase.Line[0].AccountBasedExpenseLineDetail.AccountRef.name= ContstantsSetup.QBCOn.ExpenseAccountRef.Name;
            purchase.Line[0].AccountBasedExpenseLineDetail.AccountRef.value= ContstantsSetup.QBCOn.ExpenseAccountRef.value;
        } 
        else
        {
            purchase.AccountRef.Name = ContstantsSetup.QBCOn.QubikaExpensePaymentAccountRef.Name;
            purchase.AccountRef.Value = ContstantsSetup.QBCOn.QubikaExpensePaymentAccountRef.Value;
            purchase.EntityRef.name= qbName;
            purchase.EntityRef.value= qbID;
            purchase.Line[0].AccountBasedExpenseLineDetail.AccountRef.name= ContstantsSetup.QBCOn.QubikaExpenseLineItemCategoryRef.Name;
            purchase.Line[0].AccountBasedExpenseLineDetail.AccountRef.value= ContstantsSetup.QBCOn.QubikaExpenseLineItemCategoryRef.Value;
        }   
        purchase.Line[0].AccountBasedExpenseLineDetail.BillableStatus= 'NotBillable';
        purchase.Line[0].DetailType ='AccountBasedExpenseLineDetail';
        purchase.Line[0].Amount =fee;
        return purchase;
    }
    
    
    Public static void updatePayment(Trolley_Invoice__c tb) 
    {
        TrolleyService.T_paymentUpdate tpu = new TrolleyService.T_paymentUpdate();
        tpu.memo = tb.memo__c;
        tpu.CoverFees = tb.Cover_Fee__c;
        tpu.externalId = tb.id;
        TrolleyService.updatePayment(tpu,tb.Trolley_batch__r.Trolley_Id__c,tb.trolley_Invoicing_Payment_Id__c);
    }
    
    
  /*global void executeOldProcess(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
            List<TrolleyService.T_payment> lstpayment = new List<TrolleyService.T_payment>();
            Map<id, Trolley_Invoice_Line_Item__c> mapPayments=new Map<id, Trolley_Invoice_Line_Item__c>();
            Trolley_batch__c tb = (Trolley_batch__c)lstRecord[0];
            for(Trolley_Invoice_Line_Item__c tp:tb.Trolley_Payments__r)
            {
                mapPayments.put(tp.id,tp);
                TrolleyService.T_payment p = new TrolleyService.T_payment();
                 p.recipient=new TrolleyService.T_recipient();
                 p.recipient.referenceId=tp.Trolley_Recipient__r.referenceId__c;
                 p.amount = String.valueOf(tp.Amount__c);
                 p.externalId=tp.id;
                 p.category='services';
                 p.currency_x='USD';
                lstpayment.add(p);
            }
            TrolleyService.T_batch bch = new TrolleyService.T_batch();
            bch.payments = lstpayment;
            TrolleyService.t_batchResponse tbr =  TrolleyService.CreateBatch(bch);
            tb.Trolley_Id__c = tbr.batch.id;
            for(TrolleyService.T_payment p:tbr.batch.payments.payments)
            {
                mapPayments.get(p.externalId).Trolley_id__c = p.id;
            }
            update tb;
            update mapPayments.values();
            system.debug(tbr);
    }*/
}