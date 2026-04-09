/***********************************
 * Main class for generating and parsing the GraphQL JSON
 ***********************************/

public class RD1ToTorc_Job 
{
    public static String getGraphQLJson(TR1__Job__c Rdjob, boolean isInsert,Torc_user__c tu) 
    {
        List<String> lstQuery = new List<String>();
        
        if(isInsert)
        {
            lstQuery.add('mutation submitJobRequest($input: CreateJobOpportunityInput!, $extendedInput: ExtendedJobOpportunityInput){');
            lstQuery.add('submitJobRequest(input: $input, extendedInput: $extendedInput){');
        }
        else
        {
            lstQuery.add('mutation submitJobUpdate($input: UpdateJobOpportunityInput!,$extendedInput: ExtendedJobOpportunityInput){');
            lstQuery.add('submitJobUpdate(input: $input,extendedInput: $extendedInput){');
        }
        lstQuery.add('id');
        lstQuery.add('}');
        lstQuery.add('}');
        PlatformJob job = new PlatformJob(String.join(lstQuery, ' '), Rdjob,tu);
        return job.getJSON();
    }


    public static Platform_JobResponse parse(String json)
    {
        if(Test.isRunningTest())
            return new Platform_JobResponse();
        return (Platform_JobResponse) System.JSON.deserialize(json, Platform_JobResponse.class);
    }

    //================================ Inner Classes for handling the JSON drama ===================//

    public class PlatformJob 
    {
        public Job_Opportunity_Variables_Wrapper variables {get;set;}
        public string query {get;set;}
        public PlatformJob(String query, TR1__Job__c job,Torc_user__c tu) 
        {
            this.query = query;
            this.variables = new Job_Opportunity_Variables_Wrapper();
            this.variables.extendedInput = new Job_Opportunity_Variables_Extended_Input();
            this.variables.input = new Job_Opportunity_Variables_Input();
            torcRD1integrationMapping.filldata(job,this.variables.input,this.variables.extendedInput, tu);
            
        }
        public String getJSON() 
        {
            Boolean suppresNulls = true;
            String tempJSON = JSON.serialize(this, suppresNulls);
            return tempJSON.replace('currency_x', 'currency')
                            .replace('"address":{"state":"","country":"","city":""}','"address":null')
                            .replace('"geographicalRegions":[]','"geographicalRegions":null');
        }
    }

    public class Job_Opportunity_Variables_Wrapper 
    {
        public Job_Opportunity_Variables_Input input {get;set;} 
        public Job_Opportunity_Variables_Extended_Input extendedInput {get;set;}
    }
    public class Job_Opportunity_Variables_Extended_Input 
    {
        public Job_Address_Input address {get;set;}
        public List<String> skillsNames {get;set;}
        public String externalJobType {get;set;}
        public Job_Opportunity_Variables_Extended_Input() 
        {
            //this.address = new Job_Address_Input(bullhornJob);
            //this.skillsNames = new List<String>();
        }
    }

    public class Job_Address_Input 
    {
        public String city {get;set;}
        public String state {get;set;}
        public String country {get;set;}
        public Job_Address_Input(string country1,string state1, string city1) 
        {
            this.city = city1;
            this.state = state1;
            this.country = country1;
        }
    }
    public class TKSkill
    {
        public String id;
        public String category;
        public String name;
        public TKSkill(TR1__Skills__c rec)
        {
            id = rec.TR1__Skill_Code__c;
            category = torcRD1integrationMapping.getSkillsMap().getTorcValue(rec.TR1__Type__c);
            category = category!=NULL? category.toUpperCase():category;
            //torcRD1integrationMapping.getpicklistlabel(TR1__Master_Skill__c.TR1__Type__c.getDescribe(),rec.TR1__Type__c);
            name = rec.TR1__Master_Skill_Name__c;
        }
    }
    public class Job_Opportunity_Variables_Input 
    {
        public list<TKSkill> TKSkills{get;set;}
        public List<geographicalRegionsCls> geographicalRegions{get;set;}
        public String overview {get;set;}
        public string shortDescription{get;set;}
        public String responsibilities {get;set;}
        public String requirements {get;set;}
        public String title  {get;set;}
        public String externalJobId {get;set;}
        public String sfdcExternalID {get;set;}
        public String organization {get;set;}
        public Integer requiredPositions {get;set;}
        public String startDate {get;set;}
        public String jobCreationDate {get;set;}
       
        //public customerOwnerCls customerOwner{get;set;}
        public customerOwnerCls torcOwner{get;set;}
        public JobRate maxRate {get;set;}
        public JobRate minRate {get;set;}
        public JobRate minSalary {get;set;}
        public JobRate maxSalary {get;set;}
        public String jobTypeId {get;set;}
        public String externalJobType {get;set;}
        public String timeCommitment {get;set;}
        public integer timeOverlap {get;set;}
        public Integer jobLengthInWeeks {get;set;}
        public Integer jobLength {get;set;}
        public Integer requiredExperience{get;set;}
        public String status {get;set;}
        public String workMode {get;set;}
        public timeZonecls timezone {get;set;}
        public String visibilityLevel {get;set;}
        public String priorityLevel {get;set;}
        public string employmentType{get;set;}
        public string source{get;set;}
        public String id {get;set;}
        public string metadata{get;set;}
        public Job_Opportunity_Variables_Input() 
        {    
            //torcRD1integrationMapping.filldata(rdJob,this, null, null,true,tu);
        }
    }
    public class metadataCls
    {
        public string BULLHORN{get;set;}
    }
    public class BULLHORNCls
    {
        public string Client_Company{get;set;}
        public string Internal_Notes{get;set;}
        public string end_client{get;set;}
    }
    public class customerOwnerCls
    {
        public string id{get;set;}
        public string username{get;set;}
        public customerOwnerCls(torc_user__c tu)
        {
            id=tu.external_id__c;
            username = tu.username__c;
        }
    }
    public class timeZonecls
    {
        public string label{get;set;}
        public string value{get;set;}
        public timeZonecls(string l, string v)
        {
            label=l;
            value=v;
        }
    }
    public class JobRate 
    {
        public String currency_x;
        public Decimal value;
        public JobRate(Decimal rate) 
        {
            this.currency_x = 'USD';
            this.value = rate;
        }
    }

    /*************************** JOB RESPONSE *************************************/
    // If more fields are added in response they should be 
    public class PlatformJob_Response 
    {
        public String id;
    }

    public class PlatformCreateJobOpportunity_ResponseData 
    {
        //public PlatformJob_Response createJobOpportunity;
        //public PlatformJob_Response updateJobOpportunity;
        public PlatformJob_Response submitJobRequest;
        public PlatformJob_Response submitJobUpdate;
    }

    public class Platform_JobResponse 
    {
        public PlatformCreateJobOpportunity_ResponseData data;
        public List<errorClass> errors;

        public PlatformJob_Response getResponseValues() 
        {
            //if (this.data != null && this.data.createJobOpportunity != null) 
            //    return this.data.createJobOpportunity;
            //if (this.data != null && this.data.updateJobOpportunity != null)
            //    return this.data.updateJobOpportunity;
            if (this.data != null && this.data.submitJobRequest != null)
                return this.data.submitJobRequest;
            if (this.data != null && this.data.submitJobUpdate != null)
                return this.data.submitJobUpdate;
            return null;
        }
        public string getError()
        {
            if(errors==NULL || errors.size()==0) return '';
            return errors[0].message;
        }
    }
    public class errorClass
    {
        public string message{get;set;}
    }
    public class geographicalRegionsCls
    {
        public string regionName{get;set;}
        public List<string> countryNames{get;set;}
        public geographicalRegionsCls(string region,List<string>countries)
        {
            regionName=region;
            countryNames=new List<string>();
            if(countries!=NULL)
            {
                for(string country:countries)
                    countryNames.add(country);
            }
        }
    }
}