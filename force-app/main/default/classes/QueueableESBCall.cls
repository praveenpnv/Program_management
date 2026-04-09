public class QueueableESBCall implements System.Queueable, Database.AllowsCallouts {
         
    private final String url;
    private final String method;
    private final String body;
     
    public QueueableESBCall(String url, String method, String body) {
        this.url = url;
        this.method = method;
        this.body = body;
    }
     
    public void execute(System.QueueableContext ctx) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method); 
        req.setBody(body);

        if (!Test.isRunningTest()) {
            req.setHeader('Authorization', 'Basic ' + getKey(url));
        } else {
            req.setHeader('Authorization', 'Basic test');
        }

        system.debug('Body: ' + body);
        system.debug('URL: ' + url);

        Http http = new Http();
        
        try {
            HttpResponse res = http.send(req);
            System.debug(res);
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
    }

    private String getKey(String url) {
        if (url.contains(Api_Url__c.getValues('ESB_FR').Url__c)){
            System.debug('Key ' +Api_Url__c.getValues('ESB_FR').Key__c);
            return Api_Url__c.getValues('ESB_FR').Key__c;
            
        } else {
            System.debug('Key ' +Api_Url__c.getValues('ESB_BE').Key__c);

            return Api_Url__c.getValues('ESB_BE').Key__c;
        }
        
    }
}


/*public class QueueableESBCall implements System.Queueable, Database.AllowsCallouts {
         
    private final String url;
    private final String method;
    private final String body;
     
    public QueueableESBCall(String url, String method, String body) {
        this.url = url;
        this.method = method;
        this.body = body;
    }
     
    public void execute(System.QueueableContext ctx) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setBody(body);
        if(!Test.isRunningTest()){
            req.setHeader('Authorization', 'Basic '+ this.getKey(url));
        }else{
            req.setHeader('Authorization', 'Basic test');
        }
        //req.setHeader('Authorization', 'Basic c2FsZXNmb3JjZTpNV2cyeVh5S3Y2Ml');

        system.debug('body: ' + body);
        system.debug(url);
        Http http = new Http();
        
        if (!Test.isRunningTest()) {
            HttpResponse res = http.send(req);
            System.debug(res);
        } else {
            System.debug(body);
        }
    }

    private string getKey(string url){
        /*if(url.contains(Api_Url__c.getValues('ESB_FR').Url__c)){
            return Api_Url__c.getValues('ESB_FR').Key__c;
        }
        else{
            return Api_Url__c.getValues('ESB_BE').Key__c;
        //}
    }
}
*/