global class trolleyAPICallScheduler implements Schedulable 
{
    public id batchId= null;
    public integer passNumber = -1;   
    global void execute(SchedulableContext SC) 
    {
        system.debug('SCHEDULE EXECUTION '+passNumber);
        TrolleyAPICallBatch myBatchObject = new TrolleyAPICallBatch(batchId,passNumber); 
        Database.executeBatch(myBatchObject,1);
        for(Trolley_Invoice__c a:[Select ID from Trolley_Invoice__c  WHERE Trolley_Batch__c=:batchId and Pass_Number__c = :(passNumber+1) LIMIT 1])
        {
            system.debug('Calling Next batch '+ (passNumber+1));
            System.enqueueJob(new TrolleyAPICallQueue(batchid,passNumber+1));
        }
    }
    
}