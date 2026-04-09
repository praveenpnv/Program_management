Public class adminPanel
{
    public adminPanel()
    {
        dumm=new Dummy_Object__c();
        dumm.date__c = date.today();
    }
    public static boolean isTest = false;
    Public static void rerunAWS()
    {
        AWSDataLoaderQueue.runProcess(isTest);
    }
    public string Json{get;set;}
    public Dummy_Object__c dumm{get;set;}
    public void runJsonTrolleyPaypalWebhook()
    {
        RestContext.request = new RestRequest();
        RestRequest req = RestContext.request;
        req.requestBody =  Blob.valueOf(Json);
        trolleypaypalWebhook.doPost();
    }
    public void runJsonTrolley()
    {
        RestContext.request = new RestRequest();
        RestRequest req = RestContext.request;
        req.requestBody =  Blob.valueOf(Json);
        trolleyWebhook.doPost();
    }
    
}