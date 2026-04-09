Public class TrolleyBase
{
    //private static String API_KEY = 'AS56eoAaAYVERZXFVMRUXXIE'; 
    //private static String API_SECRET = 'E6KEXKDTMHAGTVIWCVNWZ7VOLNSNTDPLLD6QY5PL';
    public static string callAPI(string requestMethod,string reqBody,string reqpath)
    {
        QB_Auth__c qbAuth = [Select Trolley_API_key__c, Trolley_Secret__c from QB_Auth__c Where Active__c = true LIMIT 1];
        String API_KEY = qbAuth.Trolley_API_key__c; 
        string API_SECRET = qbAuth.Trolley_Secret__c;
        reqpath = '/v1/'+reqpath;
        string timestamp = String.valueOf(DateTime.now().getTime()/1000);
        string requestBody = reqBody!=NULL?reqBody:'';
        string message = timestamp + '\n'
                    + requestMethod + '\n' 
                    + reqpath + '\n'
                    + requestBody + '\n';
        String algorithmName='HmacSHA256';
        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueOf(message), Blob.valueOf(API_SECRET));
        string hash = EncodingUtil.ConvertToHex(hmacData);
        string headerString = 'prsign '+ API_KEY + ':' + hash;
        httpRequest req=new httpRequest();        
        req.setHeader('Authorization', headerString);
        req.setHeader('X-PR-Timestamp', timeStamp);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(requestMethod);
        if(requestBody!='')
            req.setBody(requestBody);
        req.setEndPoint('https://api.trolley.com'+reqpath);
        system.debug(req);
        httpresponse resp = sendRequest(req);
        if(resp!=null)
            LogAPI.PublishEvent((isOk(resp)?'Info':'Error'),'Trolley-Response',resp.getBody(),req.getBody());
        else
        {
            LogAPI.PublishEvent('Error','Trolley-Response','Response is NULL',req.getBody());
            return '';
        }
        return resp.getBody();
    }
    public static HttpResponse sendRequest(HttpRequest req) 
    {
        try 
        {
            Http http = new Http();
            System.debug('HttpRequest :' +req);
            HttpResponse res;
            if(Test.isRunningTest())
            {
                QB_HttpMock h=new QB_HttpMock();
                res= h.respond(req);
            }
            else
                res = http.send(req);
            System.debug('STATUS:' + res.getStatusCode());
            System.debug('************BODY*************');
            System.debug(res.getBody());
            return res;
        }
        catch( System.Exception e) 
        {
            System.debug('************ERROR:::*************');
            LogAPI.PublishEvent('Error','Trolley-Exception',e.getMessage());
            System.debug(e);
        }
        return null;
    }
    private static boolean isOK(HttpResponse res) 
    {
        return res.getStatusCode() >= 200 && res.getStatusCode() < 300;
    }
}