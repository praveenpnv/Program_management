public class RD1toTorc_Match {

    public static String getGraphQLJson(TR1__Application_V2__c app,torc_user__c matcher) 
    {
        String query = getUpdateQuery();
        MatchRequest matchRequest = new MatchRequest(query, app,matcher);
        return matchRequest.getJSON();
    }
    public static String getUpdateQuery() 
    {
        List<String> lstQuery = new List<String>();
        lstQuery.add('mutation submitSFDCMatchSync($input: UpsertMatchInput!) {');
            lstQuery.add('submitSFDCMatchSync(input: $input) {');
                lstQuery.add('id');
            lstQuery.add('}');
        lstQuery.add('}');
        return String.join(lstQuery, ' ');
    }
    public class CreateMatchInput 
    {
        public String applicationId;
        public String jobOpportunityId;
        public String userId;
        public String matcher;
        public string sfdcExternalID;
        
        public String sfdcStatus;
        Public Boolean sfdcRejected;
        Public String sfdcRejectionRoot;
        Public String sfdcRejectionReason;
        
        
        /*public String status;
        public Boolean skipMatchEmailToCandidate;
        public Boolean disableNotification;*/
    }
    
    public class MatchRequest 
    {
        public String query;
        public CreateMatchInput_Variable_Wrapper variables;
        public MatchRequest(String query, TR1__Application_V2__c app,torc_user__c matcher) 
        {
            this.query = query;
            this.variables = new CreateMatchInput_Variable_Wrapper(app,matcher);
        }
        public String getJSON() 
        {
            Boolean suppresNulls = true;
            String tempJSON = JSON.serialize(this, suppresNulls);
            return tempJSON.replace('currency_x', 'currency');
        }
    }
    /*************************** Match RESPONSE *************************************/
    public class PlatformMatch_Response 
    {
        public String id;
    }

    public class PlatformMatch_ResponseData 
    {
        public PlatformMatch_Response updateMatch;
    }

    public class Platform_MatchResponse 
    {
        public PlatformMatch_ResponseData data;

        public PlatformMatch_Response getResponseValues() 
        {
            if (this.data != null && this.data.updateMatch != null)
                return this.data.updateMatch;                
            return null;
        }
    }
    public static Platform_MatchResponse parse(String json)
    {
        if(Test.isRunningTest())
            return new Platform_MatchResponse();
        return (Platform_MatchResponse) System.JSON.deserialize(json, Platform_MatchResponse.class);
    }
    public class CreateMatchInput_Variable_Wrapper 
    {
        public CreateMatchInput input;
        public CreateMatchInput_Variable_Wrapper(TR1__Application_V2__c app,torc_user__c matcher) 
        {
            this.input = new CreateMatchInput();
            this.input.jobOpportunityId = app.Torc_Id_Of_Job__c;
            this.input.applicationId = (app.Torc_Application_id__c==NULL || app.Torc_Application_id__c=='') ? 'User#' + app.Torc_Id_Of_User__c : app.Torc_Application_id__c;
            this.input.userid = app.Torc_Id_Of_User__c;
            this.input.matcher = (app.Torc_matcher__c!=NULL && app.Torc_matcher__c!='')?app.Torc_matcher__c:(matcher==NULL?app.Creator_s_Email__c:matcher.userName__c);
            
            //this.input.matcher = matcher==NULL?app.Creator_s_Email__c:matcher.userName__c;
            this.input.sfdcStatus = app.TR1__Stage__c;
            this.input.sfdcRejected = app.TR1__Reject__c;
            this.input.sfdcRejectionRoot = app.Rejection_root__c;
            this.input.sfdcRejectionReason = app.TR1__Rejection_Reason__c;
            this.input.sfdcExternalid = app.id;
                
                //this.input.disableNotification = true;
                //this.input.skipMatchEmailToCandidate = true;
            //}    
        }
    }    
}