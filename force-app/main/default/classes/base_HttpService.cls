public class base_HttpService
{
    private string url='https://cognito-idp.us-east-1.amazonaws.com/';//'TEST-https://cognito-idp.us-east-1.amazonaws.com/';
    private string USERNAME='sfdc_integration';
    private string PASSWORD='***************';
    private string clientId= '4vgi2esmot63dcrimclbsgehlg';
    private string operationsUrl;
    private AuthenticationResultClass auth;
    public Torc_Config__c torcConfig=NULL;
    public base_HttpService()
    {
        auth=null;
        for(Torc_Config__c rec:[SELECT Authentication_URL__c, Client_ID__c, USER_NAME__c,PASSWORD__c,
                                    Operations_URL__c, Previous_Access_Token__c, Access_Token_Expiry_At__c
                                    FROm Torc_Config__c Where Active__c=true])
        {
            url = rec.Authentication_URL__c;
            clientId = rec.Client_ID__c;
            USERNAME = rec.USER_NAME__c;
            PASSWORD = rec.PASSWORD__c;
            operationsUrl = rec.Operations_URL__c;
            if(rec.Access_Token_Expiry_At__c !=NULL && rec.Access_Token_Expiry_At__c >dateTime.now())
            {
                auth=new AuthenticationResultClass();
                auth.accessToken = rec.Previous_Access_Token__c;
            }
            torcConfig = rec;
        }
        if(auth==NULL || test.isRunningTest())
        {
            auth = getNewAccessToken();   
            if(torcConfig!=NULL)
            {
                torcConfig.Previous_Access_Token__c = auth.accessToken;
                torcConfig.Access_Token_Expiry_At__c = dateTime.now().addHours(20);    
            }
        }
        system.debug(torcConfig);
        system.debug(auth);                       
    }
    public class inputClass
    {
        public string id;
        public string status;
        public inputClass(string id1,string status1)
        {
            id=id1;
            status=status1;
        }
    }
    public class variablesClass
    {
        public inputClass input;
        public variablesClass(string id,string status)
        {
            input = new inputClass(id,status);
        }
    }
    public class operationBody
    {
        public string query;
        public variablesClass variables;
        public operationBody(string id,string status)
        {
            query = 'mutation UpdateJobOpportunity($input: UpdateJobOpportunityInput!) {updateJobOpportunity(input: $input) {id}}';
            variables = new variablesClass(id,status);
        }
    }
    
    
    public class matchinputClass
    {
        public string applicationId;
        public string jobOpportunityId;
        public List<string> reasonForRejection;
        public string status;
        public matchinputClass(string appId,string jobappid,string status1)
        {
            reasonForRejection = new List<string>();
            applicationId=appId;
            jobOpportunityId=jobappid;
            List<string> l=status1.split('=');
            status=l[0];
            for(integer i=1;i<l.size();i++)
                reasonForRejection.add(l[i]);
            //status=status1;
        }
    }
    public class matchvariablesClass
    {
        public matchinputClass input;
        public matchvariablesClass(string appId,string jobappid,string status)
        {
            input = new matchinputClass(appId,jobappid,status);
        }
    }
    public class matchoperationBody
    {
        public string query;
        public matchvariablesClass variables;
        public matchoperationBody(string appId,string jobappid,string status)
        {
            query = 'mutation UpdateMatch($input: UpdateMatchInput!) {updateMatch(input: $input) {applicationId jobOpportunityId}}';
            variables = new matchvariablesClass(appId,jobappid,status);
        }
    }
    public class AuthenticationClass
    {
        public AuthenticationResultClass AuthenticationResult;
    }
    public class AuthenticationResultClass
    {
        public string AccessToken;
        public Integer ExpiresIn;
        public string IdToken;
        public string TokenType;
    }
    public class AuthParametersClass
    {
        public string USERNAME;
        public string PASSWORD;
        public AuthParametersClass(base_HttpService HttpService)
        {
            USERNAME = HttpService.USERNAME;
            PASSWORD = HttpService.PASSWORD;
        }
    }
    public class bodyClass
    {
        public AuthParametersClass AuthParameters;
        public string AuthFlow='USER_PASSWORD_AUTH';
        public string ClientId ;
        public bodyClass(base_HttpService HttpService)
        {
            AuthParameters = new AuthParametersClass(HttpService);
            ClientId = HttpService.clientId;
        }
    }
    private AuthenticationResultClass getNewAccessToken()
    {        
        bodyClass body1 = new bodyClass(this);
        httpRequest req=new httpRequest();
        req.setHeader('Content-Type', 'application/x-amz-json-1.1');
        req.setHeader('X-Amz-Target', 'AWSCognitoIdentityProviderService.InitiateAuth');
        req.setMethod('POST');
        //Increase timeout from default 10 seconds to 1
        req.setTimeout(120000);

        //req.setRedirect('follow');
        req.setBody(Json.serialize(body1));
        System.debug('**URL****' + url);

        req.setEndPoint(url);
        system.debug(req);
        httpresponse resp = sendRequest(req);
        if(Test.isRunningTest())
        {
            AuthenticationClass a = new AuthenticationClass();
            a.AuthenticationResult=new AuthenticationResultClass();
            a.AuthenticationResult.AccessToken='aa';
            a.AuthenticationResult.ExpiresIn=120020;
            a.AuthenticationResult.IdToken='aa';
            a.AuthenticationResult.TokenType='aa';
            return a.AuthenticationResult;
        }
        JSONParser parser = JSON.createParser(resp.getBody());
        AuthenticationClass res=(AuthenticationClass)parser.readValueAs(AuthenticationClass.class); 
        System.debug(res.AuthenticationResult);
        return res.AuthenticationResult;       
    }
    private HttpResponse sendRequest(HttpRequest req) 
    {
        try 
        {
            Http http = new Http();
            System.debug('HttpRequest :' +req);
            HttpResponse res;
            if(Test.isRunningTest())
            {
                res=new HttpResponse();
                res.setStatusCode(200);
                res.setBody('test');
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
            System.debug(e);
        }
        return null;
    }
    
    public string callOperation(string body)
    {
        httpRequest req=new httpRequest();
        req.setHeader('authorization', auth.AccessToken);
        req.setMethod('POST');
        //Max timeout
        req.setTimeout(120000);
        req.setBody(body);
        req.setEndPoint(operationsUrl);
        httpresponse resp = sendRequest(req);
        system.debug(resp);
        return resp.getBody();
    }
    @future(callout=true)
    public static void OpportunityStatucChange(Set<id> oppIds,set<id>jobOppIds)
    {
        Map<Id,Torc_Job_Opportunity__c> mapJobOpty=new Map<Id,Torc_Job_Opportunity__c>([SELECT ID, External_Id__c,
                                                    (SELECT  Torc_User__c, applicationid__c,userid__c
                                                        from Torc_Matchs__r)
                                                    FROM Torc_Job_Opportunity__c WHERE Id in:jobOppIds]);
        
        List<Opportunity> lstOpp=[Select ID, Job_Opportunity__c, StageName,IsWon,(Select Talent_UserName__c from OpportunityLineItems
                                                   WHERE Talent_UserName__c!=NULL)
                                  FROM Opportunity Where id in :oppIds];
        base_HttpService HttpService = new base_HttpService();
        
        for(Opportunity opp:lstOpp)
        {
            Torc_Job_Opportunity__c jobOpty = mapJobOpty.get(opp.Job_Opportunity__c);
            if(!opp.isWon && jobOpty!=NULL)
            {
                operationBody oBody=new operationBody(jobOpty.External_Id__c,'CANCELLED');
                string respBody = HttpService.callOperation(Json.serialize(oBody));
            }
            if(opp.isWon && jobOpty!=NULL)
            {
                for(OpportunityLineItem oli:opp.OpportunityLineItems)
                {
                    for(Torc_Match__c tm:jobOpty.Torc_Matchs__r)
                    {
                        system.debug(tm);
                        system.debug(oli);
                        if(tm.Torc_User__c!=NULL 
                                && tm.Torc_User__c.toLowercase()==oli.Talent_UserName__c.toLowercase())
                        {
                            matchoperationBody oBody=new matchoperationBody(tm.applicationid__c, jobOpty.External_Id__c,'ACCEPTED');
                            string respBody = HttpService.callOperation(Json.serialize(oBody));
                        }
                    }
                }
            }
            
        }
        if(HttpService.torcConfig!=NULL) upsert HttpService.torcConfig;
    }
}