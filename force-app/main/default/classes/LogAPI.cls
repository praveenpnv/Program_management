Public class LogAPI
{
    public static void publishEvent(string type, string parent, string log)
    {
        publishEvent(type, parent, log,'');
    }
    public static void publishEvent(string type, string parent, string log,string inputLog)
    {
        Log_Api__e l = new Log_Api__e(Type__c=type,Parent__c=parent);
        l.log__c=log==NULL?'':log.left(2000);
        l.Input_Log__c=inputLog==NULL?'':inputLog.left(2000);
        EventBus.publish(l);
    }
}