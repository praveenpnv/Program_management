/***********************************************************
* Represents the query object JSON that is posted to Dynamo Db
***********************************************************/
public class AWS_Query 
{   
    public static string jobTypeAWS='{"Count":6,"Items":[{"updater":{"S":"lazybaer"},"isActive":{"BOOL":true},"profileStats":{"S":"[{\\"name\\":\\"images\\",\\"label\\":\\"Profile Images\\",\\"total\\":2,\\"completed\\":0,\\"order\\":1,\\"weightedScores\\":{\\"headshotKey\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"coverPhoto\\":{\\"weight\\":7.6923,\\"completed\\":true}}},{\\"name\\":\\"generalInfo\\",\\"label\\":\\"General Info\\",\\"total\\":7,\\"completed\\":0,\\"order\\":2,\\"weightedScores\\":{\\"tagline\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"bio\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"location.cityName\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"availability\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"ratePerHour.value\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"phone.number\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"hasSocialAccounts\\":{\\"weight\\":7.6923,\\"completed\\":true}}},{\\"name\\":\\"skills\\",\\"label\\":\\"Skills\\",\\"total\\":3,\\"completed\\":0,\\"order\\":3,\\"weightedScores\\":{\\"skills\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"knownLanguages\\":{\\"weight\\":7.6923,\\"completed\\":true},\\"hasApplied\\":{\\"weight\\":7.6923,\\"completed\\":true}}},{\\"name\\":\\"connectAccounts\\",\\"label\\":\\"Connect Accounts\\",\\"total\\":2,\\"completed\\":0,\\"order\\":4,\\"weightedScores\\":{\\"codealike.handle\\":{\\"weight\\":0,\\"completed\\":false},\\"hasConnectedGithub\\":{\\"weight\\":7.6923,\\"completed\\":false}}}]"},"skills":{"L":[{"M":{"name":{"S":"Communications"},"id":{"S":"Skill3"},"type":{"M":{"name":{"S":"Common Skill"},"id":{"S":"ST2"}}},"infoUrl":{"S":"https://www.com"}}}]},"id":{"S":"JOBTYPE1"},"title":{"S":"Software Architect"}}],"ScannedCount":6}';
    public static string userAWS = '{"Count":93,"Items":[{"socialLinks":{"L":[{"M":{"type":{"S":"GITHUB"},"value":{"S":"Sushmi17"}}},{"M":{"type":{"S":"FACEBOOK"},"value":{"S":"Sushmi17"}}},{"M":{"type":{"S":"LINKEDIN"},"value":{"S":"Sushmi17"}}},{"M":{"type":{"S":"INSTAGRAM"},"value":{"S":"Sushmi17"}}}]},"assessments":{"L":[{"M":{"finalScore":{"N":"0"},"plagiarism":{"S":"Not detected"},"codeScore":{"N":"0"},"source":{"S":"Coderbyte"},"assessmentCompleted":{"S":"2024-06-12T02:20:00-04:00"},"timeTaken":{"N":"1"},"createdAt":{"S":"2024-06-12T06:21:22.866Z"},"reportLink":{"S":"https://coderbyte.com/report/user564tbgwuh:java-developer-d3jhir0prx"},"multipleChoiceScore":{"N":"-1"},"testId":{"S":"java-developer-d3jhir0prx"},"id":{"S":"09e163"},"status":{"S":"Completed"},"testName":{"S":"Java Assessment V2"},"updatedAt":{"S":"2024-06-12T06:21:22.866Z"}}}]},"skills":{"L":[{"M":{"name":{"S":"Communications"},"id":{"S":"Skills2"}}}]},"updater":{"S":"com.opentorc.id.oidc_shim"},"creator":{"S":"com.opentorc.id.post_confirmation"},"userType":{"S":"FREELANCER"},"referrerCode":{"S":""},"status":{"S":"ACTIVE"},"email":{"S":"sushmi+5@opentorc.com"},"identity_username":{"S":"sushmi3"},"username":{"S":"sushmi3"},"agreedToTerms":{"BOOL":true},"id":{"S":"USER1"}}],"ScannedCount":93}';
    public static string ApplicationAWS = '{"Count":117,"Items":[{"skills":{"L":[{"M":{"name":{"S":"Communications"},"id":{"S":"Skills2"}}}]},"__typename":{"S":"Application"},"userId":{"S":"USER1"},"jobTypeId":{"S":"JOBTYPE1"},"id":{"S":"APPLICATION1"}}],"ScannedCount":117}';
    public static string jobOpportunityAWS = '{"Count":54,"Items":[{"skills":{"L":[{"M":{"name":{"S":"Communications"},"id":{"S":"Skills2"}}}]},"__typename":{"S":"JobOpportunity"},"status":{"S":"PENDINGAPPROVAL"},"jobTypeId":{"S":"JOBTYPE1"},"id":{"S":"JOBOPPORTUNITY1"},"customerId":{"S":"USER1"},"title":{"S":"Test Job "}}],"ScannedCount":54}';    
    public static string matchAWS = '{"Count":83,"Items":[{"skills":{"L":[{"M":{"name":{"S":"Communications"},"id":{"S":"Skills2"}}}]},"__typename":{"S":"Match"},"status":{"S":"REJECTEDBYCUSTOMER"},"creator":{"S":"sushmi355555"},"jobOpportunityId":{"S":"JOBOPPORTUNITY1"},"applicationId":{"S":"APPLICATION1"}}],"ScannedCount":83}';
    //public static String scanTable(String jsonBody) 
    //{
    //    return scanTable(jsonBody, false,'');
    //}
    
    public static String scanQueryTable(String jsonBody,boolean isTestRun,string awsrecord,string soq) 
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DynamoDb/');
        req.setHeader('X-Amz-Target','DynamoDB_20120810.'+soq);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(jsonBody);
        Http http = new Http();
        HTTPResponse res;
        if(isTestRun)
        {
            return awsrecord=='User'?userAWS:
                       awsrecord=='JobType'?jobTypeAWS:
                           awsrecord=='Application'?ApplicationAWS:
                               awsrecord=='JobOpportunity'?jobOpportunityAWS:matchAWS;
        }
        else
        {
            res = http.send(req);    
            system.debug(res.getStatusCode());
            System.debug(res.getBody());
        }    
        return res.getBody();
    }

    //The table we have to query
    public class ExpressionAttributeNamesCls
    {
        public string typenameFLD;
        public string updatedAtFLD;
    }
    public string IndexName;
    public ExpressionAttributeNamesCls ExpressionAttributeNames ;
    public String TableName;   
    public String ProjectionExpression;
    //public integer x_Limit=1000;
    //--------------------Pagination---------------------------//
    //In case of pagination we have to use the Last Evaluated Key
    public AWSDataLoad.AWSLastEvaluatedKeyBase ExclusiveStartKey;
    public class cls_LastEvaluatedKey 
    {
        public cls_LastEvaluatedKeyId id;    
        public cls_LastEvaluatedKey(String key) 
        {
           this.id = new cls_LastEvaluatedKeyId();
           this.id.S = key;
        }
        public cls_LastEvaluatedKey(){}
    }
    public class cls_LastEvaluatedKeyId 
    {
        public String S;    //d7137ed1-7000-4683-94b8-600fc87b20c7
    }
    //---------------------Filter-------------------------------//
    //Query filter that needs to applied
    public String FilterExpression; //updatedAt >= :val
    public string KeyConditionExpression;
    public cls_ExpressionAttributeValues ExpressionAttributeValues;
    
    public virtual class cls_ExpressionAttributeValues 
    {
        public cls_val x_val;
        public cls_ExpressionAttributeValues(){}
        public cls_ExpressionAttributeValues(String val) 
        {
            this.x_val = new cls_val();
            this.x_val.S = val;
        }
    }
    public virtual class cls_ExpressionAttributeValues2 extends cls_ExpressionAttributeValues
    {
        public cls_val x_val2;
        public cls_ExpressionAttributeValues2(){}
        public cls_ExpressionAttributeValues2(String val,String val2)
        {
            super(val);
            if(val2!=NULL)
            {
                this.x_val2 = new cls_val();
                this.x_val2.S = val2;
            }    
        }
    }
    
    public virtual class cls_ExpressionAttributeValuesWithNm extends cls_ExpressionAttributeValues
    {
        public cls_val x_typename;
        public cls_ExpressionAttributeValuesWithNm(String val,string typeNm) 
        {
            super(val);
            this.x_typename = new cls_val();
            this.x_typename.S = typeNm;
        }
    }
    public class cls_ExpressionAttributeValuesWithNm2 extends cls_ExpressionAttributeValuesWithNm
    {
        public cls_val x_val2;
        public cls_ExpressionAttributeValuesWithNm2(String val,String val2,string typeNm) 
        {
            super(val,typeNm);
            this.x_val2 = new cls_val();
            this.x_val2.S = val2;
        }
    }
    
    class cls_val {
        public String S;    //2021-09-01T00:00:00Z
    }
    
    // =================== Public Methods =========================== //
    
    public static string getTableQuery(String tableName, String evaluatedKey) {
        AWS_Query q = new AWS_Query();
        q.TableName = tableName;
        return JSON.serialize(q).replace('x_Limit','Limit');
   }
   public static boolean isInValidLastKey(AWSDataLoad.AWSLastEvaluatedKeySuperSet lastRunKey)
   {
       return
       (lastRunKey==NULL || 
        ((lastRunKey.id==null || lastRunKey.id.S==NULL || lastRunKey.id.s=='') 
            && (lastRunKey.jobOpportunityId ==null || lastRunKey.jobOpportunityId.S==NULL || lastRunKey.jobOpportunityId.s=='')
            && (lastRunKey.entity ==null || lastRunKey.entity.S==NULL || lastRunKey.entity.s=='')
            ));
   }
   public static String getTableQuery(AWS_Sync__c sync, AWSDataLoad.AWSLastEvaluatedKeySuperSet key, string singleId) 
   {
       Datetime dt1= singleId=='MATCHONLY'?dateTime.now().addMinutes(-20) :sync.Run_From__c.addHours(-9);       
       dateTime dt2 =  sync.Max_Limit__c==NULL || sync.Max_Limit__c <=0?NULL:dt1.adddays(Integer.valueOf(sync.Max_Limit__c));
       
       String dt1Str=dt1.format('yyyy-MM-dd\'T\'HH:mm:ssZ','GMT');
       string dt2Str= dt2==NULL?NULL:dt2.format('yyyy-MM-dd\'T\'HH:mm:ssZ','GMT');
       
       system.debug(sync.Name+' ' + dt1Str+' '+dt2Str);   
       
       string additionalInQry='';
       AWS_Query q = new AWS_Query();
       q.TableName = sync.Table_Name__c;
       if (!String.isEmpty(sync.fields__c)) 
       {
          q.ProjectionExpression = sync.Fields__c;  
       }
       system.debug(sync.name);
       system.debug(key);
       if(AWS_Query.isInValidLastKey(key))
       {
           q.ExclusiveStartKey = null;
       }
       else
       {
           if(sync.name=='Match')
               q.ExclusiveStartKey = new AWSDataload.AWSLastEvaluatedKeyMatch(key);
           else if(sync.name=='JobHistory' || sync.name=='MatchHistory')    
               q.ExclusiveStartKey = new AWSDataload.AWSLastEvaluatedKeyHistory(key);
           else if(sync.name=='User')    
               q.ExclusiveStartKey = new AWSDataload.AWSLastEvaluatedKey(key);
           else
               q.ExclusiveStartKey = new AWSDataload.AWSLastEvaluatedKeyIdOnly(key);
           
       }
       system.debug(q.ExclusiveStartKey);
       if(singleId==NULL || singleId=='' || singleId=='MATCHONLY')
       {
           if(Torc_Constants__c.getInstance().AWS_Always_Query__c==TRUE && sync.Use_Query__c)
           {
               string updatedAtFld = (sync.Name=='MatchHistory'||sync.Name=='JobHistory')?'createdAt':'updatedAt';
               string typenameFld = (sync.Name=='MatchHistory'||sync.Name=='JobHistory')?'entity':'__typename';
               string typeNameVal = sync.Name=='MatchHistory'?'Match':sync.Name=='JobHistory'?'JobOpportunity':sync.name;
               string indexname1 = (sync.Name=='MatchHistory'||sync.Name=='JobHistory')?'entity-createdAt-index':'__typename-updatedAt-index';
               system.debug(indexname1);
               //q.ExclusiveStartKey = key==null?null:new AWSDataload.AWSLastEvaluatedKey(key);
               q.KeyConditionExpression = '#typename = :typename AND #updatedAt > :val';
               if(dt2Str!=NULL)
                   q.KeyConditionExpression = '#typename = :typename AND #updatedAt BETWEEN :val AND :val2';
               q.IndexName= indexname1;
               q.ExpressionAttributeNames =new ExpressionAttributeNamesCls();
               q.ExpressionAttributeNames.typenameFLD= typenameFld;
               q.ExpressionAttributeNames.updatedAtFLD = updatedAtFld;
               q.ExpressionAttributeValues=dt2Str==NULL
                                           ?new cls_ExpressionAttributeValuesWithNm(dt1Str,typeNameVal)
                                           :new cls_ExpressionAttributeValuesWithNm2(dt1Str,dt2Str,typeNameVal);
               
           }
           else
           {
               string fldName ='updatedAt';
               if(q.TableName.split('-')[0]=='FieldHistory')
                   fldName = 'createdAt';

               q.FilterExpression = fldName +' >= :val';    
               if(dt2Str!=NULL)
                   q.FilterExpression = q.FilterExpression + ' AND '+fldName +' <= :val2' ;    
               q.ExpressionAttributeValues = dt2Str==NULL 
                                                   ?new AWS_Query.cls_ExpressionAttributeValues(dt1Str)
                                                   :new AWS_Query.cls_ExpressionAttributeValues2(dt1Str,dt2Str);
           }        
           
       }
       else
       {
           q.KeyConditionExpression = 'id = :val';
           q.ExpressionAttributeValues = new AWS_Query.cls_ExpressionAttributeValues(singleId);
       }
       //q.x_Limit=10;
       String result = JSON.serialize(q);
       result = result.replace('type_name_sfdc','__typename').replace('x_typename',':typename').replace('x_val2',':val2').replace('x_val',':val').replace('x_Limit','Limit').replace('typenameFLD','#typename').replace('updatedAtFLD','#updatedAt');
       return result;
   }
}