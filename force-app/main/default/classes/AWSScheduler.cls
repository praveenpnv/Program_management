global class AWSScheduler implements Schedulable 
{
  global void execute(SchedulableContext SC) 
  {
      AWSDataLoaderQueue.runProcess(AWSDataLoaderQueue.isTestRunStatic);
  }
}