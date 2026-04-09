Public class trolleyInvoiceUpdate
{
    public Trolley_Invoice__c tInv{get;set;}
    public trolleyInvoiceUpdate(ApexPages.StandardController controller)
    {
        tInv = (Trolley_Invoice__c) controller.getRecord();
        tInv = [Select id, Memo__c, Cover_Fee__c, 
                                    trolley_Invoicing_Payment_Id__c, 
                                    Trolley_batch__c,Trolley_batch__r.Trolley_Id__c
                                FROM Trolley_Invoice__c  where id=:tInv.Id];
    }
    public pagereference toggleCoverFee()
    {
        tInv.Cover_Fee__c= !tInv.Cover_Fee__c;
        TrolleyAPICallBatch.updatePayment(tInv);
        update tInv;
        return new Pagereference('/'+tInv.Trolley_Batch__c);
    }
}