public class QBHttpService {
    
    public static final String SANDBOX_BASE_URL = 'https://sandbox-quickbooks.api.intuit.com/v3/company';
    public static final String PROD_BASE_URL    = 'https://quickbooks.api.intuit.com/v3/company';
    
    public static final String SANDBOX_PAYMENT_BASE_URL = 'https://sandbox.api.intuit.com/quickbooks/v4';
    public static final String PROD_PAYMENT_BASE_URL = 'https://api.intuit.com/quickbooks/v4';
    
    public boolean isProduction;
    
    public enum API_TYPE { ACCOUNTING, PAYMENT }
    
    private String token_type;
    private String access_token;
    private String realmId;
    private API_TYPE qbApiType = API_TYPE.ACCOUNTING;
    
    public QBHttpService(boolean isProd) 
    {
        isProduction = isProd;
    }
    
    public QBHttpService(String realmId,boolean isProd) {
        this(isProd);
        this.realmId = realmId;
    }
    
    public QBHttpService(String realmID, API_TYPE apiType,boolean isProd) {
        this(realmID,isProd);
        this.qbApiType = apiType;
    }
    
    public QBHttpService(String token, String realmId,boolean isProd) {
        this(isProd);
        this.access_token = token;
        this.token_type = 'Bearer';
        this.realmId = realmId;
    }
    
    public String getBASE_URL() {
        // Accounting API
        if (this.qbApiType == API_TYPE.ACCOUNTING) {
            if (isProduction) {
                return PROD_BASE_URL;
            }
            return SANDBOX_BASE_URL;
        }
        
/*        System.debug('***APITYPE****' + this.qbApiType);
        if (this.qbApiType == API_TYPE.PAYMENT) {
            if (isProduction) {
                return PROD_PAYMENT_BASE_URL;
            }
            return SANDBOX_PAYMENT_BASE_URL;
        }*/
        return null;
    }
    
    public void setAccessToken(String tokenType, String token) {
        this.token_type = tokenType;
        this.access_token = token;
    }
    
    public void setAccessToken(String tokenType, String token, API_TYPE apiType) {
        this.token_type = tokenType;
        this.access_token = token;
        this.qbApiType = apiType;
    }
    
    public String query(String query) {
        return get(getBASE_URL() + '/'+ this.realmId + '/' + 'query', new Map<String, String>{'query' => query });
    }
    
    /*
    public String getObjectById(String objectType, String recordID) {
        System.debug('*****objectType*****' + objectType);
        System.debug('***recordID****' + recordId); 
        return get(getBASE_URL() + '/'+ this.realmId + '/' + objectType + '/' + recordID, null);
    }
    
    public String runReport(String reportName, Map<String, String> mpParams) {
        return get(getBASE_URL() + '/'+ this.realmId + '/'  + 'reports/' + reportName, mpParams);
    }
    
    public String get(String url) {
        return get(getBASE_URL() + '/' + url, null);
    }
    */
    public String get(String url, Map<String, String> params) {
        Boolean first = true;
        if (params != null && params.size() > 0) {
            for (String key : params.keySet()) {
                url += (first ? '?' : '&');
                url += EncodingUtil.urlEncode(key, 'utf-8') + '=' + EncodingUtil.urlEncode(params.get(key), 'utf-8');
                first = false;
            }
        }
        HttpRequest req = createRequest();
        req.setEndpoint(url);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept', 'application/json');
        
        req.setMethod('GET');
        HttpResponse res = sendRequest(req);
        if (isOK(res)) {
            System.debug(LoggingLevel.WARN, '***RESPONSE****' + res.getBody());
            return res.getBody();
        }
        throw buildResponseException(res);
    }
    
    public String postObject(String objectURL, String jsonStr) {
        return post('/'+ this.realmId + '/' + objectURL, jsonStr);
    }
    
    public String post(String objectURL, String jsonStr) {
        System.debug('***jsonStr****');
        System.debug(jsonStr);
        
        String url =  getBASE_URL() +  objectURL;
        System.debug('***URL****' + url);
        
        HttpRequest req = createRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Request-Id',String.valueOf(Crypto.getRandomLong()));
        
        req.setBody(jsonStr);
        HttpResponse res = sendRequest(req);
        
        LogAPI.PublishEvent((isOk(res)?'Info':'Error'),'Quickbooks',res.getBody(),req.getBody());
        
        if (isOK(res)) {
            System.debug(LoggingLevel.WARN, '***RESPONSE****' + res.getBody());
            return res.getBody();
        }
        throw buildResponseException(res);
    }
    private boolean isOK(HttpResponse res) {
        return res.getStatusCode() >= 200 && res.getStatusCode() < 300;
    }
    
    private HttpRequest createRequest() {
        HttpRequest req = new HttpRequest();
        req.setHeader('User-Agent','apex-google-api');
        if(this.access_token != null && this.token_type != null) {
            String str = this.token_type + ' ' + this.access_token;
            req.setHeader('Authorization', str);
        }
        return req;
    }
    
    private HttpResponse sendRequest(HttpRequest req) {
        Http http = new Http();
        try {
            System.debug('HttpRequest :' +req);
            HttpResponse res;
            if(test.isRunningTest())
            {
                QB_HttpMock h=new QB_HttpMock();
                res= h.respond(req);
            }    
            else    
                res = http.send(req);
            System.debug('STATUS:' + res.getStatusCode());
            System.debug('************BODY*************');
            System.debug(res.getBody());
            System.debug(res);
            return res;
        } catch( System.Exception e) {
            
            throw new QBServiceException(e);
        }
    }
    
    public QBServiceException buildResponseException(HttpResponse res) {
        String msg = 'STATUS: ' + res.getStatus() + 
            '\nSTATUS_CODE: ' + res.getStatusCode() +
            '\nBODY: ' + res.getBody();
            
        for(String header : res.getHeaderKeys()) {
            msg += header + '<->' + res.getHeader(header);
        }   
        System.debug(msg);
        return new QBServiceException(msg);
    }
    
}