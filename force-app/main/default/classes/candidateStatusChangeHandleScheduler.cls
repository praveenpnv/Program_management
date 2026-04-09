global class candidateStatusChangeHandleScheduler implements Schedulable 
{
    global void execute(SchedulableContext SC) 
    {
        candidateStatusChangeHandleBatch.ProcessNow();
    }
    
}