global class awsCleanUpScheduler implements Schedulable 
{
    global void execute(SchedulableContext SC) 
    {
        AWSCleanup.ProcessNow();
    }
    
}