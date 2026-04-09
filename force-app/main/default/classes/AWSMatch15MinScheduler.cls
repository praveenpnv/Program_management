global class AWSMatch15MinScheduler implements Schedulable 
{
  global void execute(SchedulableContext SC) 
  {
      AWSDataLoaderQueue.runProcessForMatchOnly();
  }
}