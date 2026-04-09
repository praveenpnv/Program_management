trigger TrolleyPaypalbatchTrigger on Trolley_Paypal_Batch__c (after insert, after update,before update) 
{
    QBContstantsSetup ContstantsSetup= NEW QBContstantsSetup();
    List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
    for(Trolley_Paypal_Batch__c rec:trigger.new)
    {
        if(trigger.isBefore && trigger.isUpdate)
        {
            if(rec.Status__c =='SUCCESS' && rec.SUMMARY__c =='Payouts batch completed successfully.' && rec.Process_in_QB__c ==FALSE && trigger.oldMap.get(rec.id).Process_in_QB__c==FALSE && (trigger.oldMap.get(rec.id).Status__c !='SUCCESS' || trigger.oldMap.get(rec.id).Summary__c !='Payouts batch completed successfully.' ))
            {
                rec.Process_in_QB__c = true;
            }    
        }
        else if(trigger.isAfter)
        {
            if(rec.Process_in_QB__c && (trigger.isinsert || trigger.oldMap.get(rec.id).Process_in_QB__c==FALSE) && rec.Fee__c>0)
            {
                string description = 'Paypal Charges '+rec.Name+' ('+dateTime.now().format('yyyy-MM-dd')+')';
                QBAccountingService.QBPurchase rec1 = TrolleyAPICallBatch.createCoverExpense(rec.Fee__c,description,ContstantsSetup,false,null,null);
                QB_API_Call__c qb = new  QB_API_Call__c(Name='purchase',Input__c = QBOpportunitySetup.removeAttributes(json.serialize(rec1)));
                lst.add(qb);
            }
        }
    }
    if(lst.size()>0)
    {
        QBOpportunitySetup.CallQBAPI(lst);
    }
}