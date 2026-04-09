trigger LogAPITrigger on Log_API__e (after insert) 
{
    List<Log_API_Data__c> l=new List<Log_API_Data__c>();
    for(Log_API__e r:trigger.new)
    {
        l.add(new Log_API_Data__c(Name=r.Type__c,Parent__c=r.Parent__c,Log__c=r.Log__c,Input_Log__c=r.Input_Log__c));
    }
    insert l;
}