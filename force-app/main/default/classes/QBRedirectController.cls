public class QBRedirectController 
{
    private QBOAuth qbAuth = null;    
    public QBOAuth.AuthResponse response {get;set;}    
    public String qbAuthName {get;set;}
    public Boolean isProduction  {get;set;}
    
    public QB_Auth__c queryExistingQBAuth() 
    {
       return [SELECT Name, App_Token__c, OAuth_Key__c, OAuth_Secret__c, Redirect_Uri__c, 
                     Production__c FROM QB_Auth__c 
               WHERE  Active__c = true 
               ORDER BY CreatedDate DESC 
               Limit 1];
    }
    public QBRedirectController() 
    {
        QB_Auth__c qbDbAuth = queryExistingQBAuth();
        this.qbAuthName = qbDbAuth.Name;
        this.isProduction = qbDbAuth.Production__c;
        this.qbAuth =  new QBOAuth(qbDbAuth.OAuth_Key__c, qbDbAuth.OAuth_Secret__c, null, qbDbAuth.Redirect_Uri__c);
        this.qbAuth.state = String.valueOf(Crypto.getRandomLong());
    }

    public String getLoginUrl() 
    {
        return this.qbAuth.getLoginUrl();   
    }

    public PageReference parseCode() 
    {
        String code = ApexPages.currentPage().getParameters().get('code');
        String companyId = ApexPages.currentPage().getParameters().get('realmId');
        String state = ApexPages.currentPage().getParameters().get('state');
        if (!String.isBlank(code)) 
        {
            response = this.qbAuth.authenticate(code);
            QB_Auth__c auth = queryExistingQBAuth();
            auth.Refresh_Token__c = response.refresh_token;
            auth.Access_Token__c = response.access_token;
            auth.Realm_ID__c = companyId;
            auth.Token_Time__c = System.now();
            auth.Refresh_Token_Expires_In__c = response.getRefreshTokenExpiry();
            auth.Access_Token_Expires_In__c = response.getAccessTokenExpiry();
            update auth;
        }
        
        return null;
    }
}