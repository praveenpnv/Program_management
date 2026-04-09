Public class TrolleyAPICallQueue implements Queueable
{
    public static void runProcess(id batchid)
    {
        system.debug('START OF PAYMENT PROCESS');
        System.enqueueJob(new TrolleyAPICallQueue(batchid,0));
    }
    private id batchId= null;
    private integer passNumber = -1;
    public TrolleyAPICallQueue(id bId, Integer pNumber)
    {
        system.debug('Batch ID:'+bId+' AND Pass Number :'+pNumber);
        batchId = bId;
        passNumber=pNumber;
    }
    public void execute(QueueableContext context) 
    {
        trolleyAPICallScheduler sch=new trolleyAPICallScheduler();
        sch.batchId = batchId;
        sch.passNumber = passNumber;
        DateTime now = System.now();
        DateTime xMinuteFromNow = now.addMinutes(1);
        String cronExp = xMinuteFromNow.second() + ' ' + xMinuteFromNow.minute() + ' ' + xMinuteFromNow.hour() + ' ' + xMinuteFromNow.day() + ' ' + xMinuteFromNow.month() + ' ? ' + xMinuteFromNow.year();
        System.schedule('SCH-'+passNumber+'-' + xMinuteFromNow,cronExp,sch);
        /*for(Trolley_Invoice__c a:[Select ID from Trolley_Invoice__c  WHERE Trolley_Batch__c=:batchId and Pass_Number__c = :(passNumber+1) LIMIT 1])
        {
            system.debug('Calling Next batch '+ (passNumber+1));
            System.enqueueJob(new TrolleyAPICallQueue(batchid,passNumber+1));
        }*/   
    }
}