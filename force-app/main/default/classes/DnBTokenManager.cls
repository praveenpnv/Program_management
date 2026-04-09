public class DnBTokenManager {
    
    public class TokenResponse {
        public String access_token;
        public Integer expires_in;
        public String token_type;
    }

    private static final String PARTITION_NAME = 'local.DnBTokenCache';
    private static final String CACHE_KEY = 'DNBAccessToken'; //DNB_ACCESS_TOKEN';
    
	public static String getAccessToken() {
      
    Cache.OrgPartition partition = Cache.Org.getPartition(PARTITION_NAME);
    String cachedToken = (String) partition.get(CACHE_KEY);

    if (cachedToken != null) {
        System.debug('✅ Reusing cached token from Platform Cache');
        return cachedToken;
    }
    System.debug('⏳ No token in cache. Getting new token from DnB');

   // String password = 'gju';
  //  String username = '90890';
      
  //  String credentials = EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:DnB_Credential/v3/token');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    //req.setHeader('Authorization', 'Basic ' + credentials);
    req.setBody('grant_type=client_credentials');

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
        TokenResponse token = (TokenResponse) JSON.deserialize(res.getBody(), TokenResponse.class);

        Integer ttl = 84600; // 23.5 hours
        partition.put(CACHE_KEY, token.access_token, ttl);

        return token.access_token;
    } else {
        throw new CalloutException('❌ Failed to get DnB token: ' + res.getStatusCode() + ' - ' + res.getBody());
    }
}

  
}