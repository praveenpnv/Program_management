trigger trolleyInvoiceTrigger on Trolley_Invoice__c (after update) 
{
    Set<Id> invoiceIds=new set<id>();
    Set<Id> invoiceIdsNonTorc=new set<id>();
    for(Trolley_Invoice__c rec:trigger.new)
    {
        if(rec.Payment_Status__c=='processed' && trigger.oldMap.get(rec.id).Payment_Status__c!='processed' && rec.Torc_User__c!=NULL)
        {
            invoiceIds.add(rec.id);
        }
        if(rec.Payment_Status__c=='processed' && trigger.oldMap.get(rec.id).Payment_Status__c!='processed' && rec.Non_Torc_User__c!=NULL)
        {
            invoiceIdsNonTorc.add(rec.id);
        }
    }
    
    if(invoiceIds.size()>0)
    {
        QBContstantsSetup ContstantsSetup= NEW QBContstantsSetup();
        set<string> billids=new set<string>();
        Map<string,QBAccountingService.QBBillPayment> mapVendorToBillPay = new Map<string,QBAccountingService.QBBillPayment>();
        for(Trolley_Invoice_Line_Item__c rec:[Select ID, Quickbooks_payment_Json__c,QB_Bill_Id__c 
                                                from Trolley_Invoice_Line_Item__c 
                                                WHERE Trolley_Invoice__c in:invoiceIds])
        {
            if(!billids.contains(rec.QB_Bill_Id__c))
            {
                billids.add(rec.QB_Bill_Id__c);
                TrolleyAPICallBatch.getQBBillPaymentJson(rec.Quickbooks_payment_Json__c,mapVendorToBillPay,ContstantsSetup);
            }
        } 
        
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(QBAccountingService.QBBillPayment rec:mapVendorToBillPay.values())
        {
            QB_API_Call__c qb = new  QB_API_Call__c(Name='billpayment',Input__c = QBOpportunitySetup.removeAttributes(json.serialize(rec)));
            lst.add(qb);
        } 
        
        for(id iId:invoiceIds)
        {
            if(trigger.newMap.get(iId).Cover_Fee__c==TRUE && trigger.newMap.get(iId).Fee__c>0)
            {
                QBAccountingService.QBPurchase rec = TrolleyAPICallBatch.createCoverExpense(trigger.newMap.get(iId),ContstantsSetup);
                QB_API_Call__c qb = new  QB_API_Call__c(Name='purchase',Input__c = QBOpportunitySetup.removeAttributes(json.serialize(rec)));
                lst.add(qb);
            }
        }
        QBOpportunitySetup.CallQBAPI(lst);                                         
    }
    
    
    if(invoiceIdsNonTorc.size()>0)
    {
        QBContstantsSetup ContstantsSetup= NEW QBContstantsSetup();
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(id iId:invoiceIdsNonTorc)
        {
            QBAccountingService.QBPurchase rec = TrolleyAPICallBatch.createNonTorcExpense(trigger.newMap.get(iId),ContstantsSetup);
            QB_API_Call__c qb = new  QB_API_Call__c(Name='purchase',Input__c = QBOpportunitySetup.removeAttributes(json.serialize(rec)));
            lst.add(qb);
            
            
            if(trigger.newMap.get(iId).Cover_Fee__c==TRUE && trigger.newMap.get(iId).Fee__c>0)
            {
                rec = TrolleyAPICallBatch.createCoverExpense(trigger.newMap.get(iId),ContstantsSetup);
                qb = new  QB_API_Call__c(Name='purchase',Input__c = QBOpportunitySetup.removeAttributes(json.serialize(rec)));
                lst.add(qb);
            }
        }
        QBOpportunitySetup.CallQBAPI(lst);                                         
    }
}