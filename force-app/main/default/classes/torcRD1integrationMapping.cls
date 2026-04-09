public class torcRD1integrationMapping
{
    public static boolean isAddressChanged(Tr1__job__c n,Tr1__job__c o)
    {
        system.debug(n.WorkSite_Address__City__s);
        system.debug(n.WorkSite_Address__StateCode__s);
        system.debug(n.WorkSite_Address__CountryCode__s);
        system.debug(o.WorkSite_Address__City__s);
        system.debug(o.WorkSite_Address__StateCode__s);
        system.debug(o.WorkSite_Address__CountryCode__s);
        
        return (n.WorkSite_Address__City__s != o.WorkSite_Address__City__s || n.WorkSite_Address__StateCode__s != o.WorkSite_Address__StateCode__s || n.WorkSite_Address__CountryCode__s != o.WorkSite_Address__CountryCode__s);
    }
    public class mappingClass
    {
        public map<string,string> rd1ToTorc;
        public map<string,string> TorcTord1;
        public mappingClass()
        {
            rd1ToTorc = new map<string,string>();
            TorcTord1 = new map<string,string>();
        }
        public void add(string rd1,string torc)
        {
            rd1ToTorc.put(rd1,torc);
            TorcTord1.put(torc,rd1);
        }
        public string getRdValue(string torcval)
        {
            if(torcval=='' || torcval==NULL) return null;
            return TorcTord1.get(torcval);
        }
        public string getTorcValue(string rd1)
        {
            if(rd1=='' || rd1==NULL) return null;
            return rd1ToTorc.get(rd1);
        }
    }
    public static mappingClass getSkillsMap()
    {
        mappingClass m=new mappingClass();
        m.add('IT_Skill','IT');
        m.add('Language_Skill','Language');
        m.add('Professional_Skill','Soft');
        m.add('Competency','Professional');
        
        m.add('Certification','Certification'); 
        m.add('Language','Language'); 
        m.add('Professional','Professional'); 
        m.add('IT','IT'); 
        m.add('Soft','Soft'); 

        
               
        return m;
    }
    public static mappingClass getemploymentMap()
    {
        mappingClass m=new mappingClass();
        m.add('Contract','IC');
        m.add('Contract','CONTRACT');
        m.add('GDC Staffing','DTCPERMPLACEMENT');
        m.add('GDC Solutions','DTCSOLUTION');
        m.add('DTC Staffing','DTCPERMPLACEMENT');
        m.add('DTC Solutions','DTCSOLUTION');
        m.add('Permanent','PERMPLACEMENT');
        m.add('Contract to Perm','CONTRACTTOPERM');
        m.add('Solutions','SOLUTION');
        return m;
    }
    public static string getTorcJobStatusByRdStatus(string status, string closedreason)
    {
        return status =='Accepting Candidates'?'ACTIVE':
                   status =='Unqualified'?'PENDINGAPPROVAL':
                   (status =='Placed' || status=='Covered')?'FULFILLED':
                   (status =='On Hold' || status=='Declined')?'CANCELLED':
                   status =='Archive'?'RDHISTORY':
                   (status =='Closed' && closedreason=='Filled')?'FULFILLED':'CANCELLED';
    }
    public static mappingClass getJobStatusmapping()
    {
        mappingClass m=new mappingClass();
        /*m.add('Accepting Candidates','ACTIVE');
        m.add('Closed','CANCELLED');
        m.add('Closed','DELETED');
        m.add('Unqualified','DRAFT');
        m.add('Placed','FULFILLED');
        m.add('Covered','FULFILLED');
        m.add('Closed','NONSTRIKEZONE');
        m.add('Unqualified','PENDINGAPPROVAL');
        m.add('Closed','RDFULFILLED');
        m.add('Archive','RDHISTORY');
        m.add('On Hold','CANCELLED');
        m.add('Declined','CANCELLED');*/
        
        m.add('Accepting Candidates','ACTIVE');
        m.add('Closed','CANCELLED');
        m.add('Unqualified','DRAFT');
        m.add('Placed','FULFILLED');
        m.add('Covered','FULFILLED');
        m.add('Unqualified','PENDINGAPPROVAL');
        m.add('Archive','RDHISTORY');
        m.add('On Hold','CANCELLED');
        m.add('Declined','CANCELLED');
        
        return m;
    }
    public static mappingClass getworkModemapping()
    {
        mappingClass m=new mappingClass();
        m.add('Partial','HYBRID');
        m.add('None','OFFICE');
        m.add('Unknown','OFFICE');
        m.add('100%','REMOTE');
        return m;
    }
    public static mappingClass gettimeOverlap()
    {
        mappingClass m=new mappingClass();
        m.add('No restriction','-1');
        m.add('2 hours','2');
        m.add('4 hours','4');
        m.add('All hours','8');
        
        return m;
    }
    public static string getpicklistlabel(Schema.DescribeFieldResult fieldResult, string apiValue)
    {
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        String label;
        for (Schema.PicklistEntry entry : picklistValues) 
        {
            if (entry.getValue() == apiValue) 
            {
                label = entry.getLabel();
                break;
            }
        }
        return label;
    }
    public static Map<string,string> torcJobTypeMap=NULL;
    public static void filltorcJobTypeMap()
    {
        torcJobTypeMap=new Map<string,string>();
        for(Torc_Job_Type__c rec:[Select External_Id__c,Name from Torc_Job_Type__c where Delete_From_Platform__c=false])
        {
            torcJobTypeMap.put(rec.Name,rec.External_Id__c);
            
        }
    }        
    public static void filldata(TR1__Job__c rdJob, RD1ToTorc_Job.Job_Opportunity_Variables_Input platformJob, RD1ToTorc_Job.Job_Opportunity_Variables_Extended_Input extInput, Torc_user__c tu)
    {
        mappingClass jobMap=getJobStatusmapping();
        mappingClass workModeMap=getworkModemapping();
        mappingClass timeOverlapMap=gettimeOverlap();
        mappingClass employeementMap=getemploymentMap();
        mappingClass skillsMap = getSkillsMap();
        if(rdJob.Torc_Job_Type__c!=NULL)
        {
            if(torcJobTypeMap==NULL)filltorcJobTypeMap();
                platformJob.jobTypeId = torcJobTypeMap.get(rdJob.Torc_Job_Type__c);
        }
        else
            platformJob.jobTypeId = '46b0759a-c718-40e6-b219-e5a7cb796fee'; //rdJob.Job_Type_ID__c;
        platformJob.visibilityLevel = 'PUBLIC';//'LIMITED'; 
        
        boolean haveSkills=false;
        for(TR1__Skills__c sk:rdJob.TR1__Skills__r)
        {
            if(sk.TR1__Skill_Code__c!=NULL && sk.TR1__Skill_Code__c!='' && sk.TR1__Type__c!=NULL && sk.TR1__Master_Skill_Name__c!=NULL && sk.TR1__Master_Skill_Name__c!='')
            {
                haveSkills=true;
                break;
            }    
        }
        if(haveSkills)
        {
            platformJob.TKSkills =new List< RD1ToTorc_Job.TKSkill>();
            for(TR1__Skills__c sk:rdJob.TR1__Skills__r)
            {
                if(sk.TR1__Skill_Code__c!=NULL && sk.TR1__Skill_Code__c!='' && sk.TR1__Type__c!=NULL && sk.TR1__Master_Skill_Name__c!=NULL && sk.TR1__Master_Skill_Name__c!='')
                    platformJob.TKSkills.add(new RD1ToTorc_Job.TKSkill(sk));
            }    
        }
        
        if(tu!=NULL)
            platformJob.torcOwner =new RD1ToTorc_Job.customerOwnerCls(tu);
        platformJob.workMode = workModeMap.getTorcValue(rdJob.Remote_Work_Mode__c);
        platformJob.status =  getTorcJobStatusByRdStatus(rdJob.TR1__Status__c,rdJob.TR1__Closed_Reason__c);
        //   jobMap.getTorcValue(rdJob.TR1__Status__c);    
        if(rdJob.Primary_Timezone__c!=null)
        {
            string plabel = getpicklistlabel(TR1__Job__c.Primary_Timezone__c.getDescribe(),rdJob.Primary_Timezone__c);
            platformJob.timezone  = new RD1ToTorc_Job.timeZonecls(plabel,rdJob.Primary_Timezone__c);
        }    
        string s=timeOverlapMap.getTorcValue(rdJob.timeOverlap__c);
        if(s!=NULL)
            platformJob.timeOverlap = integer.valueOf(s);
        
        system.debug(rdjob.Employment__c);
        system.debug(rdjob.Job_Type__c);
        
        if(rdjob.Employment__c!=NULL)
            platformJob.employmentType = employeementMap.getTorcValue(rdjob.Employment__c); 
        else if(rdJob.Job_Type__c!=NULL)
            platformJob.employmentType = employeementMap.getTorcValue(rdjob.Job_Type__c);        
        
        system.debug('========================='+platformJob.employmentType);
        system.debug(rdjob.Employment__c+'=='+rdjob.Job_Type__c+'====='+platformJob.employmentType);
        //platformJob.organization = rdJob.TR1__Account_Name__c;
        platformJob.organization = rdJob.Torc_Organization__c;
        
        platformJob.id = rdJob.Torc_Id__c;   
        //platformJob.externalJobId = rdJob.Id;
        platformJob.sfdcExternalID = rdJob.Id;
        platformJob.externalJobId = rdJob.TR1__Job_Number__c;
        platformJob.overview = rdJob.TR1__Client_Job_Description__c;
        platformJob.requirements = rdJob.TR1__Experience_Requirements__c ;
        platformJob.responsibilities = rdJob.TR1__Responsibilities__c;
        platformJob.requiredPositions = rdJob.TR1__Number_of_Openings__c==NULL?1:Integer.valueOf(rdJob.TR1__Number_of_Openings__c);
        //platformJob.title = rdJob.TR1__Job_Title__c;
        platformJob.title = rdJob.Name;
        platformJob.shortDescription = rdJob.TR1__Client_Job_Description__c==NULL?'':rdJob.TR1__Client_Job_Description__c.left(250);
        //platformJob.source = 'SFDC';
        platformJob.requiredExperience=INTEGER.valueof(rdjob.TR1__Years_of_Experience__c);
        platformJob.priorityLevel = rdJob.Job_priority__c;
        
        boolean setPayRate=(rdJob.TR1__Maximum_Pay_Rate__c==NULL && 
                            rdJob.TR1__Minimum_Pay_Rate__c==NULL && 
                            rdJob.TR1__Salary_High__c==NULL && 
                            rdJob.TR1__Salary_Low__c==NULL);
        if(rdJob.TR1__Maximum_Pay_Rate__c!=NULL || rdJob.TR1__Minimum_Pay_Rate__c!=NULL ||setPayRate)
        {
            platformJob.maxRate = new RD1ToTorc_Job.JobRate(rdJob.TR1__Maximum_Pay_Rate__c==NULL?0:rdJob.TR1__Maximum_Pay_Rate__c);
            platformJob.maxRate.currency_x = rdJob.CurrencyISOCode;
            platformJob.minRate = new RD1ToTorc_Job.JobRate(rdJob.TR1__Minimum_Pay_Rate__c==NULL?0:rdJob.TR1__Minimum_Pay_Rate__c); 
            platformJob.minRate.currency_x = rdJob.CurrencyISOCode;
        }
        if(rdJob.TR1__Salary_High__c!=NULL || rdJob.TR1__Salary_Low__c!=NULL)
        {   
            platformJob.maxSalary = new RD1ToTorc_Job.JobRate(rdJob.TR1__Salary_High__c==NULL?0:rdJob.TR1__Salary_High__c);
            platformJob.maxSalary.currency_x = rdJob.CurrencyISOCode;
            platformJob.minSalary = new RD1ToTorc_Job.JobRate(rdJob.TR1__Salary_Low__c==NULL?NULL:rdJob.TR1__Salary_Low__c);     
            platformJob.minSalary.currency_x = rdJob.CurrencyISOCode;
        }    

            
        platformJob.jobCreationDate =  rdJob.createdDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', 'GMT');   
        if (rdJob.TR1__Estimated_Start_Date__c != null) 
        {
            Date dt = rdJob.TR1__Estimated_Start_Date__c;
            platformJob.startDate = DateTime.newInstance(dt.year(),dt.month(), dt.day()).format('yyyy-MM-dd');
        }
        if (rdJob.TR1__Estimated_End_Date__c != null && rdJob.TR1__Estimated_Start_Date__c!=NULL) 
        {
            Integer days = rdJob.TR1__Estimated_Start_Date__c.daysBetween(rdJob.TR1__Estimated_End_Date__c)+1;
            platformJob.jobLengthInWeeks = Integer.valueOf(days / 7);
            platformJob.jobLength = days;
        }
        if(rdJob.Workregime__c!=NULL)
            platformJob.timeCommitment = rdJob.Workregime__c=='100%'?'FULLTIME':'PARTTIME';
                
        RD1ToTorc_Job.BULLHORNCls BULLHORNstr= new RD1ToTorc_Job.BULLHORNCls(); 
        BULLHORNstr.Client_Company = rdJob.TR1__Account_Name__c;
        BULLHORNstr.Internal_Notes = rdJob.Internal_Notes_Long__c;
        BULLHORNstr.end_Client = rdJob.end_client_name__c;

        RD1ToTorc_Job.metaDatacls metaC= new RD1ToTorc_Job.metaDatacls(); 
        metaC.BULLHORN = JSON.serialize(BULLHORNstr, true).replace('"Client_Company"','"Client_Company__c"').replace('"Internal_Notes"','"Internal_Notes__c"');
        //metaC.BULLHORN = JSON.serialize(BULLHORNstr, true);
        platformJob.metadata = JSON.serialize(metaC, true);
        
        extInput.address = new RD1ToTorc_Job.Job_Address_Input('','','');
        platformJob.geographicalRegions = new List< RD1ToTorc_Job.geographicalRegionsCls>();
        if(rdJob.Torc_Location_Type__c=='Region/Country' || rdJob.Torc_Location_Type__c==NULL)
        {
            Map<string,List<string>>allregions = new Map<string,List<string>>();
            if(rdJob.Torc_Location_Type__c=='Region/Country' && (rdJob.Developer_Region__c!=NULL || rdJob.Developer_Countries__c!=NULL))
            {    
                if(rdJob.Developer_Region__c!=NULL)
                {
                    for(string str:rdJob.Developer_Region__c.split(';'))
                    {
                        allregions.put(str.trim(),null);
                    }
                }
                if(rdJob.Developer_Countries__c!=NULL)
                {
                    for(string str:rdJob.Developer_Countries__c.split(';'))
                    {
                        List<string>spl=str.split('-');
                        if(allregions.keyset().contains(spl[1].trim()) && allregions.get(spl[1].trim())==NULL)
                            continue;
                        if(allregions.get(spl[1].trim())==NULL)
                                allregions.put(spl[1].trim(),new List<string>());
                        allregions.get(spl[1].trim()).add(spl[0].trim());
                    }
                }
            }
            else
            {
                for(string str:('LATAM;Africa;Asia & Pacific;Europe;Middle East;US & Canada').split(';'))
                {
                    allregions.put(str.trim(),null);
                }
            }
            platformJob.geographicalRegions = new List< RD1ToTorc_Job.geographicalRegionsCls>();
            for(string str:allregions.keyset())
            {
                platformJob.geographicalRegions.add(new RD1ToTorc_Job.geographicalRegionsCls(str,allregions.get(str)));
            }
            system.debug(platformJob.geographicalRegions);
        }
        else if(rdJob.Torc_Location_Type__c=='City')
        {
            extInput.address = new RD1ToTorc_Job.Job_Address_Input(rdJob.Torc_Search_Country__c,rdJob.Torc_Search_State__c,rdJob.Torc_Search_City__c);    
        }
        else if(rdJob.Torc_Location_Type__c=='Worksite Address')
        {
            string city = rdJob.WorkSite_Address__City__s==NULL?'':rdJob.WorkSite_Address__City__s;
            string state = rdJob.WorkSite_Address__StateCode__s==NULL?'':rdJob.Worksite_Address__c.getState();
            string country = rdJob.WorkSite_Address__CountryCode__s==NULL?'':rdJob.Worksite_Address__c.getCountry();
            extInput.address = new RD1ToTorc_Job.Job_Address_Input(country,state, city);    
        }
        system.debug(extInput.address);
            
        /*else
        {        
            rdJob.Remote_Work_Mode__c = workModeMap.getRDValue(JunctionJob.workMode__c);
            rdJob.TR1__Status__c = jobMap.getRDValue(JunctionJob.Status__c);    
            if(JunctionJob.timeZone__c!=null)
            {
                //string plabel = getpicklistlabel(TR1__Job__c.Primary_Timezone__c.getDescribe(),rdJob.Primary_Timezone__c);
                //platformJob.timezone  = new RD1ToTorc_Job.timeZonecls(plabel,rdJob.Primary_Timezone__c);
                rdJob.Primary_Timezone__c = JunctionJob.timeZone__c;
            }    
            if(JunctionJob.timeOverlap__c!=NULL)
            {
                string s=timeOverlapMap.getRDValue(JunctionJob.timeOverlap__c.toString());
                rdJob.timeOverlap__c = s;
            }        
            if(JunctionJob.employmentType__c!=NULL)
                rdjob.Employment__c = employeementMap.getRDValue(JunctionJob.employmentType__c);    
            
            rdJob.TR1__Client_Job_Description__c = JunctionJob.overview__c;
            rdJob.TR1__Experience_Requirements__c = JunctionJob.requirements__c;
            rdJob.TR1__Responsibilities__c = JunctionJob.responsibilities__c;
            rdJob.TR1__Number_of_Openings__c=JunctionJob.requiredPositions__c;
            rdJob.TR1__Job_Title__c = JunctionJob.title__c;
            
            rdJob.TR1__Client_Job_Description__c = JunctionJob.shortDescription__c;
            //rdjob.Source__c=JunctionJob.source__c;
            //rdjob.TR1__Years_of_Experience__c = JunctionJob.requiredExperience__c;
            rdJob.Job_priority__c = JunctionJob.priorityLevel__c;

            rdJob.TR1__Maximum_Pay_Rate__c = JunctionJob.maxRate__c;
            rdJob.TR1__Minimum_Pay_Rate__c = JunctionJob.minRate__c;
            
            rdJob.TR1__Salary_High__c = JunctionJob.maxSalary__c;
            rdJob.TR1__Salary_Low__c = JunctionJob.minSalary__c;
            if(JunctionJob.startDate__c!=NULL)
            {
                rdJob.TR1__Estimated_Start_Date__c     = JunctionJob.startDate__c;
                if(JunctionJob.jobLength__c!=NULL)
                    rdJob.TR1__Estimated_End_Date__c= JunctionJob.startDate__c + integer.valueOf(JunctionJob.jobLength__c)-1;
            }                
        } */   
    }
    
    
    
    
    
    //----------USER--------------------------------------------------------------
    /*public static mappingClass getcandidateStatusMap()
    {
        mappingClass m=new mappingClass();

        m.add('Collaborator','ACTIVE');
        m.add('New','ACTIVE');
        m.add('Passive','ACTIVE');
        m.add('Active','ACTIVE');
        m.add('Do not use','SUSPENDED');
        m.add('Do not use','INACTIVE');
        return m;
    }*/
    public static void filldataTorcToRD1Contact(Contact rdCandidate,Torc_User__c Junctioncandidate,Torc_User__c JunctionCandidateOld,List<TR1__EmploymentHistory__c>lstEmployeement)
    {
        //mappingClass candidateStatusMap=getcandidateStatusMap();
        if(JunctionCandidateOld==NULL || Junctioncandidate.status__c!=JunctionCandidateOld.status__c || rdCandidate.id==NULL)
        {
            //rdCandidate.TR1__Candidate_Status__c =candidateStatusMap.getRDvalue(Junctioncandidate.status__c);
            rdCandidate.DO_Not_use__c = !(Junctioncandidate.status__c=='ACTIVE');
        }
        
        rdCandidate.Mktg_Contact_OK__c = Junctioncandidate.agreedToMarketing__c?'Yes':'No';
        
        if(Junctioncandidate.given_name__c!='NoFirstName')
            rdCandidate.FirstName = Junctioncandidate.given_name__c;                
        
        rdCandidate.LastName = Junctioncandidate.family_name__c==NULL?'NoLastName' : Junctioncandidate.family_name__c;
        if(rdCandidate.id==NULL)
        {
            rdCandidate.email = Junctioncandidate.email__c;
            rdCandidate.Is_Index_to_Textkernel__c = true;
            rdCandidate.Employee_Type__c ='Unknown';
            rdCandidate.Line_of_Business__c ='RD';
        }    
        rdCandidate.torc_user__c = Junctioncandidate.userName__c;
        if(Junctioncandidate.linkedin__c!=NULL)
            rdCandidate.TR1__LinkedIn_ProfileUrl__c = 'https://www.linkedin.com/in/' + Junctioncandidate.linkedin__c;
        else
            rdCandidate.TR1__LinkedIn_ProfileUrl__c = null;  
        //rdCandidate.Torc_Candidate_Status__c = Junctioncandidate.status__c;
        
        if(Junctioncandidate.noticePeriod__c==0 || Junctioncandidate.noticePeriod__c==15 || Junctioncandidate.noticePeriod__c==30 || Junctioncandidate.noticePeriod__c==60 ||    Junctioncandidate.noticePeriod__c==90)
            rdCandidate.TR1__Notice_Period__c =  string.valueOf(Junctioncandidate.noticePeriod__c);
        else if(Junctioncandidate.noticePeriod__c!=null)
        {
            rdCandidate.TR1__Notice_Period__c =  'Other';
            rdCandidate.Notice_Period__c =  Junctioncandidate.noticePeriod__c;
        }  
        rdCandidate.Whatsapp_Allowed__c = Junctioncandidate.WhatsAppAllowed__c;
        if(Junctioncandidate.Phone__c!=NULL)
        {
            string pn = Junctioncandidate.Phone__c.replace('-','').replace(' ','').replace('(','').replace(')','');
            if(isPhonenumberValid(pn))
                rdCandidate.MobilePhone = pn;
        }    
        if(Junctioncandidate.ratePerHour__c!=NULL)
        {
            //rdCandidate.TR1__Desired_Hourly__c =Junctioncandidate.ratePerHour__c;
            rdCandidate.Desired_day_rate__c=Junctioncandidate.ratePerHour__c*8;
        }    
        if(Junctioncandidate.salary__c!=NULL)
        {
            rdCandidate.TR1__Desired_Salary__c =Junctioncandidate.salary__c;            
        }    
        rdCandidate.Years_of_experience__c=Junctioncandidate.overallExperience__c;    
        if(Junctioncandidate.sfdcExternalID__c == NULL)
        {
            rdCandidate.Source_Type__c = 'Torc';
            rdCandidate.CurrencyISOCode = 'USD'; 
        }    
        /*            
        if(junctionCandidate.Job_History_JSON__c!=NULL && (rdCandidate.id==NULL || JunctionCandidateOld==NULL || (JunctionCandidateOld!=NULL && junctionCandidate.Job_History_JSON__c!=junctionCandidateOld.Job_History_JSON__c)))
        {
            JSONParser jp = JSON.createParser(junctionCandidate.Job_History_JSON__c);
            AWSDataLoad.AWSresumeWorkHistoryL Jobhist =(AWSDataLoad.AWSresumeWorkHistoryL)jp.readValueAs(AWSDataLoad.AWSresumeWorkHistoryL.class);
            system.debug(Jobhist);
            if(Jobhist!=NULL && Jobhist.L!=NULL)
            {
                for(AWSDataLoad.AWSresumeWorkHistoryM jobM:Jobhist.L)
                {
                    system.debug(jobM);
                    AWSDataLoad.AWSresumeWorkHistory jobH = jobM.M;
                    system.debug(jobH);
                    TR1__EmploymentHistory__c eHist=new TR1__EmploymentHistory__c();  
                    eHist.Torc_Id__c = jobH.id.S;
                    eHist.TR1__StartDate__c = jobH.startDate!=NULL && jobH.startdate.S!=NULL?jobH.startDate.S.left(10):'';
                    eHist.TR1__EndDate__c = jobH.enddate!=NULL && jobH.enddate.S!=NULL?jobH.enddate.S.left(10):'';
                    eHist.TR1__Title__c = jobH.title!=NULL?jobH.title.S:'';
                    eHist.TR1__Description__c = jobH.Description!=NULL?jobH.Description.S:'';   
                    eHist.TR1__EmployerName__c = jobH.companyName!=NULL?jobH.companyName.S:'';   
                    eHist.TR1__Contact__r=new Contact(Torc_Id__c=rdCandidate.Torc_Id__c);
                    lstEmployeement.add(eHist);
                }   
            } 
        }*/
    }

    public static void filldataToTorc(Contact rdCandidate, RD1ToTorc_User.PlatformTorcUser_Variables_Input platformUser,contentVersion resume)
    {
        //mappingClass candidateStatusMap=getcandidateStatusMap();
        if (resume != null && resume.resume_from_Torc__c==FALSE) 
        {
            platformUser.base64Resume  = EncodingUtil.base64Encode(resume.VersionData);
            platformUser.resumeFileName = resume.Title + '.' + resume.FileExtension;
        }
        platformUser.status = rdCandidate.DO_Not_use__c?'INACTIVE':'ACTIVE';
        boolean haveSkills=false;
        for(ATSExtractedCandidateSkill__c sk:rdCandidate.ATSExtractedCandidateSkills__r)
        {
            haveSkills=true;
            break;
        }
        if(haveSkills)
        {
            platformUser.skillsNames=new List<string>();
            for(ATSExtractedCandidateSkill__c sk:rdCandidate.ATSExtractedCandidateSkills__r)
                platformUser.skillsNames.add(sk.Extracted_Skill__c);
        }
        
        platformUser.bullhornStatus = rdCandidate.TR1__Candidate_Status__c;
        string userCreateddate = (rdCandidate.BH_Original_added_date__c!=NULL?
                                                Datetime.NewInstance(rdCandidate.BH_Original_added_date__c.year(),rdCandidate.BH_Original_added_date__c.Month(),rdCandidate.BH_Original_added_date__c.day())
                                                :rdCandidate.createdDate).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', 'GMT');   
        if(rdCandidate.torc_id__c==NULL)
            platformUser.userCreationDate =  userCreateddate;
        
        
        if(rdCandidate.Responsible_Opco__c!=NULL && rdCandidate.Responsible_Opco__c!='')
        {
            RD1ToTorc_User.BULLHORNCls BULLHORNstr= new RD1ToTorc_User.BULLHORNCls(); 
            BULLHORNstr.opco = rdCandidate.Responsible_Opco__c;
            //BULLHORNstr.Created_At = userCreateddate;
            RD1ToTorc_User.metaDatacls metaC= new RD1ToTorc_User.metaDatacls(); 
            metaC.BULLHORN = JSON.serialize(BULLHORNstr, true);
            platformUser.metadata = JSON.serialize(metaC, true);
        }
        
        
       
        
        
        //if(rdCandidate.TR1__Candidate_Status__c!=NULL)
        //    platformUser.status = candidateStatusMap.getTorcvalue(rdCandidate.TR1__Candidate_Status__c);
            //if(rdCandidate.torc_id__c==NULL)
            {
                platformUser.sfdcExternalID = rdCandidate.id;
                platformUser.given_name = (rdCandidate.FirstName==NULL||rdCandidate.FirstName=='')?'NoFirstName':rdCandidate.FirstName;
                platformUser.family_name = rdCandidate.LastName;
                platformUser.identity_username = platformUser.generateIdentityUserName(rdCandidate.Torc_Email__c);
                platformUser.userType = 'FREELANCER';
                if(rdCandidate.Mktg_Contact_OK__c!=NULL)
                    platformUser.agreedToMarketing = rdCandidate.Mktg_Contact_OK__c=='Yes';
                
                if(rdCandidate.Torc_Country__c!=NULL && rdCandidate.Torc_State__c!=NULL && rdCandidate.Torc_City__c!=NULL)
                {
                    platformUser.address = new RD1ToTorc_User.cls_Address();
                    platformUser.address.country = rdCandidate.Torc_Country__c;  
                    platformUser.address.state = rdCandidate.Torc_State__c;  
                    platformUser.address.city = rdCandidate.Torc_City__c;  
                }    
                if(rdCandidate.TR1__Notice_Period__c!=NULL && rdCandidate.TR1__Notice_Period__c!='Other')
                    platformUser.noticePeriod = Integer.valueOf(rdCandidate.TR1__Notice_Period__c);  
                else if(rdCandidate.TR1__Notice_Period__c=='Other' && rdCandidate.Notice_Period__c !=NULL)    
                    platformUser.noticePeriod = Integer.valueOf(rdCandidate.Notice_Period__c);  
                if(rdCandidate.MobilePhone!=NULL)
                    platformUser.phone = new RD1ToTorc_User.Phonecls(rdCandidate.MobilePhone, rdCandidate.Whatsapp_Allowed__c);  
                
                //platformUser.ratePerHour = new RD1ToTorc_Job.JobRate(rdCandidate.TR1__Desired_Hourly__c!=NULL?rdCandidate.TR1__Desired_Hourly__c:null);  
                platformUser.ratePerHour = new RD1ToTorc_Job.JobRate(rdCandidate.Desired_day_rate__c!=NULL?rdCandidate.Desired_day_rate__c/8:null);  
               
                platformUser.ratePerHour.currency_x = rdCandidate.CurrencyISOCode;      

                platformUser.salary = new RD1ToTorc_Job.JobRate(rdCandidate.TR1__Desired_Salary__c!=NULL?rdCandidate.TR1__Desired_Salary__c:null);        
                platformUser.salary.currency_x = rdCandidate.CurrencyISOCode;      

                if(rdCandidate.Years_of_experience__c!=NULL)    
                    platformUser.overallExperience = integer.valueOf(rdCandidate.Years_of_experience__c);      
                if(rdCandidate.Availability_date__c!=NULL) 
                {
                    date dt = rdCandidate.Availability_date__c;           
                    platformUser.nextAvailableDate = DateTime.newInstance(dt.year(),dt.month(), dt.day()).format('yyyy-MM-dd')+'T00:00:00.000Z';
                }   
                platformUser.socialLinks=new List<RD1ToTorc_User.socialLinksCls>();
                if(rdCandidate.TR1__LinkedIn_ProfileUrl__c!=NULL)
                {
                    RD1ToTorc_User.socialLinksCls r1=new RD1ToTorc_User.socialLinksCls();
                    r1.type='LINKEDIN';
                    r1.value=rdCandidate.TR1__LinkedIn_ProfileUrl__c;
                    platformUser.socialLinks.add(r1);
                }
            }   
    }
    public static void filldata(TR1__Application_V2__c rdApplication, Torc_Match_Shadow__c Junctionmatch, Torc_Match_Shadow__c JunctionmatchOld, boolean RDToTorc,List<recordtype> lstRecordtypes,string jobRecordtype)
    {
        rdApplication.Torc_Stage__c = Junctionmatch.Delete_From_Platform__c?'DELETED':Junctionmatch.status__c;
        rdApplication.Torc_rejectionreason__c = Junctionmatch.reasonForRejection__c;
        rdApplication.Torc_freelancerPitch__c = Junctionmatch.freelancerPitch__c;
        //if(rdApplication.Status__c==NULL)
        //    rdApplication.Status__c = 'Submitted';
        
        if(rdApplication.Torc_Stage__c=='REJECTEDBYCUSTOMER' || rdApplication.Torc_Stage__c=='REJECTEDBYMEMBER' || rdApplication.Torc_Stage__c=='REJECTEDBYMATCHER')
        {
            if(!rdApplication.TR1__Reject__c)
            {
                rdApplication.TR1__Reject__c = true;
                rdApplication.Rejection_root__c = rdApplication.Torc_Stage__c=='REJECTEDBYCUSTOMER'?'Client':(rdApplication.Torc_Stage__c=='REJECTEDBYMEMBER'?'Candidate': 'Randstad');
                //rdApplication.TR1__Rejection_Origin__c = rdApplication.Torc_Stage__c=='REJECTEDBYCUSTOMER'?'Client':(rdApplication.Torc_Stage__c=='REJECTEDBYMEMBER'?'Candidate': 'Internal');
                rdApplication.TR1__Rejection_Reason__c = 'Rejected From Torc';            
            }    
        }
        
        if(rdApplication.id==NULL)
        {
            rdApplication.Source__c = 'Torc Match';
            for(recordType rt:lstRecordtypes)
                if(rt.Name==jobRecordtype)
                    rdApplication.RecordTypeId = rt.id;
        }
    }
    
/*    
    public static void filldata(TR1__Application_V2__c rdApplication, Torc_Match__c Junctionmatch,Torc_Match__c JunctionmatchOld, boolean RDToTorc,List<recordtype> lstRecordtypes,string jobRecordtype)
    {
        rdApplication.Torc_Stage__c = Junctionmatch.Delete_From_Platform__c?'DELETED':Junctionmatch.status__c;
        rdApplication.Torc_rejectionreason__c = Junctionmatch.reasonForRejection__c;
        rdApplication.Torc_freelancerPitch__c = Junctionmatch.freelancerPitch__c;
        //if(rdApplication.Status__c==NULL)
        //    rdApplication.Status__c = 'Submitted';
        
        if(rdApplication.Torc_Stage__c=='REJECTEDBYCUSTOMER' || rdApplication.Torc_Stage__c=='REJECTEDBYMEMBER' || rdApplication.Torc_Stage__c=='REJECTEDBYMATCHER')
        {
            if(!rdApplication.TR1__Reject__c)
            {
                rdApplication.TR1__Reject__c = true;
                rdApplication.Rejection_root__c = rdApplication.Torc_Stage__c=='REJECTEDBYCUSTOMER'?'Client':(rdApplication.Torc_Stage__c=='REJECTEDBYMEMBER'?'Candidate': 'Randstad');
                //rdApplication.TR1__Rejection_Origin__c = rdApplication.Torc_Stage__c=='REJECTEDBYCUSTOMER'?'Client':(rdApplication.Torc_Stage__c=='REJECTEDBYMEMBER'?'Candidate': 'Internal');
                rdApplication.TR1__Rejection_Reason__c = 'Rejected From Torc';            
            }    
        }
        
        if(rdApplication.id==NULL)
        {
            rdApplication.Source__c = 'Torc Match';
            for(recordType rt:lstRecordtypes)
                if(rt.Name==jobRecordtype)
                    rdApplication.RecordTypeId = rt.id;
        }
    }
*/    
    public static boolean isPhonenumberValid(string phone)
    {
        String regexPattern = '(([+][(]?[0-9]{1,3}[)]?)|([(]?[0-9]{4}[)]?))\\s*[)]?[-\\s\\.]?[(]?[0-9]{1,3}[)]?([-\\s\\.]?[0-9]{3})([-\\s\\.]?[0-9]{3,4})';
        return Pattern.matches(regexPattern, phone);
    }
    //------------
    public static void filldata(RD1ToTorc_Notes.Note_Variable_Input inp, Task Rdnote,contact con,TR1__Job__c job)
    {
        inp.content = rdNote.Description;
        inp.externalid=rdNote.id;
        if(con!=NULL)
            inp.userId = con.torc_id__c;
        else if(job!=NULL)
            inp.jobOpportunityId= job.torc_id__c;    
        inp.isPublic=true;
    }
}