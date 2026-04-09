/*
    STEP1 : Fetch RD1Job Detail. If have Torc Id, Immediately Go to Step 3. If Have BH Job Id. Immediately go to Step 2.
    STEP2 : Find If BHJobId have TorcJob-JobExternalId. Update RD1Job.TorcId. Immediately Go to Step 3.
    STEP3 : Call TorcJob Insert/Update Operation to sync job to torc. Delayed Go to Step 4.
    STEP4 : Wait for All APICalls To Complete. Reload the Rd1 Job and TorcJob. If no Torc Job created yet then Stay in STEP4. If Done Step 5 Immediately.
    STEP5 : Load All Matches Of Job from platform. Deplayed Move to 6 
    STEP6 : Load All Applications of rd1Job. If there is any candidate not in torc. Create them via API and move to delayed step 7. 
            Else Immediately move step 8
    STEP7 : Wait for All APICalls To Complete. Immediately Move to Step 8.
    STEP8 : load All Torc Matches and Find Torcusers not on RD1. mapthem. Immediately Step9
    STEP9 : load Torc Matches and Update them in RD1. Immediately Move to Step 10.
    STEP10 : load RD1 Apps and Update them in Torc. Delayed Move to Step 11
    STEP11 : Wait in this until All API Finishes. Immediately go to step 12.
    STEP12: Close the page and return to Job.
    */
public class torcRd1SyncJob
{
    public TR1__Job__c rd1Job{get;set;}
    public Torc_Job_Opportunity__c torcJob{get;set;}
    public List<Torc_Api_Call__c> lstApiCalls{get;set;}
    Public List<Torc_Match__c> lstMatches{get;set;}
    Public List<tr1__Application_V2__c> lstApplications{get;set;}
    public boolean done{get;set;}
    public boolean errorCome{get;set;}
    public string errorMessage{get;set;}
    public Integer currentStep{get;set;}
    public torcRd1SyncJob(ApexPages.StandardController controller)
    {
        errorCome = false;
        Rows=new list<Row>();
        done=false;
        rd1Job=(TR1__Job__c)controller.getRecord();
        rd1Job=[Select id,name from TR1__Job__c where id=:rd1job.id];
        currentStep = 1;
        lstApiCalls = new List<Torc_Api_Call__c>();
        lstApplications = new List<tr1__Application_V2__c>();
        lstMatches = new List<Torc_Match__c>();
        fillRows();
        
    }
    public void process()
    {
        system.debug('=====STEP====='+currentStep);
        system.debug(rd1Job);
        system.debug(torcJob);
        system.debug(lstApplications);
        system.debug(lstMatches);
        system.debug(lstApiCalls);
        
        IF(currentStep==1)
        {
            getRD1Job();
            if((rd1job.Torc_Id__c!=NULL && rd1job.Torc_Id__c!='') || rd1job.Legacy_BH_Id__c==NULL)
            {
                update rd1job;
                currentStep = 3;
                process();
                return;
            }
            else if(rd1job.Legacy_BH_Id__c!=NULL)
            {
                currentStep = 2;
                process();
                return;
            }
        }
        
        IF(currentStep==2)
        {
            List<Torc_Job_Opportunity__c> lsttorcJob=[Select id, external_Id__c, externalJobId__c from Torc_Job_Opportunity__c where externalJobId__c=:rd1job.Legacy_BH_Id__c.toString() LIMIT 1];
            if(lsttorcJob.size()>0)
            {
                rd1Job.Torc_Id__c = lsttorcJob[0].external_Id__c;
                update rd1Job;
            }
            else 
                update rd1job;
            currentStep = 3;
            process();
            return;
        }
        IF(currentStep ==3)
        {
            initiateJobCreationOrUpdationinTorc();
            currentStep = 4;
            return;
        }
        IF(currentStep ==4)
        {
            if(!doesAllApiComplete())
                return;
            getRd1Job();
            getTorcJob();
            if(torcJob==NULL)
                return;
            currentStep = 5;
            process(); 
            return;   
        }
        IF(currentStep ==5)
        {
            torcRd1Integration.DoNotRunMATCHTOApplication = true;
            AWSDataLoad.updatematchesByJobId(torcJob.External_Id__c);
            torcRd1Integration.DoNotRunMATCHTOApplication = false;
            currentStep = 6;
            return;   
        }
        IF(currentStep==6)
        {
            set<id> candidates = loadAllRD1ApplicationsAndreturnNonTorc();
            if(candidates.size()>0)
            {
                createCandidatesinTorc(candidates);
                currentStep = 7;
                return;
            }
            currentStep = 8;
            process(); 
            return;   
        }
        IF(currentStep ==7)
        {
            if(!doesAllApiComplete())
                return;
            currentStep = 8;
            process(); 
            return;   
        }
        IF(currentStep == 8)
        {
            set<id> tUsers = loadAllTorcMatchesAndreturnNonRD1();
            if(tUsers.size()>0)
            {
                createCanddiatesInRd1(tUsers);
            }
            currentStep = 9;
            process();
            return;
        }
        IF(currentStep == 9)
        {
            moveAllTorcMatchesToRD1();
            currentStep = 10;
            process();
            return;
        }
        IF(currentStep == 10)
        {
            moveAllRd1AppsToTorc();
            currentStep = 11;
            return;
        }
        IF(currentStep == 11)
        {
            if(!doesAllApiComplete())
                return;
            currentStep = 12;
            process(); 
            return;   
        }
        IF(currentStep == 12)
        {
            return;
        }
    }
    public void createCanddiatesInRd1(set<id>torcIdsnotinRd1)
    {
        string soql = 'SELECT '+ torcRD1Integrationbatch.getFieldList('Torc_User__c') +' FROM Torc_User__c Where External_Id__c in:torcIdsnotinRd1';
        List<Torc_User__c> results = Database.query(soql);
        torcRD1Integration.QuickCreateContactByTorcUser(results,null);
    }
    public void getRd1Job()
    {
        rd1Job=[Select id, Torc_Id__c, Legacy_BH_Id__c,name from TR1__Job__c Where id =:rd1Job.Id];
    }
    public void getTorcJob()
    {
        torcJob=null;
        if(rd1Job.Torc_Id__c==NULL)return;
        for(torc_Job_Opportunity__c tjo:[Select id,Name, external_id__c 
                                        from torc_Job_Opportunity__c 
                                        where external_id__c=:rd1Job.torc_id__c AND Delete_from_Platform__c=FALSE LIMIT 1])
        {
            torcJob = tjo;
        }
    }
    public void initiateJobCreationOrUpdationinTorc()
    {
        lstApiCalls.clear();
        Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Job',Job__c=rd1Job.id,Operation__c=(rd1Job.Torc_Id__c==NULL?'INSERT':'UPDATE'));
        rec.Body__c = JSON.serialize(rd1Job);
        lstApiCalls.add(rec);
        doLocalRun();
    }
    integer currentRunCount;
    public void doLocalRun()
    {
        currentRunCount = 0;
        doLocalRunNext();
    }
    public void doLocalRunNext()
    {
        List<torc_API_Call__c> lstlocalApiCalls=new List<torc_API_call__c>();
        for(integer i=0;i<50;i++)
        {
            if(currentRunCount>=lstApiCalls.size())
                break;
            lstlocalApiCalls.add( lstApiCalls[currentRunCount]);   
            currentRunCount++;
        }
        if(lstlocalApiCalls.size()>0)
            torcRD1Integration.runbatch(lstlocalApiCalls);      
    }
    
    public boolean doesAllApiComplete()
    {
        if(currentRunCount<lstApiCalls.size())
        {
            doLocalRunNext();
            return false;
        }
        set<id>idSet = new set<id>();
        for(Torc_API_Call__c r:lstApiCalls)idSet.add(r.id);
        if(idSet.size()==0)return true;
        for(Torc_API_Call__c t:[Select id,Type__c, Is_Error__c, Processed__c 
                                from Torc_API_Call__c 
                                where (Processed__c=FALSE OR Is_Error__c=TRUE) and id in :idSet])
        {
            if(t.Is_Error__c)
            {
                errorCome=true;
                errorMessage = 'Error - '+ t.Type__c+'.('+t.id+').';
            }
            return false;        
        }
        return true;
    }
    public Set<id> loadAllRD1ApplicationsAndreturnNonTorc()
    {
        lstApplications.clear();
        Set<id> nonTorcApp=new set<id>();
        for(tr1__Application_V2__c app:[Select id, TR1__Applicant__c, TR1__Applicant__r.Torc_Id__c from tr1__Application_V2__c where TR1__Job__c =:rd1Job.id])
        {
            lstApplications.add(app);
            if(app.TR1__Applicant__r.Torc_Id__c==NULL)
                nonTorcApp.add(app.TR1__Applicant__c);
        }
        return nonTorcApp;
    }
    public Set<id> loadAllTorcMatchesAndreturnNonRD1()
    {
        lstMatches.clear();
        Set<id> nonRD1App=new set<id>();
        for(Torc_match__c app:[Select id, Torc_User_ref__r.sfdcExternalId__c from Torc_match__c where Torc_Job_Opportunity__c =:torcJob.id])
        {
            lstMatches.add(app);
            if(app.Torc_User_ref__r.sfdcExternalId__c==NULL)
                nonRD1App.add(app.Torc_User_ref__r.sfdcExternalId__c);
        }
        return nonRD1App;
    }
    public void createCandidatesinTorc(set<id>candidates)
    {
        lstApiCalls.clear();
        for(id cId:candidates)
        {
            Torc_API_Call__c rec=new Torc_API_Call__c(type__c='User',Contact__c=cid,Operation__c='INSERT');
            rec.Body__c = JSON.serialize(new Contact(id=cid));
            lstApiCalls.add(rec);
        }    
        doLocalRun();
    }
    public void moveAllTorcMatchesToRD1()
    {
        List<Torc_match_Shadow__c>lst=new List<Torc_match_Shadow__c>();
        for(Torc_match_Shadow__c t:[Select id, sync_Request_Time__c,updater__c from Torc_match_Shadow__c where jobOpportunityId__c =:torcJob.external_Id__c])
        {
            t.sync_Request_Time__c=datetime.Now();
            if(torcRD1Integration.isUpdaterSFDC(t.updater__c)) t.updater__c='updaterdummy';
            lst.add(t);
        }
        if(lst.size()>0)
            update lst;
    }
    public void moveAllRd1AppsToTorc()
    {
        lstApiCalls.clear();
        for(tr1__Application_V2__c lapp:[Select id from tr1__Application_V2__c 
                                        where TR1__Job__c =:rd1Job.id AND Torc_Id_Of_User__c!=NULL And Torc_Id_Of_Job__c!=NULL AND Torc_Stage__c!='DELETED'])
        {
            Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Match',Application__c=lApp.id,Operation__c='INSERT');
            rec.Body__c = JSON.serialize(lapp);
            lstApiCalls.add(rec);
        }
        doLocalRun();
    }
    
    public void processNow() 
    {
        try
        {
            process();
            done = (currentStep >=12);
            updateRows(); 
            if(errorCome)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Processing halted. Please update Job and Save and retry. If error continues then give these details to Admin. : ' + errorMessage));        
        }
        catch(exception ex)
        {
            errorCome = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Processing halted. Please update Job and Save and retry. If error continues then give these details to Admin. : ' + ex.getMessage()));    
        }
    }
    
    /*public void processNow() 
    {
        try
        {
            if (currentStep < 11) 
                currentStep++;
            if(currentStep==5)
            {
                errorCome=true;
                errorMessage = 'There is some issue in the process  Please give this message to Admin.';
            }
            done = (currentStep >=11);
            updateRows(); 
            if(errorCome)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Processing halted. Please update Job and Save and retry. If error continues then give these details to Admin. : ' + errorMessage));        
            }
        }
        catch(exception ex)
        {
            errorCome = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Processing halted. Please update Job and Save and retry. If error continues then give these details to Admin. : ' + ex.getMessage()));    
        }
    }*/
    public list<Row> Rows{get;set;}
    public class Row 
    { 
        public Integer step {get;set;} 
        public String label {get;set;} 
        public String Description {get;set;} 
        public Row(integer s, string d)
        {
            step=s;
            Description=d;
            label='PENDING';
        }
    }
    public void fillRows()
    {
        Rows.add(new Row(1, 'Retrieving RD Job details from the system.'));
        Rows.add(new Row(2, 'Attempting to map RD Job to Torc Job using the Legacy Bullhorn Job ID.'));
        Rows.add(new Row(3, 'Initiating update to the Torc platform with job details.'));
        Rows.add(new Row(4, 'Creating or updating the job in the Torc platform.'));
        Rows.add(new Row(5, 'Reloading all matches from the Torc platform.'));
        Rows.add(new Row(6, 'Retrieving all applications associated with the RD1 Job.'));
        Rows.add(new Row(7, 'Creating applicants in Torc if they do not already exist.'));
        Rows.add(new Row(8, 'Loading all Torc matches and creating candidates in RD1 if they do not already exist.'));
        Rows.add(new Row(9, 'Creating or updating RD1 applications using Torc matches.'));
        Rows.add(new Row(10, 'Initiating update to the Torc platform using RD1 applications.'));
        Rows.add(new Row(11, 'Creating or updating Torc matches using RD1 applications.'));
        Rows.add(new Row(12, 'Process completed.'));
        Rows[0].label = 'PROCESSING';
    }
    public void updateRows() 
    {
        for (Integer s = 1; s <= 12; s++) 
        {
            Rows[s-1].label =  (s < currentStep) ? 'DONE' : (s == currentStep ? 'PROCESSING' : 'PENDING');
        }
    }    
    public String getDoneFlag() { return String.valueOf(done); }
    public String getJobUrl()   { return '/' + rd1Job.Id; }
}