Public class AWSDataLoad
{
    public static boolean onlyLoadmatchInShadow=false;
    Public class AWSHistory
    {
        Public AWSString attribute;
        Public AWSString createdAt;
        Public AWSString creator;
        Public AWSString id;
        Public AWSString table;
        Public AWSString newValue;
        Public AWSString eventType;
        Public AWSString oldValue;
        Public AWSString primaryKey;
        public string getAWSprimaryKey(string tbl)
        {
            if(primaryKey==NULL) return '';
            JSONParser parser = JSON.createParser(primaryKey.S);
            AWSDataLoad.AWSprimaryKey a= (AWSDataLoad.AWSprimaryKey)parser.readValueAs(AWSDataLoad.AWSprimaryKey.class);
            return a.getKey(tbl);
        }
    }
    public class AWSprimaryKey
    {
        Public string jobOpportunityId;
        Public string applicationId;
        Public string id;
        public string getkey(string tbl)
        {
            if(tbl=='JobOpportunity')
                return id==NULL?NULL:id;
            else
                return (applicationId==NULL?'':applicationId)+'-'+(jobOpportunityId==NULL?'':jobOpportunityId);    
        }
    }
    Public class AWSHistoryCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSHistory> Items;
        public List<Torc_History__c> upsertInSFDC(AWS_Sync__c awsSyncrec)
        {
            List<Torc_History__c> l=new List<Torc_History__c>();
            for(AWSHistory awsrec:Items)
            {
                Torc_History__c rec=new Torc_History__c();               
                rec.attribute__c = awsrec.attribute==NULL?Null:awsrec.attribute.S;
                rec.eventType__c = awsrec.eventType==NULL?Null:awsrec.eventType.S;
                rec.creator__c = awsrec.creator==NULL?Null:awsrec.creator.S;
                rec.table__c = awsrec.table==NULL?Null:awsrec.table.S;
                if(rec.table__c!=NULL)
                    rec.table__c=rec.table__c.split('-')[0];    
                rec.newValue__c = awsrec.newValue==NULL?Null:awsrec.newValue.S;
                rec.oldValue__c = awsrec.oldValue==NULL?Null:awsrec.oldValue.S;
                rec.External_ID__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.primaryKey__c = awsrec.getAWSprimaryKey(rec.table__c);
                rec.Created_by_Torc_user__r = rec.creator__c==NULL || rec.creator__c.startsWith('google_')|| rec.creator__c.startsWith('github_') ? 
                                        new Torc_User__c(identity_username__c = rec.creator__c):
                                        new Torc_User__c(userName__c = rec.creator__c);
                                        
                if(rec.table__c=='Match')
                    rec.Torc_Match__r = new Torc_Match__c(External_Id__c = rec.primaryKey__c);
                if(rec.table__c=='JobOpportunity')
                    rec.Torc_Job_Opportunity__r = new Torc_Job_Opportunity__c(External_Id__c = rec.primaryKey__c);
                rec.Name=   rec.attribute__c+' '+rec.eventType__c+' '+rec.newValue__c;
                rec.Name=rec.Name.left(80);
                l.add(rec); 
            }
            Schema.SObjectField f = Torc_History__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(l,f,false);
            AWSDataLoad.recordOutput(dr);
            return l;
        }
    }
    
    
    Public class AWSReferralStatus
    {
        Public AWSString createdAt;
        Public AWSString updatedAt;
        Public AWSString identity_username;
        Public AWSString creator;
        Public AWSString updater;
        Public AWSReferralM direct;
        Public AWSReferralM email;
        Public AWSReferralM facebook;
        Public AWSReferralM linkedIn;
        Public AWSReferralM profile;
        Public AWSReferralM reddit;
        Public AWSReferralM twitter;
        Public AWSReferralM whatsApp; 
        public Double getReferrelValue(boolean act, AWSReferralM a)
        {
            return a==NULL?0:a.getValue(act);
        }       
    }
    Public class AWSReferralM
    {
        Public AWSReferral M;
        public Double getValue(boolean act)
        {
            return m==NULL?0:
            (act?
                ((M.actualCount==NULL || M.actualCount.N==NULL)?0:M.actualCount.N):
                ((M.copiedCount==NULL || M.copiedCount.N==NULL)?0:M.copiedCount.N)
            );
        }
    }
    Public class AWSReferral
    {
        Public AWSInteger actualCount;
        Public AWSInteger copiedCount;
    }
    Public class AWSReferralStatusCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSReferralStatus> Items;
        public List<Torc_Referral_Status__c> upsertInSFDC(AWS_Sync__c awsSyncrec)
        {
            List<Torc_Referral_Status__c> l=new List<Torc_Referral_Status__c>();
            for(AWSReferralStatus awsrec:Items)
            {
                Torc_Referral_Status__c rec=new Torc_Referral_Status__c(); 
                rec.Identity_Username__c = awsrec.identity_username==NULL?Null:awsrec.identity_username.S;
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);              
                rec.updatedAt__c = awsrec.updatedAt==NULL?Null: stringtoDateTime(awsrec.updatedAt.S);              
                rec.Torc_user__r = new Torc_User__c(identity_username__c = rec.Identity_Username__c);
                rec.Name=   rec.Identity_Username__c;
                rec.Name=rec.Name!=NULL?rec.Name.left(80):'';
                
                rec.direct_actualCount__c = awsrec.getReferrelValue(true, awsrec.direct);              
                rec.direct_copiedCount__c = awsrec.getReferrelValue(false, awsrec.direct);
                
                rec.email_actualCount__c = awsrec.getReferrelValue(true, awsrec.email);              
                rec.email_copiedCount__c = awsrec.getReferrelValue(false, awsrec.email);
                
                rec.facebook_actualCount__c = awsrec.getReferrelValue(true, awsrec.facebook);              
                rec.facebook_copiedCount__c = awsrec.getReferrelValue(false, awsrec.facebook);
                
                rec.linkedin_actualCount__c = awsrec.getReferrelValue(true, awsrec.linkedin);              
                rec.linkedin_copiedCount__c = awsrec.getReferrelValue(false, awsrec.linkedin);
                
                rec.profile_actualCount__c = awsrec.getReferrelValue(true, awsrec.profile);              
                rec.profile_copiedCount__c = awsrec.getReferrelValue(false, awsrec.profile);
                
                rec.reddit_actualCount__c = awsrec.getReferrelValue(true, awsrec.reddit);              
                rec.reddit_copiedCount__c = awsrec.getReferrelValue(false, awsrec.reddit);
                
                rec.twitter_actualCount__c = awsrec.getReferrelValue(true, awsrec.twitter);              
                rec.twitter_copiedCount__c = awsrec.getReferrelValue(false, awsrec.twitter);
                
                rec.whatsApp_actualCount__c = awsrec.getReferrelValue(true, awsrec.whatsApp);              
                rec.whatsApp_copiedCount__c = awsrec.getReferrelValue(false, awsrec.whatsApp);
                
                l.add(rec); 
            }
            Schema.SObjectField f = Torc_Referral_Status__c.Fields.Identity_Username__c;
            List<database.UpsertResult> dr = database.Upsert(l,f,false);
            AWSDataLoad.recordOutput(dr);
            return l;
        }
    }






    Public Class AWSString
    {
        Public String S;
    }
    Public Class AWSBool
    {
        Public Boolean BOOL;
    }
    Public Class AWSInteger
    {
        Public Double N;
    }
    Public class AWSLocationM
    {
        Public AWSLocation M;
    }
    Public class AWSLocation
    {
        Public AWSString cityName;
        Public AWSString countryCode;
        Public AWSInteger countryId;
        Public AWSString countryName;
        Public AWSString latitude;
        Public AWSInteger locationId;
        Public AWSString longitude;
        Public AWSString stateCode;
        Public AWSInteger stateId;
        Public AWSString stateName;
        Public AWSString wikiDataId;
    }
    Public class AWSratePerHourM
    {
        Public AWSratePerHour M;
    }
    Public class AWSratePerHour
    {
        Public AWSInteger value;
        Public AWSString x_currency;
    }
    Public virtual class AWSLastEvaluatedKeyBase
    {
        protected AWSLastEvaluatedKeyBase(){}
        public AWSLastEvaluatedKeyBase(AWSLastEvaluatedKeySuperSet par)
        {
            
        }
    }
    Public virtual class AWSLastEvaluatedKeyIdOnly extends AWSLastEvaluatedKeyBase
    {
        Public AWSString id;
        protected AWSLastEvaluatedKeyIdOnly(){}
        public AWSLastEvaluatedKeyIdOnly(AWSLastEvaluatedKeySuperSet par)
        {
            if(par==null)return;
            id=par.id;
        }
    }
    Public virtual class AWSLastEvaluatedKey extends AWSLastEvaluatedKeyIdOnly
    {
        Public AWSString updatedAt;
        Public AWSString type_name_sfdc;
        public AWSLastEvaluatedKey(){}
        public AWSLastEvaluatedKey(AWSLastEvaluatedKeySuperSet par)
        {
            if(par==null)return;
            id=par.id;
            updatedAt=par.updatedAt;
            type_name_sfdc=par.type_name_sfdc;
        }
    }
    Public virtual class AWSLastEvaluatedKeyMatch extends AWSLastEvaluatedKeyBase
    {
        Public AWSString updatedAt;
        Public AWSString type_name_sfdc;
        Public AWSString jobOpportunityId;
        Public AWSString applicationId;
        protected AWSLastEvaluatedKeyMatch(){}
        public AWSLastEvaluatedKeyMatch(AWSLastEvaluatedKeySuperSet par)
        {
            if(par==null)return;
            //id=par.id;
            jobOpportunityId=par.jobOpportunityId;
            applicationId=par.applicationId;
            updatedAt =par.updatedAt;
            type_name_sfdc = par.type_name_sfdc;
        }
    }
    Public virtual class AWSLastEvaluatedKeyHistory extends AWSLastEvaluatedKeyIdOnly
    {
        Public AWSString entity;
        Public AWSString createdAt;
        protected AWSLastEvaluatedKeyHistory(){}
        public AWSLastEvaluatedKeyHistory(AWSLastEvaluatedKeySuperSet par)
        {
            if(par==null)return;
            id=par.id;
            entity=par.entity;
            createdAt=par.createdAt;
        }
    }
    
    Public class AWSLastEvaluatedKeySuperSet extends AWSLastEvaluatedKey
    {
        Public AWSString jobOpportunityId;
        Public AWSString applicationId;
        Public AWSString entity;
        Public AWSString createdAt;
        
    }
    
    Public class AWSUser
    {
        public AWSInteger noticePeriod;
        
        public AWSresumeWorkHistoryL resumeWorkHistory;
        public AWSresumeWorkHistoryL careers;
        public AWSString sfdcExternalID;
        public AWSratePerHourM ratePerHour;
        public AWSratePerHourM salary;
        Public AWSBool agreedToTerms;
        Public AWSBool agreedToMarketing;
        Public AWSBool deleteit;
        Public AWSString company;
        Public AWSString lastActivityDate;
        Public AWSString referrerSource;
        Public AWSinitialCognitoGroupsL cognitoGroups;
        Public AWSInteger profileCompletion;
        Public AWSInteger overallExperience;
        Public AWSString availability;
        Public AWSString createdAt;
        Public AWSString creator;
        Public AWSString email;
        Public AWSString family_name;
        Public AWSString githubAccessToken;
        Public AWSString githubRefreshToken;
        Public AWSString given_name;
        Public AWSString id;
        Public AWSString nylasAccountId;
        Public AWSString identity_username;
        Public AWSString referralCode;
        Public AWSString referrerCode;
        Public AWSString status;
        Public AWSString updatedAt;
        Public AWSString nextAvailableDate;
        Public AWSString externalUserId;
        Public AWSString updater;
        Public AWSString username;
        Public AWSString resumeLocation;
        Public AWSString profileStats;
        Public AWSString userType;
        Public AWSString visibility;
        Public AWSLocationM location;
        Public AWSSkillsL skills;
        Public AWSSkillsL TKskills;
        Public AWSsocialLinksL socialLinks;
        Public AWSassessmentsL assessments;
        Public AWSMetaDataM metadata;
        Public AWSPhoneM phone;
        public string eventId;
    }
    Public class AWSinitialCognitoGroupsL
    {
        Public List<AWSString>L;
    }
    
    Public class AWSPhoneM
    {
        Public AWSPhone M;
    }
    Public class AWSPhone
    {
        Public AWSString x_number;
        Public AWSBOOL whatsAppAllowed;
    }
    
    Public class AWSMetaDataM
    {
        Public AWSMetaData M;
    }
    Public class AWSMetaData
    {
        Public AWSString Do_Not_Disturb;
        Public AWSString Job_Enabled;
        Public AWSString Payment_Enabled;
    }
    Public class AWSsocialLinksL
    {
        Public List<AWSsocialLinkM>L;
    }
    Public class AWSsocialLinkM
    {
        Public AWSsocialLink M;
    }
    Public class AWSsocialLink
    {
        Public AWSString value;
        Public AWSString type;
    }
    
    Public class AWSassessmentsL
    {
        Public List<AWSassessmentM>L;
    }
    Public class AWSassessmentM
    {
        Public AWSassessment M;
    }
    Public class AWSassessment
    {
        Public AWSString id;
        Public AWSInteger codeScore;
        Public AWSString assessmentCompleted;
        Public AWSString source;
        Public AWSString createdAt;
        Public AWSString updatedAt;
        Public AWSInteger finalScore;
        Public AWSInteger multipleChoiceScore;
        Public AWSString plagiarism;
        Public AWSString status;
        Public AWSString testId;
        Public AWSString testName;
        Public AWSInteger timeTaken;
        Public AWSInteger experience;
        Public AWSString reportLink;
    }
    public class AWSProfileStatsSuper
    {
        public list<AWSProfileStats> l;
    }
    public class AWSProfileStats
    {
        public string name;
        public string label;
        public integer total;
        public AWSweightedScores weightedScores ;
        
    }
    public class AWSweightedScores
    {
        public AWSweightedScore headshotKey;
        public AWSweightedScore coverPhoto;
        public AWSweightedScore bio;
        
    }
    public class AWSweightedScore
    {
        public decimal weight;
        public boolean completed;
    }
    Public class AWSUserCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSUser> Items;
        public List<Torc_User__c> upsertInSFDC(AWS_Sync__c awsSyncrec,List<AWS_Event__c> lstawsEvent)
        {
            List<AWS_Event__c> lstAwsEventLocal = new List<AWS_Event__c>();
            Map<string,Torc_User__c> uniqueSet=new Map<string,Torc_User__c>();
            Map<string,Torc_Assessment__c> assessmentl=new Map<string,Torc_Assessment__c>();
            Map<String,Torc_Skill__c> skilMap=new Map<String,Torc_Skill__c>();
            for(AWSUser awsrec:Items)
            {
                if(awsrec.metadata!=NULL && awsrec.metadata.M!=NULL)
                {
                }
                Torc_User__c rec=new Torc_User__c();
                rec.Do_Not_Disturb__c = (awsrec.metaData!=NULL && awsrec.Metadata.M!=NULL && awsrec.metadata.m.Do_Not_Disturb!=NULL && awsrec.metadata.m.Do_Not_Disturb.S=='true');
                rec.Job_Enabled__c = (awsrec.metaData!=NULL && awsrec.Metadata.M!=NULL && awsrec.metadata.m.Job_Enabled!=NULL && awsrec.metadata.m.Job_Enabled.S=='true');
                rec.Payment_Enabled__c = (awsrec.metaData!=NULL && awsrec.Metadata.M!=NULL && awsrec.metadata.m.Payment_Enabled!=NULL && awsrec.metadata.m.Payment_Enabled.S=='true');
                
                rec.agreedToTerms__c = awsrec.agreedToTerms==NULL?false:awsrec.agreedToTerms.BOOL;
                rec.agreedToMarketing__c = awsrec.agreedToMarketing==NULL?false:awsrec.agreedToMarketing.BOOL;
                
                rec.updater__c = awsrec.updater==NULL?Null:awsrec.updater.S;
                rec.creator__c = awsrec.creator==NULL?Null:awsrec.creator.S;
                rec.externalUserId__c  = awsrec.externalUserId==NULL?Null:awsrec.externalUserId.S;  
                if(awsrec.sfdcExternalID!=NULL && awsrec.sfdcExternalID.S!=null && awsrec.sfdcExternalID.S!='')
                    rec.sfdcExternalID__c  = awsrec.sfdcExternalID==NULL?Null:awsrec.sfdcExternalID.S;  
                             
                rec.profileCompletion__c = awsrec.profileCompletion==NULL?NULL:awsrec.profileCompletion.N;
                rec.overallExperience__c = awsrec.overallExperience==NULL?NULL:awsrec.overallExperience.N;
                
                //rec.job_History_JSON__c = awsrec.resumeWorkHistory==null?null:JSON.serialize(awsrec.resumeWorkHistory);
                //rec.job_History_JSON__c = awsrec.careers==null?null:JSON.serialize(awsrec.careers);
                rec.phone__c = (awsrec.phone==NULL || awsrec.phone.M==NULL || awsrec.phone.M.x_number==NULL)?NULL:awsrec.phone.M.x_number.S;
                rec.whatsAppAllowed__c = (awsrec.phone==NULL || awsrec.phone.M==NULL || awsrec.phone.M.whatsAppAllowed==NULL)?False:(awsrec.phone.M.whatsAppAllowed.BOOL==NULL?False:awsrec.phone.M.whatsAppAllowed.BOOL);
                rec.availability__c = awsrec.availability==NULL?Null:awsrec.availability.S;
                rec.company__c = awsrec.company==NULL?Null:awsrec.company.S;
                
                rec.resumeLocation__c = awsrec.resumeLocation==NULL?Null:awsrec.resumeLocation.S;
                
               
                rec.nextAvailableDate__c = awsrec.nextAvailableDate==NULL?Null: stringtoDate(awsrec.nextAvailableDate.S);
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.lastActivityDate__c = awsrec.lastActivityDate==NULL?Null: stringtoDateTime(awsrec.lastActivityDate.S);
                rec.nylasAccountId__c = awsrec.nylasAccountId==NULL?Null: awsrec.nylasAccountId.S;
                
               
                rec.email__c = awsrec.email==NULL?Null:awsrec.email.S;
                rec.family_name__c = awsrec.family_name==NULL?Null:awsrec.family_name.S;
                if(rec.family_name__c!=NULL && rec.family_name__c.length()>80)
                    rec.family_name__c = rec.family_name__c.left(80);
                //rec.githubAccessToken__c = awsrec.githubAccessToken==NULL?Null:awsrec.githubAccessToken.S;
                //rec.githubRefreshToken__c = awsrec.githubRefreshToken==NULL?Null:awsrec.githubRefreshToken.S;
                rec.given_name__c = awsrec.given_name==NULL?Null:awsrec.given_name.S;
                if(rec.given_name__c!=NULL && rec.given_name__c.length()>80)
                    rec.given_name__c = rec.given_name__c.left(80);
                rec.External_ID__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.identity_username__c = awsrec.identity_username==NULL?Null:awsrec.identity_username.S;
                rec.referralCode__c = awsrec.referralCode==NULL?Null:awsrec.referralCode.S.left(50);
                rec.referrerCode__c = awsrec.referrerCode==NULL?Null:awsrec.referrerCode.S.left(50);
                rec.status__c = awsrec.status==NULL?Null:awsrec.status.S;
                rec.updatedAt__c = awsrec.updatedAt==NULL?Null:stringtoDateTime(awsrec.updatedAt.S);
                rec.userName__c = rec.Name = awsrec.userName==NULL?Null:awsrec.userName.S;
                if(rec.userName__c==NULL || rec.userName__c=='')
                    rec.Name=rec.identity_username__c;
                rec.userType__c = awsrec.userType==NULL?Null:awsrec.userType.S;
                rec.visibility__c = awsrec.visibility==NULL?Null:awsrec.visibility.S;
                if(awsrec.TKSkills!=NULL)
                    awsrec.Skills = awsrec.TKSkills;
                rec.skills__c = awsrec.skills==NULL?Null:awsrec.skills.getInString(skilMap);
                rec.skills_Id__c = awsrec.skills==NULL?Null:awsrec.skills.getInIDString();
                rec.Skill_Experience__c = awsrec.skills==NULL?Null:awsrec.skills.getInExperienceString();
                rec.NoticePeriod__c = awsrec.noticePeriod==NULL?Null:awsrec.noticePeriod.N;
               
                string profileStats = awsrec.profileStats==NULL?null:awsrec.profileStats.S;
                rec.headshotKey__c = rec.coverPhoto__c = rec.bio__c=false;
                if(profileStats!=NULL && profileStats.trim()!='')
                {
                    profileStats='{"l":'+profileStats+'}';
                    JSONParser jp = JSON.createParser(profileStats);
                    AWSDataLoad.AWSProfileStatsSuper lstStats=(AWSDataLoad.AWSProfileStatsSuper)jp.readValueAs(AWSDataLoad.AWSProfileStatsSuper.class);                    
                    for(AWSProfileStats ps:lstStats.l)
                    {
                        if(ps.weightedScores!=NULL && ps.weightedScores.headshotKey!=NULL)
                             rec.headshotKey__c = ps.weightedScores.headshotKey.Completed;
                        if(ps.weightedScores!=NULL && ps.weightedScores.coverPhoto!=NULL)
                             rec.coverPhoto__c = ps.weightedScores.coverPhoto.Completed; 
                        if(ps.weightedScores!=NULL && ps.weightedScores.bio!=NULL)
                             rec.bio__c = ps.weightedScores.bio.Completed;          
                    }
                }
                
                if(awsrec.deleteIt!=NULL && awsrec.deleteIt.BOOL!=NULL && awsrec.deleteIt.BOOL)
                    rec.Delete_From_Platform__c = true;
                rec.ratePerHour__c = (awsrec.ratePerHour!=NULL && awsrec.ratePerHour.M!=NULL && awsrec.ratePerHour.M.value!=NULL)?awsrec.ratePerHour.M.value.N:Null;
                rec.salary__c = (awsrec.salary!=NULL && awsrec.salary.M!=NULL && awsrec.salary.M.value!=NULL)?awsrec.salary.M.value.N:Null;
                if(awsrec.location!=NULL && awsrec.location.M!=NULL)
                {
                    rec.cityName__c = awsrec.location.M.cityName==NULL?NULL:awsrec.location.M.cityName.S;
                    rec.countryCode__c = awsrec.location.M.countryCode==NULL?NULL: awsrec.location.M.countryCode.S;
                    rec.countryName__c = awsrec.location.M.countryName==NULL?NULL: awsrec.location.M.countryName.S;
                    rec.stateCode__c = awsrec.location.M.stateCode==NULL?NULL: awsrec.location.M.stateCode.S;
                    rec.stateName__c = awsrec.location.M.stateName==NULL?NULL: awsrec.location.M.stateName.S;
                    rec.countryCode__c = awsrec.location.M.countryCode==NULL?NULL: awsrec.location.M.countryCode.S;
                }
                if(awsrec.socialLinks!=NULL && awsrec.socialLinks.L!=NULL)
                {
                    for(AWSsocialLinkM SLM:awsrec.socialLinks.L)
                    {
                        if(SLM!=NULL && SLM.M!=NULL  && SLM.M.type!=NULL && SLM.M.type.S!=NULL)
                        {
                            if(SLM.M.type.S=='TWITTER')
                                rec.Twitter__c =(SLM.M.value!=NULL)?SLM.M.value.S:null;
                            Else if(SLM.M.type.S=='FACEBOOK')
                                rec.Facebook__c =(SLM.M.value!=NULL)?SLM.M.value.S:null;
                            Else if(SLM.M.type.S=='LINKEDIN')
                                rec.LinkedIn__c =(SLM.M.value!=NULL)?SLM.M.value.S:null;
                            Else if(SLM.M.type.S=='INSTAGRAM')
                                rec.Instagram__c =(SLM.M.value!=NULL)?SLM.M.value.S:null;            
                            Else if(SLM.M.type.S=='GITHUB')
                                rec.Github__c =(SLM.M.value!=NULL)?SLM.M.value.S:null;                
                        }
                    }
                }
                rec.referrerSource__c = awsrec.referrerSource==NULL?Null:awsrec.referrerSource.S.left(80);
                string cGList ='';
                if(awsrec.cognitoGroups!=NULL && awsrec.cognitoGroups.L!=NULL)
                {
                    for(AWSString a:awsrec.cognitoGroups.L)
                    {
                        if(a.S!=NULL)
                        {
                            cGList=cGList+(cGList==''?'':';')+a.S;
                        }
                    }
                    if(cGList!=NULL && cGList!='' && cGList.trim()!='')
                        rec.CognitoGroups__c = cGList;
                }
                if(rec.External_Id__c!=NULL)       
                    uniqueSet.put(rec.External_Id__c,rec);
                if(awsRec.assessments!=NULL && awsRec.assessments.L!=NULL)
                {
                    for(AWSassessmentM SLM:awsrec.assessments.L)
                    {
                        if(SLM!=NULL && SLM.M!=NULL  && SLM.M.id!=NULL && SLM.M.id.S!=NULL)
                        {
                            Torc_Assessment__c tRec = new Torc_Assessment__c();
                            tRec.Torc_User__r = new Torc_User__c(External_Id__c = rec.External_Id__c);
                            tRec.External_ID__c = SLM.M.id==NULL?Null:SLM.M.id.S;
                            tRec.codeScore__c = SLM.M.codeScore==NULL?Null:SLM.M.codeScore.N;
                            tRec.finalScore__c = SLM.M.finalScore==NULL?Null:SLM.M.finalScore.N;
                            tRec.multipleChoiceScore__c = SLM.M.multipleChoiceScore==NULL?Null:SLM.M.multipleChoiceScore.N;
                            tRec.timeTaken__c = SLM.M.timeTaken==NULL?Null:SLM.M.timeTaken.N;                            
                            tRec.plagiarism__c = SLM.M.plagiarism==NULL?Null:SLM.M.plagiarism.S;
                            tRec.status__c = SLM.M.status==NULL?Null:SLM.M.status.S;
                            tRec.testId__c = SLM.M.testId==NULL?Null:SLM.M.testId.S;
                            tRec.testName__c = SLM.M.testName==NULL?Null:SLM.M.testName.S;
                            tRec.reportLink__c = SLM.M.reportLink==NULL?Null:SLM.M.reportLink.S;                            
                            tRec.assessmentDate__c = SLM.M.assessmentCompleted==NULL?Null: stringtoDateTime(SLM.M.assessmentCompleted.S);
                            tRec.source__c = SLM.M.source==NULL?Null:SLM.M.source.S;
                            tRec.createdAt__c = SLM.M.createdAt==NULL?Null: stringtoDateTime(SLM.M.createdAt.S);
                            tRec.updatedAt__c = SLM.M.updatedAt==NULL?Null: stringtoDateTime(SLM.M.updatedAt.S);
                            assessmentl.put(tRec.External_ID__c,tRec);
                        }
                    }
                }
                AWS_Event__c newAWSEve = new AWS_Event__c(Json__c=JSON.serialize(awsRec).left(131000),info_1__c='USER',info_2__c=rec.external_id__c, info_3__c=rec.email__c,info_4__c=rec.updater__c);
                newAWSEve.eventId__c = awsRec.eventId==NULL || awsRec.eventId==''?null:awsRec.eventId;
                lstAwsEventLocal.add(newAWSEve);
            }
            
            Schema.SObjectField fSk = Torc_Skill__c.Fields.External_ID__c;
            
            
            database.upsert(skilMap.values(), fSk,false);
            
            Schema.SObjectField f = Torc_User__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(uniqueSet.values(),f,false);
            
            system.debug(dr);
            
            Schema.SObjectField fAss = Torc_Assessment__c.Fields.External_ID__c;
            List<database.UpsertResult> drAss = database.Upsert(assessmentl.values(),fAss,false); 
            
            AWSDataLoad.recordOutput(dr,(lstAwsEventLocal.size()>0?lstAwsEventLocal[0]:NULL));
            //AWSDataLoad.recordOutput(drAss,(lstAwsEventLocal.size()>0?lstAwsEventLocal[0]:NULL));
            //upsert l External_ID__c;
            if(lstawsEvent!=NULL)
                lstawsEvent.addAll(lstAwsEventLocal);
            return uniqueSet.values();
        }
    }
    
    Public class AWSUserResume
    {
        Public String userId;
        Public String resumeLocation;
        Public Boolean uploadedByRD;
        Public String eventType;
    }

    Public class AWSUserResumeCall
    {
        Public List<AWSUserResume> Items{get;set;}
        public List<Torc_User__c> upsertInSFDC()
        {
            List<Torc_User__c> l=new List<Torc_User__c>();
            for(AWSUserResume awsrec:Items)
            {
                Torc_User__c rec=new Torc_User__c();
                rec.resumeuploadedByRD__c = awsrec.uploadedByRD;
                rec.resumeLocation__c = awsrec.resumeLocation;
                rec.External_ID__c = awsrec.userId;
                rec.resumeUpdateTime__c = dateTime.now();
                l.add(rec);
            }
            Schema.SObjectField f = Torc_User__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(l,f,false);
            return l;
        }
    }
    
    
    
    
    
    Public class AWSJobType
    {
        Public AWSString createdAt;
        Public AWSBool deleteit;
        Public AWSString id;
        Public AWSBOOL isActive;
        Public AWSString overview;
        Public AWSString requirements;
        Public AWSString responsibilities;
        Public AWSString title;
        Public AWSString updatedAt;
        Public AWSSkillsL skills;
    }
    Public class AWSJobTypeCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSJobType> Items;
        public List<Torc_Job_Type__c> upsertInSFDC(AWS_Sync__c awsSyncrec)
        {
            List<Torc_Job_Type__c> l=new List<Torc_Job_Type__c>();
            Map<String,Torc_Skill__c> skilMap=new Map<String,Torc_Skill__c>();
            for(AWSJobType awsrec:Items)
            {
                Torc_Job_Type__c rec=new Torc_Job_Type__c(); 
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.updatedAt__c = awsrec.updatedAt==NULL?Null: stringtoDateTime(awsrec.updatedAt.S);
                rec.External_Id__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.isActive__c = awsrec.isActive==NULL?False:awsrec.isActive.BOOL;
                rec.title__c = awsrec.title==NULL?Null:awsrec.title.S;
                rec.Name = awsrec.title==NULL?Null:awsrec.title.S;
                rec.overview__c = awsrec.overview==NULL?Null:awsrec.overview.S;
                rec.requirements__c = awsrec.requirements==NULL?Null:awsrec.requirements.S;
                rec.responsibilities__c = awsrec.responsibilities==NULL?Null:awsrec.responsibilities.S;
                rec.skills__c = awsrec.skills==NULL?Null:awsrec.skills.getInString(skilMap);
                rec.skills_Id__c = awsrec.skills==NULL?Null:awsrec.skills.getInIDString();
                if(awsrec.deleteIt!=NULL && awsrec.deleteIt.BOOL!=NULL && awsrec.deleteIt.BOOL)
                    rec.Delete_From_Platform__c = true;
                l.add(rec);    
            }
            upsert skilMap.values() External_ID__c;
            Schema.SObjectField f = Torc_Job_Type__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(l,f,false);
            AWSDataLoad.recordOutput(dr);
            //upsert l External_ID__c;
            return l;
        }
    }
    public class AWSpreferredRateM
    {
        public AWSpreferredRate M;
    }
    Public Class AWSpreferredRate
    {
        Public AWSInteger value;
        Public AWSString x_currency;
    }
    Public class AWSApplication
    {
        Public AWSString availableStartDate;
        Public AWSBool deleteit;
        Public AWSString createdAt;
        Public AWSString creator;
        Public AWSString id;
        Public AWSString jobTypeId;
        Public AWSString owner;
        Public AWSpreferredRateM preferredRate;
        Public AWSString updatedAt;
        Public AWSString updater;
        Public AWSString userId;
    }
    Public class AWSApplicationCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSApplication> Items;
        public List<Torc_Application__c> upsertInSFDC(AWS_Sync__c awsSyncrec)
        {
            List<Torc_Application__c> l=new List<Torc_Application__c>();
            for(AWSApplication awsrec:Items)
            {
                Torc_Application__c rec=new Torc_Application__c(); 
                rec.availableStartDate__c = awsrec.availableStartDate==NULL?Null: stringtoDate(awsrec.availableStartDate.S);
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.updatedAt__c = awsrec.updatedAt==NULL?Null: stringtoDateTime(awsrec.updatedAt.S);
                rec.creator__c = awsrec.creator==NULL?Null:awsrec.creator.S;
                rec.owner__c = awsrec.owner==NULL?Null:awsrec.owner.S;
                rec.updater__c = awsrec.updater==NULL?Null:awsrec.updater.S;
                rec.External_Id__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.jobTypeId__c = awsrec.jobTypeId==NULL?Null:awsrec.jobTypeId.S;
                rec.userId__c = awsrec.userId==NULL?Null:awsrec.userId.S;
                if(awsrec.preferredRate!=NULL && awsrec.preferredRate.M!=NULL)
                {
                    rec.Preferred_Rate__c = awsrec.preferredRate.M.value==NULL?NULL:awsrec.preferredRate.M.value.N;
                }
                if(awsrec.deleteIt!=NULL && awsrec.deleteIt.BOOL!=NULL && awsrec.deleteIt.BOOL)
                    rec.Delete_From_Platform__c = true;
                rec.Torc_Job_Type__r = new Torc_Job_Type__c(External_Id__c = rec.jobTypeId__c);
                rec.Torc_User__r = new Torc_User__c(External_Id__c = rec.userId__c);
                l.add(rec);    
            }
            Schema.SObjectField f = Torc_Application__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(l,f,false);
            AWSDataLoad.recordOutput(dr);
            system.debug(dr);
            //upsert l External_ID__c;
            return l;
        }
    }
    Public class AWSJobOpportunityCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSJobOpportunity> Items;
        public List<Torc_Job_Opportunity__c> upsertInSFDC(AWS_Sync__c awsSyncrec,List<AWS_Event__c> lstawsEvent)
        {
            List<AWS_Event__c> lstAwsEventLocal = new List<AWS_Event__c>();
            Map<String,Torc_Skill__c> skilMap=new Map<String,Torc_Skill__c>();
            Map<string,Torc_Job_Opportunity__c> uniqueSet=new Map<string,Torc_Job_Opportunity__c>();
            for(AWSJobOpportunity awsrec:Items)
            {
                Torc_Job_Opportunity__c rec=new Torc_Job_Opportunity__c(); 
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.updatedAt__c = awsrec.updatedAt==NULL?Null: stringtoDateTime(awsrec.updatedAt.S);
                rec.updater__c = awsrec.updater==NULL?Null:awsrec.updater.S;
                rec.creator__c = awsrec.creator==NULL?Null:awsrec.creator.S;
                rec.External_Id__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.Name = awsrec.title==NULL?Null:awsrec.title.S.left(80);
                rec.title__c = awsrec.title==NULL?Null:awsrec.title.S;
                rec.owner__c = awsrec.owner==NULL?Null:awsrec.owner.S;
                rec.jobTypeId__c = awsrec.jobTypeId==NULL?Null:awsrec.jobTypeId.S;
                rec.overview__c = awsrec.overview==NULL?Null:awsrec.overview.S;
                rec.requirements__c = awsrec.requirements==NULL?Null:awsrec.requirements.S;
                rec.responsibilities__c = awsrec.responsibilities==NULL?Null:awsrec.responsibilities.S;
                rec.torcOwner__c = (awsRec.torcOwner==NULL || awsRec.torcOwner.M==NULL || awsRec.torcOwner.M.userName==NULL)?null:awsRec.torcOwner.M.userName.S;
                
                rec.Customer_Owner_User__c = (awsRec.customerOwner==NULL || awsRec.customerOwner.M==NULL || awsRec.customerOwner.M.userName==NULL)?null:awsRec.customerOwner.M.userName.S;
                rec.Customer_Owner_Id__c = (awsRec.customerOwner==NULL || awsRec.customerOwner.M==NULL || awsRec.customerOwner.M.Id==NULL)?null:awsRec.customerOwner.M.id.S;
                rec.status__c = awsrec.status==NULL?Null:awsrec.status.S;
                rec.timeCommitment__c = awsrec.timeCommitment==NULL?Null:awsrec.timeCommitment.S;
                rec.timeOverlap__c = awsrec.timeOverlap==NULL?Null:awsrec.timeOverlap.N;
                rec.StartDate__c = awsrec.StartDate==NULL?Null: stringtoDate(awsrec.StartDate.S);
                rec.jobLength__c = awsrec.jobLength==NULL?Null:awsrec.jobLength.N;
                rec.jobLengthInWeeks__c = awsrec.jobLengthInWeeks==NULL?Null:awsrec.jobLengthInWeeks.N;
                
                rec.requiredPositions__c = awsrec.requiredPositions==NULL?Null:awsrec.requiredPositions.N;
                rec.openPositions__c = awsrec.openPositions==NULL?Null:awsrec.openPositions.N;
                                            
                rec.maxRate__c = (awsrec.maxRate==NULL || awsrec.maxRate.M==null || awsrec.maxRate.M.value==null) ?Null:awsrec.maxRate.M.value.N;
                rec.minRate__c = (awsrec.minRate==NULL || awsrec.minRate.M==null || awsrec.minRate.M.value==null) ?Null:awsrec.minRate.M.value.N;
                rec.regions__c = awsrec.regions==NULL?Null:awsrec.regions.getInString();
                rec.skills__c = awsrec.skills==NULL?Null:awsrec.skills.getInString(skilMap);
                rec.skills_Id__c = awsrec.skills==NULL?Null:awsrec.skills.getInIDString();
                rec.timeZone__c = (awsrec.timeZone!=NULL && awsrec.timeZone.M!=NULL && awsrec.timeZone.M.value!=NULL)?awsrec.timeZone.M.value.S:NULL;
                rec.Torc_Job_Type__r = new Torc_Job_Type__c(External_Id__c = rec.jobTypeId__c);
                rec.customerId__c = awsrec.customerId==NULL?Null:awsrec.customerId.S;
                rec.organization__c = awsrec.organization==NULL?Null:awsrec.organization.S;
                rec.externalJobId__c = awsrec.externalJobId==NULL?Null:awsrec.externalJobId.S;
                if(awsrec.sfdcExternalID!=NULL && awsrec.sfdcExternalID.S!=null && awsrec.sfdcExternalID.S!='')
                    rec.sfdcExternalID__c = awsrec.sfdcExternalID==NULL?Null:awsrec.sfdcExternalID.S;
               
                rec.priorityLevel__c = awsrec.priorityLevel==NULL?Null:awsrec.priorityLevel.S;
                
                rec.workMode__c = awsrec.workMode==NULL?Null:awsrec.workMode.S;
                rec.employmentType__c = awsrec.employmentType==NULL?Null:awsrec.employmentType.S;
                rec.shortDescription__c = awsrec.shortDescription==NULL?Null:awsrec.shortDescription.S;                
                rec.maxSalary__c = (awsrec.maxSalary==NULL || awsrec.maxSalary.M==null || awsrec.maxSalary.M.value==null) ?Null:awsrec.maxSalary.M.value.N;
                rec.minSalary__c = (awsrec.minSalary==NULL || awsrec.minSalary.M==null || awsrec.minSalary.M.value==null) ?Null:awsrec.minSalary.M.value.N;
                              
                if(awsrec.deleteIt!=NULL && awsrec.deleteIt.BOOL!=NULL && awsrec.deleteIt.BOOL)
                    rec.Delete_From_Platform__c = true;
                if(rec.customerId__c!=NULL && rec.customerId__c!='' && rec.customerId__c!=rec.External_Id__c)                
                    rec.Torc_Customer__r = new torc_user__c(External_Id__c=rec.customerId__c);
                
                if( awsRec.torcOwner!=NULL && awsRec.torcOwner.M!=NULL && awsRec.torcOwner.M.id!=NULL && 
                    awsRec.torcOwner.M.id.S!=NULL && awsRec.torcOwner.M.id.S!='')
                    rec.Talent_Owner__r = new torc_user__c(External_Id__c=awsRec.torcOwner.M.id.S);
                if(rec.Customer_Owner_Id__c!=NULL)
                    rec.CustomerOwner__r = new torc_user__c(External_Id__c=rec.Customer_Owner_Id__c); 
                if(rec.External_Id__c!=NULL)       
                    uniqueSet.put(rec.External_Id__c,rec);

            
                AWS_Event__c newAWSEve = new AWS_Event__c(Json__c=JSON.serialize(awsRec).left(131000),info_1__c='JOB',info_2__c=rec.external_id__c, info_3__c=rec.Name,info_4__c=rec.updater__c);
                newAWSEve.eventId__c = awsRec.eventId==NULL || awsRec.eventId==''?null:awsRec.eventId;
                lstAwsEventLocal.add(newAWSEve);
            }
            upsert skilMap.values() External_ID__c;
            
            Schema.SObjectField f = Torc_Job_Opportunity__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(uniqueSet.values(),f,false);
            system.debug(dr);
            AWSDataLoad.recordOutput(dr,(lstAwsEventLocal.size()>0?lstAwsEventLocal[0]:NULL));
            if(lstawsEvent!=NULL)
                lstawsEvent.addAll(lstAwsEventLocal);

            //upsert l External_ID__c;
            return uniqueSet.values();
        }
    }
    Public class AWSJobOpportunity
    {
        Public AWSString createdAt;
        Public AWSBool deleteit;
        Public AWSString organization{get;set;}
        Public AWSString customerId;
        Public AWSString id;
        Public AWSString title;
        Public AWSString updatedAt;
        Public AWSString updater;
        Public AWSString creator;
        Public AWSString externalJobId;
        Public AWSString sfdcExternalID;
        Public AWSString overview;
        Public AWSString owner;
        Public AWSString priorityLevel;
        Public AWSString jobTypeId;
        Public AWSInteger jobLength;
        Public AWSratePerHourM maxRate;
        Public AWSratePerHourM minRate;
        Public AWSReagons regions;
        Public AWSString requirements;
        Public AWSString responsibilities;
        Public AWSString status;
        Public AWSString timeCommitment;
        Public AWSInteger timeOverlap;
        Public AWSString startDate;
        Public AWSInteger jobLengthInWeeks;
        Public AWSSkillsL skills;
        Public AWSTimeZoneM timezone;
        Public AWStorcOwnerM torcOwner;
        Public AWStorcOwnerM customerOwner;
        Public AWSInteger requiredPositions;
        Public AWSInteger openPositions;
        
        Public AWSString workMode;
        Public AWSString employmentType;
        Public AWSString shortDescription;
        Public AWSratePerHourM maxSalary;
        Public AWSratePerHourM minSalary;
        public string eventId;
    }
    Public class AWStorcOwnerM
    {
        Public AWStorcOwner M;
    }
    Public class AWStorcOwner
    {
        Public AWSString username;
        Public AWSString id;
    }
    Public class AWSresumeWorkHistoryL
    {
        Public List<AWSresumeWorkHistoryM>L;
    }  
    Public class AWSresumeWorkHistoryM
    {
        Public AWSresumeWorkHistory M;
    }
    Public class AWSresumeWorkHistory
    {
        Public AWSString startDate;
        Public AWSString title;
        Public AWSString id;
        Public AWSString locationType;
        Public AWSString description;
        Public AWSString format;
        Public AWSString companyName;
        Public AWSString endDate;
        Public AWSString stack;
        Public AWSSkillsL skills;
    }
    Public class AWSSkillsL
    {
        Public List<AWSSkillsM>L;
        Public string getInString(Map<String,Torc_Skill__c> sklM)
        {
            if(L==null)return '';
            string res='';
            for(AWSSkillsM rec:l)
            {
                if(rec.M!=NULL && rec.M.name!=NULL)
                {
                    res = res + (res==''?'':', ')+(rec.M.name.S==NULL?'':rec.M.name.S);
                    if(sklM.get(rec.M.Id.S)==NULL)
                    {
                       string nm = rec.M.name.S;
                       nm=nm==null?null:nm.left(79);
                       Torc_Skill__c ts=new Torc_Skill__c(External_Id__c=rec.M.Id.S, Name = nm);
                       if(rec.M.type!=NULL && rec.M.type.M!=NULL && rec.M.type.M.name!=NULL)
                       {
                           ts.Type_Name__c = rec.M.type.M.name.S;
                           ts.Type_Id__c = rec.M.type.M.id.S;
                       }
                       sklM.put(rec.M.Id.S,ts); 
                    }   
                }
            }
            return res;
        }
        Public string getInIDString()
        {
            if(L==null)return '';
            string res='';
            for(AWSSkillsM rec:l)
            {
                if(rec.M!=NULL && rec.M.name!=NULL)
                {
                    res = res + (res==''?'':',')+(rec.M.id.S==NULL?'':rec.M.id.S);  
                }
            }
            return res;
        }
        Public string getInExperienceString()
        {
            if(L==null)return '';
            string res='';
            for(AWSSkillsM rec:l)
            {
                if(rec.M!=NULL && rec.M.name!=NULL)
                {
                    string exp = rec.M.experience==NULL?NULL:rec.M.experience.S;
                    res = res + (res==''?'':',')+(exp==NULL?'':exp);  
                }
            }
            return res;
        }
       
        
    }
    Public class AWSSkillsM
    {
        Public AWSSkills M;
    }
    Public class AWSSkills
    {
        Public AWSString name;
        Public AWSString id;
        Public AWSString infoUrl;
        Public AWSSkillTypeM type;
        public AWSString experience;
    }
    Public class AWSSkillTypeM
    {
        Public AWSSkillType M;
    }
    Public class AWSSkillType
    {
        Public AWSString name;
        Public AWSString id;
    }
    Public class AWSReagons
    {
        Public List<AWSString> L;
        Public string getInString()
        {
            if(L==null)return '';
            string res='';
            for(AWSString rec:l)
            {
                if(rec.S!=NULL)
                {
                    res = res + (res==''?'':', ')+rec.S;
                }
            }
            return res;
        }
    }
    Public class AWSTimeZoneM
    {
        Public AWSTimeZone M;
    }
    Public class AWSTimeZone
    {
        Public AWSString value;
        Public AWSString label;
    }
    
    Public class AWSMatch
    {
        Public AWSString createdAt;
        Public AWSBool deleteit;
        Public AWSString creator;
        Public AWSString updatedAt;
        Public AWSString updater;
        Public AWSString userid;
        Public AWSString id;
        Public AWSString title;
        Public AWSString applicationId;
        Public AWSString jobOpportunityId;
        Public AWSString owner;
        Public AWSString matcher;
        Public reasonForRejectionCls reasonForRejection;
        Public AWSString status;
        Public AWSString subStatus;
        Public AWSString sfdcStatus;
        
        Public AWSBool sfdcRejected;
        Public AWSString sfdcRejectionRoot;
        Public AWSString sfdcRejectionReason;
        
        
        public AWSString freelancerPitch;
        
        Public AWSString availableStartDate;
        Public AWSratePerHourM rate;
        Public AWSratePerHourM customerRate;
        public string eventId;
        
    }
    public class reasonForRejectionCls
    {
        Public List<AWSString> L;
    }
    Public class AWSMatchCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSMatch> Items;
        public List< Torc_Match__c > upsertInSFDC(AWS_Sync__c awsSyncrec,List<AWS_Event__c> lstawsEvent)
        {
            List<AWS_Event__c> lstAwsEventLocal = new List<AWS_Event__c>();
            
            Map<string,Torc_Match__c> uniqueSet=new Map<string,Torc_Match__c>();
            
            Map<string,Torc_Match_Shadow__c> uniqueSetShadow=new Map<string,Torc_Match_Shadow__c>();
            for(AWSMatch awsrec:Items)
            {
                Torc_Match__c rec=new Torc_Match__c(); 
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.updatedAt__c = awsrec.updatedAt==NULL?Null: stringtoDateTime(awsrec.updatedAt.S);
                rec.updater__c = awsrec.updater==NULL?Null:awsrec.updater.S;
                rec.creator__c = awsrec.creator==NULL?Null:awsrec.creator.S;
                rec.Platform_Id__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.External_Id__c = awsrec.applicationId.S +'-'+awsrec.jobOpportunityId.S;
                rec.owner__c = awsrec.owner==NULL?Null:awsrec.owner.S;
                rec.matcher__c = awsrec.matcher==NULL?Null:awsrec.matcher.S;
                rec.Status__c = awsrec.Status==NULL?Null:awsrec.Status.S;
                rec.subStatus__c = awsrec.subStatus==NULL?Null:awsrec.subStatus.S;
                rec.sfdcStatus__c = awsrec.sfdcStatus==NULL?Null:awsrec.sfdcStatus.S;
                rec.sfdcRejected__c = (awsrec.sfdcRejected==NULL || awsrec.sfdcRejected.BOOL==NULL)?false:awsrec.sfdcRejected.BOOL;
                rec.sfdcRejectionRoot__c = awsrec.sfdcRejectionRoot==NULL?Null:awsrec.sfdcRejectionRoot.S;
                rec.sfdcRejectionReason__c = awsrec.sfdcRejectionReason==NULL?Null:awsrec.sfdcRejectionReason.S;
                string reasonForRejection='';
                if(awsrec.reasonForRejection!=NULL && awsrec.reasonForRejection.L!=NULL && awsrec.reasonForRejection.L.size()>0)
                {
                    for(AWSString s:awsrec.reasonForRejection.L)
                        if(s!=NULL && s.S!=NULL && s.S!='')  
                            reasonForRejection=reasonForRejection+(reasonForRejection==''?'':', ')+s.S;
                }
                rec.reasonForRejection__c = reasonForRejection.left(255);
                rec.freelancerPitch__c = awsrec.freelancerPitch==NULL || awsrec.freelancerPitch.S==NULL?Null:awsrec.freelancerPitch.S.left(2000); 
                              
                if(awsrec.deleteIt!=NULL && awsrec.deleteIt.BOOL!=NULL && awsrec.deleteIt.BOOL)
                {
                    system.debug('DELETING MARK-----------------------------------------------');
                    rec.Delete_From_Platform__c = true;
                    if(torcRD1Integration.isUpdaterSFDC(rec.updater__c)) rec.updater__c='deleterdummy';
                }
                else
                {
                    rec.Delete_From_Platform__c = false;
                }
                rec.availableStartDate__c = awsrec.availableStartDate==NULL?Null: stringtoDateTime(awsrec.availableStartDate.S);
                rec.rate__c = (awsrec.rate!=NULL && awsrec.rate.M!=NULL && awsrec.rate.M.value!=NULL)?awsrec.rate.M.value.N:Null;
                rec.customerRate__c = (awsrec.customerRate!=NULL && awsrec.customerRate.M!=NULL && awsrec.customerRate.M.value!=NULL)?awsrec.customerRate.M.value.N:Null;
                rec.jobOpportunityId__c = awsrec.jobOpportunityId==NULL?Null:awsrec.jobOpportunityId.S;
                rec.applicationId__c = awsrec.applicationId==NULL?Null:awsrec.applicationId.S;
                rec.userid__c = awsrec.userid==NULL?Null:awsrec.userid.S;
                
                rec.Torc_Job_Opportunity__r = new Torc_Job_Opportunity__c(External_Id__c = rec.jobOpportunityId__c);
                //rec.Torc_Application__r=null;
                //if(rec.applicationId__c!=NULL && rec.applicationId__c.length()>5 && rec.applicationId__c.left(5)!='User#')                
                //    rec.Torc_Application__r = new Torc_Application__c(External_Id__c = rec.applicationId__c);
                if(rec.userid__c!=NULL)
                    rec.Torc_User_Ref__r = new Torc_User__c(External_Id__c = rec.userid__c);
                
                system.debug(rec.External_Id__c);
                
                if(rec.External_Id__c!=NULL)     
                {  
                    system.debug(uniqueSet.get(rec.External_Id__c));
                    uniqueSet.put(rec.External_Id__c.toLowerCase().trim(),rec);
                }    
                
                Torc_Match_Shadow__c resShadow = new Torc_Match_Shadow__c();
                resShadow.External_Id__c            =rec.External_Id__c;
                resShadow.applicationId__c=rec.applicationId__c;
                resShadow.Delete_From_Platform__c=rec.Delete_From_Platform__c;
                resShadow.freelancerPitch__c=rec.freelancerPitch__c;
                resShadow.jobOpportunityId__c=rec.jobOpportunityId__c;
                resShadow.Matcher__c=rec.Matcher__c;
                resShadow.Platform_Id__c=rec.Platform_Id__c;
                resShadow.reasonForRejection__c=rec.reasonForRejection__c;
                resShadow.status__c=rec.status__c;
                resShadow.subStatus__c=rec.subStatus__c;
                resShadow.updater__c=rec.updater__c;
                resShadow.userid__c=rec.userid__c;
                if(resShadow.External_Id__c!=NULL)     
                {  
                    system.debug(uniqueSetShadow.get(resShadow.External_Id__c));
                    uniqueSetShadow.put(resShadow.External_Id__c.toLowerCase().trim(),resShadow);
                }    
                AWS_Event__c newAWSEve = new AWS_Event__c(Json__c=JSON.serialize(awsRec).left(131000), info_1__c='MATCH',info_2__c=rec.Status__c, info_3__c=rec.jobOpportunityId__c,info_5__c=rec.userId__c,info_4__c=rec.updater__c);
                newAWSEve.eventId__c = awsRec.eventId==NULL || awsRec.eventId==''?null:awsRec.eventId;
                lstAwsEventLocal.add(newAWSEve);
                
                   
            }
            Schema.SObjectField fShadow = Torc_Match_Shadow__c.Fields.External_ID__c;
            system.debug(uniqueSetShadow.keyset());
            system.debug(uniqueSetShadow.values());
            List<database.UpsertResult> drShadow = database.Upsert(uniqueSetShadow.values(),fShadow,false);  
            AWSDataLoad.recordOutput(drShadow,(lstAwsEventLocal.size()>0?lstAwsEventLocal[0]:NULL));
            system.debug(drShadow);  
            system.debug('===== onlyLoadmatchInShadow'+onlyLoadmatchInShadow);        
            if(!onlyLoadmatchInShadow)
            {
                Schema.SObjectField f = Torc_Match__c.Fields.External_ID__c;
                system.debug(uniqueSet.keyset());
                system.debug(uniqueSet.values());
                List<database.UpsertResult> dr = database.Upsert(uniqueSet.values(),f,false);  
                AWSDataLoad.recordOutput(dr,(lstAwsEventLocal.size()>0?lstAwsEventLocal[0]:NULL));
            }    
            if(lstawsEvent!=NULL)
                lstawsEvent.addAll(lstAwsEventLocal);
            return uniqueSet.values();
        }
    }
    Public class AWSNote
    {
        Public AWSString createdAt;
        Public AWSString creator;
        Public AWSString externalId;
        Public AWSString userId;
        Public AWSString jobOpportunityId;
        Public AWSString content;
        Public AWSString updater;
        Public AWSString noteType;
        Public AWSString id;
        Public AWSBool isPublic;
    }
    
    Public class AWSNoteCall
    {
        Public AWSLastEvaluatedKeySuperSet LastEvaluatedKey;
        Public Integer Count;
        Public Integer ScannedCount;
        Public List<AWSNote> Items;
        public List< Torc_Note__c > upsertInSFDC(AWS_Sync__c awsSyncrec,List<AWS_Event__c> lstawsEvent)
        {
            List<AWS_Event__c> lstAwsEventLocal = new List<AWS_Event__c>();
            List< Torc_Note__c > l=new List< Torc_Note__c >();
            for(AWSNote awsrec:Items)
            {
                Torc_Note__c rec=new Torc_Note__c(); 
                
                rec.createdAt__c = awsrec.createdAt==NULL?Null: stringtoDateTime(awsrec.createdAt.S);
                rec.updater__c = awsrec.updater==NULL?Null:awsrec.updater.S;
                rec.creator__c = awsrec.creator==NULL?Null:awsrec.creator.S;
                rec.external_Id__c = awsrec.id==NULL?Null:awsrec.id.S;
                rec.externalSystemId__c = awsrec.externalId==NULL?Null:awsrec.externalId.S;
                rec.userId__c = awsrec.userId==NULL?Null:awsrec.userId.S;
                rec.jobOpportunityId__c = awsrec.jobOpportunityId==NULL?Null:awsrec.jobOpportunityId.S;
                rec.content__c = awsrec.content==NULL?Null:awsrec.content.S;
                rec.noteType__c = awsrec.noteType==NULL?Null:awsrec.noteType.S;
                rec.isPublic__c = (awsrec.isPublic!=NULL && awsrec.isPublic.BOOL!=NULL && awsrec.isPublic.BOOL);
                if(rec.userid__c!=NULL)
                    rec.Torc_User__r = new Torc_User__c(External_Id__c = rec.userid__c);
                if(rec.jobOpportunityId__c!=NULL)
                    rec.Torc_Job_Opportunity__r = new Torc_Job_Opportunity__c(External_Id__c = rec.jobOpportunityId__c);    
                l.add(rec);  

                AWS_Event__c newAWSEve = new AWS_Event__c(Json__c=JSON.serialize(awsRec).left(131000), info_1__c='NOTE',info_2__c=rec.noteType__c, info_3__c=rec.jobOpportunityId__c,info_5__c=rec.userId__c,info_4__c=rec.updater__c);
                lstAwsEventLocal.add(newAWSEve); 
            }
            Schema.SObjectField f = Torc_Note__c.Fields.External_ID__c;
            List<database.UpsertResult> dr = database.Upsert(l,f,false);  
            system.debug(dr);          
            AWSDataLoad.recordOutput(dr);
            if(lstawsEvent!=NULL)
                lstawsEvent.addAll(lstAwsEventLocal);
            return l;
        }
    }    
    
    
    
    
    
    Public Static DateTime stringtoDateTime(String s)
    {
        if(s==NULL || s=='')
            return null;
        String []l1=s.split('T');
        String []dt=l1[0].split('-');
        String []tm=l1[1].split(':');   
        Datetime d=datetime.newInstance(Integer.valueof(dt[0]),
                                        Integer.valueof(dt[1]),
                                        Integer.valueof(dt[2]),
                                        Integer.valueof(tm[0]),
                                        Integer.valueof(tm[1]),
                                        0
                                       );
        return d;
    }
    Public Static Date stringtoDate(String s)
    {
        if(s==NULL || s=='')
            return null;
        String []l1=s.split('T');
        String []dt=l1[0].split('-');
        Date d=date.newInstance(Integer.valueof(dt[0]),Integer.valueof(dt[1]),Integer.valueof(dt[2]));
        return d;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadUsersNow(JSONParser parser,AWS_Sync__c awsrec,List<AWS_Event__c> awsEventlst)
    {
        //JSONParser parser = LoadData('User');
        AWSUserCall res=(AWSUserCall)parser.readValueAs(AWSUserCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec, awsEventlst);
        //return res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadjobTypeNow(JSONParser parser,AWS_Sync__c awsrec)
    {
        //JSONParser parser = LoadData('JobType');
        AWSJobTypeCall res=(AWSJobTypeCall)parser.readValueAs(AWSJobTypeCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec);
        //return (res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadApplicationNow(JSONParser parser,AWS_Sync__c awsrec)
    {
        //JSONParser parser = LoadData('Application');
        AWSApplicationCall res=(AWSApplicationCall)parser.readValueAs(AWSApplicationCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec);
        //return (res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadJobOpportunityNow(JSONParser parser,AWS_Sync__c awsrec,List<AWS_Event__c> awsEventlst)
    {
        //JSONParser parser = LoadData('JobOpportunity');
        AWSJobOpportunityCall res=(AWSJobOpportunityCall)parser.readValueAs(AWSJobOpportunityCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec,awsEventlst);
        //return (res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadMatchNow(JSONParser parser,AWS_Sync__c awsrec,List<AWS_Event__c> awsEventlst)
    {
        //JSONParser parser = LoadData('Match');
        AWSMatchCall res=(AWSMatchCall)parser.readValueAs(AWSMatchCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec,awsEventlst);
        //return (res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadNoteNow(JSONParser parser,AWS_Sync__c awsrec,List<AWS_Event__c> awsEventlst)
    {
        AWSNoteCall res=(AWSNoteCall)parser.readValueAs(AWSNoteCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec,awsEventlst);
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadHistoryNow(JSONParser parser,AWS_Sync__c awsrec)
    {
        //JSONParser parser = LoadData('User');
        AWSHistoryCall res=(AWSHistoryCall)parser.readValueAs(AWSHistoryCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec);
        //return (res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public Static AWSDataLoad.AWSLastEvaluatedKeySuperSet LoadReferralStatusNow(JSONParser parser,AWS_Sync__c awsrec)
    {
        //JSONParser parser = LoadData('User');
        AWSReferralStatusCall res=(AWSReferralStatusCall)parser.readValueAs(AWSReferralStatusCall.class);
        system.debug(res);
        res.upsertInSFDC(awsrec);
        //return (res.LastEvaluatedKey!=NULL && res.LastEvaluatedKey.id!=NULL)?res.LastEvaluatedKey.id.S:NULL;
        return res.LastEvaluatedKey;
    }
    Public static void recordOutput(List<database.UpsertResult> dr)
    {
        recordOutput( dr,null);
    }
    Public static void recordOutput(List<database.UpsertResult> dr,aws_Event__c awsEvent)
    {
        if(awsEvent==NULL) return;
        integer err=0;
        string errorMsg=awsEvent.Error_Log__c==NULL?'':(awsEvent.Error_Log__c+'[OLD]');
        for(Database.UpsertResult drs:dr)
        { 
            if(!drs.isSuccess())
            {
                err++;
                if(drs.getErrors().size()>0)
                {
                    errorMsg = errorMsg+ drs.getErrors()[0].getMessage();
                }    
            }
        }                    
        system.debug(errorMsg);
        if(awsEvent!=NULL && err>0)
        {
            awsEvent.Error_Log__c = err.toString()+'/'+errorMsg.left(950);
            awsEvent.Retry_Error__c = awsEvent.Error_Log__c.toLowerCase().indexOf('not found for field external_id__c in entity')>0;
        }
    }
    
    public static string bodyreparse(string body)
    {
        return body.replace('"currency"','"x_currency"')
                   .replace('"date"','"x_date"')
                   .replace('"number"','"x_number"')
                   .replace('"Do Not Disturb"','"Do_Not_Disturb"')
                   .replace('"Job Enabled"','"Job_Enabled"')
                   .replace('"__typename"','"type_name_sfdc"')
                   .replace('"Payment Enabled"','"Payment_Enabled"');
                   
    }
    Public static void realTimeProcess(List< Dynamo_Stream_Shadow__c> lstDynamo)
    {
        List<Object> itemList= new List<Object>();
        integer batchNo=0;
        for(Dynamo_Stream_Shadow__c ds:lstDynamo)
        {
            batchNo = Integer.valueOf(ds.Batch_Identifier__c);
            string body = bodyreparse(ds.JSON__c);
            List<Object> lst = (List<Object>)JSON.deSerializeUntyped(body);
            itemList.addAll(lst);
            system.debug('INITIAL BODY:' +body);
        }    
        realTimeProcess(itemList,batchNo);
    }
    Public static string realTimeProcess(List<Object> itemList,Integer batchN)
    {
        List<AWS_Event__c> lstEvent = new List<AWS_Event__c>();
        Map<string,List<Object>> mapRec= new Map<string,List<Object>>();
        AWSUserResumeCall arc=new AWSUserResumeCall();
        arc.items = new List<AWSUserResume>();
        for(object obj:itemList)
        {
            system.debug(obj);
            Map<String,Object> results = (Map<String,Object>)obj;
            string eventId =(string)results.get('eventID');
            string eventName = (string)results.get('eventName');
            string eventType = (string)results.get('eventType');
            system.debug(eventType);
            if(eventType=='resumeUpdated')
            {
                JSONParser jp = JSON.createParser(JSON.Serialize(obj));
                AWSUserResume resum=(AWSUserResume)jp.readValueAs(AWSUserResume.class);
                system.debug(resUm);
                arc.items.add(resum);
            }
            else
            {
                string tableName = (string)results.get('eventSourceARN');
                tableName =tableName.split(':table/')[1].split('-')[0];
                results = (Map<String,Object>)results.get('dynamodb');
                Map<String,Object>newImage;
                if(eventName=='REMOVE')
                    newImage = (Map<String,Object>)results.get('OldImage');
                else    
                    newImage = (Map<String,Object>)results.get('NewImage');
                if(eventName=='REMOVE')
                {
                    Map<string,Boolean> mDel = new map<String,Boolean>();
                    mDel.put('BOOL',true);
                    newImage.put('deleteit',mDel);
                    system.debug('INREMOVECODE-----------------------------------------------');
                    
                }
                if(mapRec.get(tableName)==NULL)
                   mapRec.put(tableName,new List<Object>());
                   
                newImage.put('eventId',eventId);   
                mapRec.get(tableName).add(newImage);
                system.debug(tableName+'['+eventName+']');
            }    
        }       
        
        for(AWS_Sync__c awsrec : [Select Fields__c, Run_From__c,ID,Name, Table_Name__c, Order__c from AWS_Sync__c Where Name in :mapRec.keyset() AND Real_Time_Skip__c =FALSE Order by Order__c])
        {
            Map<string,Object> mapForUpsert=new Map<string,Object>();
            mapForUpsert.put('Count',mapRec.get(awsrec.Name).size());
            mapForUpsert.put('Items',mapRec.get(awsrec.Name));
            string Fbody = JSON.Serialize(mapForUpsert);
            system.debug(Fbody);
            loadNow(Fbody, awsrec,lstEvent);
        }
        if(lstEvent.size()>0)
        {            
            for(Aws_Event__c a:lstEvent)
                a.batch__c=batchN;
            insert lstEvent;
        }
        if(arc.items.size()>0)
        {
            arc.upsertInSFDC();
        }
        return lstEvent.size()>0?lstEvent[0].id:null;
    }
    public static AWSDataLoad.AWSLastEvaluatedKeySuperSet loadNow(string body, AWS_Sync__c awsrec)
    {
        return loadNow(body, awsrec,null);
    }
    public static AWSDataLoad.AWSLastEvaluatedKeySuperSet loadNow(string body, AWS_Sync__c awsrec,List<AWS_Event__c> awsEventlst)
    {
        JSONParser jp = JSON.createParser(body);
        if(awsrec.Name =='User')
            return AWSDataLoad.LoadUsersNow(jp,awsrec,awsEventlst);
        else if(awsrec.Name =='JobType')
            return AWSDataLoad.LoadjobTypeNow(jp,awsrec);
        else if(awsrec.Name =='Application')
            return AWSDataLoad.LoadApplicationNow(jp,awsrec);
        else if(awsrec.Name =='JobOpportunity')
            return AWSDataLoad.LoadJobOpportunityNow(jp,awsrec,awsEventlst);
        else if(awsrec.Name =='Match')
            return AWSDataLoad.LoadMatchNow(jp,awsrec,awsEventlst);
        else if(awsrec.Name =='History' || awsrec.Name =='JobHistory' || awsrec.Name =='MatchHistory')
            return AWSDataLoad.LoadHistoryNow(jp,awsrec);    
        else if(awsrec.Name =='ReferralStatus')
            return AWSDataLoad.LoadReferralStatusNow(jp,awsrec);        
        else if(awsrec.Name =='Note')
            return AWSDataLoad.LoadNoteNow(jp,awsrec,awsEventlst);            
        else
            return NULL; 
    }
    public static void updatematchesByJobId(string jobId)
    {
        AWS_Sync__c awsrec=[Select Use_Query__c, Fields__c, Max_Limit__c , Run_From__c,ID,Name, Table_Name__c, Order__c from AWS_Sync__c Where Name ='Match'];   
        string sct ='{"TableName":"'+awsrec.Table_Name__c+'","ProjectionExpression":null,"KeyConditionExpression":"jobOpportunityId = :val","IndexName":"byJobOpportunity","FilterExpression":null,"ExpressionAttributeValues":{":val":{"S":"'+jobId+'"}},"ExpressionAttributeNames":null,"ExclusiveStartKey":null}';
        if(!test.isrunningtest())
        {
            string body = AWS_Query.scanQueryTable(sct,false,'Match','Query');
            body = AWSDataLoad.bodyreparse(body);
            system.debug(body);
            AWSDataLoad.loadNow(body, awsrec);
        }    
    } 
}