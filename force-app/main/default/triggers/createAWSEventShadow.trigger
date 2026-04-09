trigger createAWSEventShadow on Dynamo_Stream_Shadow__c (before insert,after insert) 
{
    System.debug('+=+=+=+=+=+=+=+=+=IN NEW EVENT BASED CALL+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=');
    if(trigger.isBefore)
    {
        Integer bIde = integer.valueOf((Math.random()*9999));
        for(Dynamo_Stream_Shadow__c ds : Trigger.New) 
        {
            if(ds.Json__c!=NULL)
            {
                ds.length__c = ds.Json__c.length();
                ds.Record_Count__c = ((List<Object>)JSON.deSerializeUntyped(ds.JSON__c)).size();
            }    
            ds.Batch_Identifier__c= bIde;
        }
    }
    else    
        AWSDataLoad.realTimeProcess(trigger.new);    
}