public class QBServiceException extends Exception 
{
    public void persistInDb() 
    {
        Exception_Log__c qbLog = new Exception_Log__c(Type__c = 'QB Exception');
        qbLog.Log__c = this.getMessage();
        insert qbLog;
    }
}