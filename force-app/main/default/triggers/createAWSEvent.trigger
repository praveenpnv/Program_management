trigger createAWSEvent on Dynamo_Stream__e (after insert) 
{
    System.debug('+=+=+=+=+=+=+=+=+=IN OLD EVENT BASED CALL+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=');
    //AWSDataLoad.realTimeProcess(trigger.new);    
    List<Dynamo_Stream_Shadow__c> lstEvent = new List<Dynamo_Stream_Shadow__c>();
    for(Dynamo_Stream__e evt : Trigger.New) 
    {
       Dynamo_Stream_Shadow__c ae=new Dynamo_Stream_Shadow__c(JSON__c = evt.JSON__c);
       lstEvent.add(ae);
    }
    insert lstEvent;
}