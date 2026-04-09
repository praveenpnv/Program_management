/********************************************************
* QB Authentication is responsible for doing authenticaton with QB
*********************************************************/
public class QB_Authentication {

    private Boolean isUpdateToken = false;
    
    public String accessToken {get; private set;}
    public String refreshToken {get; private set;}
    public String realmId {get; private set;}
    public DateTime refreshExpiryDate {get; private set;}
    public DateTime accessExpiryDate {get; private set;}
    private DateTime tokenIssuedTime {get;set;}
    
    public QB_Auth__c qbAuth ;
    
    public void initializeToken() {
       qbAuth = getQBAuth();
       
       this.realmId = qbAuth.Realm_ID__c;
       
       if (qbAuth.Access_Token__c != null && isTokenValid(qbAuth.Access_Token_Expires_In__c)) {
          System.debug('****Token Valid****');
          this.accessToken =  qbAuth.Access_Token__c;
       }
       else {
          this.isUpdateToken = true;
          
          QBOAuth.AuthResponse response = refreshToken(qbAuth);
          this.accessToken =  response.access_token;
          this.refreshToken = response.refresh_token;
          this.refreshExpiryDate = response.getRefreshTokenExpiry();
          this.accessExpiryDate = response.getAccessTokenExpiry();
          this.tokenIssuedTime = System.now();
       }
     }

     public void persistTokenInDb() {
      if (this.isUpdateToken) {
          qbAuth.Access_Token__c = this.accessToken;
          qbAuth.Refresh_Token__c = this.refreshToken;
          qbAuth.Refresh_Token_Expires_In__c = this.refreshExpiryDate;
          qbAuth.Access_Token_Expires_In__c = this.accessExpiryDate;
          qbAuth.Token_Time__c = tokenIssuedTime;
          update qbAuth;
      }   
    }
    
     private QBOAuth.AuthResponse refreshToken(QB_Auth__c qbAuth) {
         
         QBOAuth qb = new QBOAuth(qbAuth.OAuth_Key__c, qbAuth.OAuth_Secret__c, null, null);
         System.debug('******DEDDDDDD*******'+qbAuth.Refresh_Token__c+'-----');
         QBOAuth.AuthResponse response = qb.refreshToken(qbAuth.Refresh_Token__c==NULL?'':qbAuth.Refresh_Token__c);
         
         System.debug(LoggingLevel.Warn,'******Response*******');
         System.debug(LoggingLevel.Warn, response);
         System.debug(LoggingLevel.Warn,'*********************');
         
         return  response;   
    }
    
     public Boolean isTokenValid(DateTime dt) {
        if (dt == null) return false;
        
        system.debug(dt);
        system.debug(datetime.now());
        
        Decimal minute_in_millisecond = 1000 * 60;
        Decimal accessValidTime = dt.getTime();
        Decimal currentTime = System.now().getTime();
    
        System.debug('****accessValidTime***' + accessValidTime);
        //The access token 
        //Decimal minutes = (accessValidTime - currentTime - (minute_in_millisecond * 10)) / minute_in_millisecond;
        Decimal minutes = (accessValidTime - currentTime) / minute_in_millisecond;
        System.debug('************MINUTES********');
        System.debug(minutes);
        
        if (minutes >= 30) {
            return true;
        }
        return false;
    }
    
    private QB_Auth__c getQBAuth() {

        List<QB_Auth__c> lstQBAuth = [SELECT LastModifiedDate, Realm_ID__c,Token_Time__c, 
                                             Access_Token__c, App_Token__c, OAuth_Key__c, OAuth_Secret__c, 
                                             Refresh_Token__c,
                                             Access_Token_Expires_In__c,
                                             Refresh_Token_Expires_In__c 
                                       FROM QB_Auth__c WHERE
                                       Active__c = true 
                                       ORDER BY LastModifiedDate DESC
                                       Limit 1];
        if (lstQBAuth.size() == 1) {
            return lstQBAuth[0];
        }                       
        throw new QBServiceException('QB Auth Record is not found');
   }

}