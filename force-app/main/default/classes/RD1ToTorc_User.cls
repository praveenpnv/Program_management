public with sharing class RD1ToTorc_User 
{


    public static String getGraphQLJson(Contact candidate,ContentVersion resume) 
    {
        List<String> lstQuery = new List<String>();
        lstQuery.add('mutation SubmitSFDCUserSync($userEmail:AWSEmail!, $source: EXTERNALDATASOURCE!, $userFields: SubmitSFDCUserSyncInput!) {');
        lstQuery.add('submitSFDCUserSync(userEmail:$userEmail, source: $source, userFields: $userFields) {');
        lstQuery.add('id');
        lstQuery.add('location {');
        lstQuery.add('cityName');
        lstQuery.add('countryName');
        lstQuery.add('stateName');
        lstQuery.add('}');
        
        lstQuery.add('}');
        lstQuery.add('}');
        PlatformTorcUser torcUser = new PlatformTorcUser(String.join(lstQuery, ' '), candidate, resume);
        return torcUser.getJSON();
    }
        
    /*public static String getGraphQLJson(Contact RdContact, boolean isInsert) 
    {
        List<String> lstQuery = new List<String>();
        
        if(isInsert)
        {
            lstQuery.add('mutation CreateUser($source: EXTERNALDATASOURCE!, $users: [NewUserInput!]!) {');
            lstQuery.add('createUser(source: $source, users: $users) {');
            lstQuery.add('result {');
            lstQuery.add('identityUsername');
            lstQuery.add('status');
            lstQuery.add('message');
            lstQuery.add('}');
            lstQuery.add('}');
            lstQuery.add('}');
            PlatformTorcUser torcUser = new PlatformTorcUser(String.join(lstQuery, ' '), RdContact);
            return torcUser.getJSON();
        }
        else
        {
            lstQuery.add('mutation UpdateUser($input: UpdateUserInput!) {');
            lstQuery.add('updateUser(input: $input) {');
            lstQuery.add('id');
            lstQuery.add('}');
            lstQuery.add('}');
            PlatformTorcUser torcUser = new PlatformTorcUser(String.join(lstQuery, ' '), RdContact);
            return torcUser.getJSON().replace('"users"','"input"');
        }
    }*/
    
   
    

    public class PlatformTorcUser 
    {
        public PlatformTorcUser_Variables_Wrapper variables {get;set;}
        public string query {get;set;}
        
        public PlatformTorcUser(String query, Contact candidate, ContentVersion resume) 
        {
            this.query = query;
            this.variables = new PlatformTorcUser_Variables_Wrapper();
            this.variables.source = 'SFDC';
            this.variables.userEmail = candidate.Torc_Email__c;
            this.variables.userFields = new PlatformTorcUser_Variables_Input(candidate, resume);
        }
        /*public PlatformTorcUser(String query, Contact candidate) 
        {
            this.query = query;
            this.variables = new PlatformTorcUser_Variables_Wrapper();
            if(candidate.Torc_Id__c==NULL)
            {
                this.variables.source = 'SFDC';
                this.variables.talentSource = candidate.Source_Type__c;
            }    
            this.variables.users = new PlatformTorcUser_Variables_Input(candidate);
        }*/
        public String getJSON() 
        {
            Boolean suppresNulls = true;
            String tempJSON = JSON.serialize(this, suppresNulls);
            return tempJSON.replace('currency_x', 'currency').replace('x_number', 'number');
        }
    }
    Public class Phonecls
    {
        Public string x_number;
        Public boolean whatsAppAllowed;
        public Phonecls(string n, boolean wa)
        {
            x_number=n;
            whatsAppAllowed=wa;
        }
    }
    public static Platform_TorcUserResponse parse(String json)
    {
        if(Test.isRunningTest())
            return new Platform_TorcUserResponse();
        return (Platform_TorcUserResponse) System.JSON.deserialize(json, Platform_TorcUserResponse.class);
    }
    public class Platform_TorcUserResponse
    {
        public dataCls data;
        public List<errorsCls> errors;
    }
    public class errorsCls
    {
        public string message;
    }
    public class dataCls
    {
        public submitSFDCUserSynccls submitSFDCUserSync;
    }
    public class submitSFDCUserSynccls
    {
        public String id;
        public locationCls location;
    }
    public class locationCls
    {
        public String cityName;
        public String stateName;
        public String countryName;
        public locationCls(){}
        public locationCls(string country1,string state1, string city1)
        {
            cityName=city1;
            stateName=state1;
            countryName=country1;
        }
    }

    public class PlatformTorcUser_Variables_Wrapper 
    {
        public PlatformTorcUser_Variables_Input userFields {get;set;} 
        public String userEmail {get;set;}
        public String source {get;set;}      
        
        //public PlatformTorcUser_Variables_Input users {get;set;} 
        
        //public String talentSource {get;set;}      
    }
    public class socialLinksCls 
    {
        public string type{get;set;}
        public string value{get;set;}
    }
    public class metadataCls
    {
        public string BULLHORN{get;set;}
    }
    public class BULLHORNCls
    {
        public string opco{get;set;}
        //public string Created_At{get;set;}
    }
    
    public class PlatformTorcUser_Variables_Input 
    {
        public string bullhornStatus{get;set;}
        public List<socialLinksCls> socialLinks{get;set;}
        public List<string>skillsNames{get;set;}
        //public String id{get;set;}
        //public String email {get;set;}
        public string sfdcExternalID{get;set;}
        public String given_name {get;set;}
        public String family_name {get;set;}
        public String identity_username {get;set;}
        public cls_Address address {get;set;}
        public String userType {get;set;}
        //public String bio {get;set;}
        public Phonecls phone{get;set;}
        public string importSource{get;set;}
        //public string Source{get;set;}
        //public string workAuthorizations{get;set;}
        public string nextAvailableDate{get;set;}
        public string userCreationDate{get;set;}
       
        //public string jobRole{get;set;}
        public integer noticePeriod{get;set;}
        public integer overallExperience{get;set;}
        public RD1ToTorc_Job.JobRate salary{get;set;}
        public RD1ToTorc_Job.JobRate ratePerHour{get;set;}
        public string status{get;set;}
        public string visibility{get;set;}
        public boolean agreedToMarketing{get;set;}
        public String base64Resume {get;set;}
        public String resumeFileName {get;set;}
        public string metadata{get;set;}
        public String generateIdentityUserName(string email) 
        {
            String lowerCaseEmail = email.toLowerCase();
            String hashedEmail = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(lowerCaseEmail)));
            return 'rd1_' + hashedEmail;
        }
        /*public PlatformTorcUser_Variables_Input(Contact candidate) 
        {
            torcRD1integrationMapping.filldataToTorc(candidate,this);
        }*/
        public PlatformTorcUser_Variables_Input(Contact candidate, ContentVersion resume) 
        {
            torcRD1integrationMapping.filldataToTorc(candidate,this,resume);
        } 
    }

    public class cls_Address 
    {
        public String city {get;set;}
        public String state {get;set;}
        public String country {get;set;}
    }
}