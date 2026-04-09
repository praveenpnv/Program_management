global class torcRD1Integrationbatch implements Schedulable, Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    public static string qry='Select is_Error__c, Skip_Count__c, Createddate,Torc_Id__c, ID,Type__c,Operation__c, Body__c,Job__c, Application__c ,Contact__c,Processed__c,result__c, SFDC_Error__c  FROM Torc_API_Call__c WHERE Processed__c=FALSE ';
    private set<id>recIds;
    Public torcRD1Integrationbatch(set<id>ris)
    {
        recIds = ris;
    }
    global void execute(SchedulableContext sc) 
    {
        System.enqueueJob(new torcRD1IntegrationQueue(recIds));
    }
    global Database.QueryLocator start( Database.BatchableContext bc )
    { 
        string s = qry+' AND id  in :recIds';
        return Database.getQueryLocator(s);
    }    
    global void execute(Database.BatchableContext bc, List<Torc_API_Call__c> lstRecord) 
    {
        runProcessNow(lstRecord);
    }
    
    public static void runProcessNow(List<id> lstRecordIds) 
    {
        runProcessNow(Database.Query(qry+' AND id in: lstRecordIds'));
    }
    public static void runProcessNow(List<Torc_API_Call__c> lstRecord) 
    {
        Map<id,Contact>contactIds=new Map<id,Contact>();
        Map<id,TR1__Job__c>jobIds=new Map<id,TR1__Job__c>();
        Map<id,TR1__Application_V2__c>applicationIds=new Map<id,TR1__Application_V2__c>();
        Map<string,Task>NoteIds=new Map<string,Task>();
        for(Torc_API_Call__c sobj:lstrecord)
        {
            if(sObj.type__c=='Job')
                jobIds.put(sObj.Job__c,null);
            if(sObj.type__c=='User')
                contactIds.put(sObj.Contact__c,NULL);    
            if(sObj.type__c=='Match')
                applicationIds.put(sObj.Application__c,NULL);        
            if(sObj.type__c=='Note')
                NoteIds.put(sObj.Body__c,NULL);        
            if(sObj.type__c=='Note' && sObj.Contact__c!=NULL)
                contactIds.put(sObj.Contact__c,NULL);      
            if(sObj.type__c=='Note' && sObj.Job__c!=NULL)
                jobIds.put(sObj.Job__c,NULL);          
        }
        if(NoteIds.keyset().size()>0)
        {
            Set<id> lstIds=jobIds.keyset();
            for(Task cn:[SELECT Id, Description, whoId,whatId, TR1__Original_Power_Note__c from Task Where id in:NoteIds.keySet()])
                NoteIds.put(cn.id,cn);            
        }
        if(jobIds.keyset().size()>0)
        {
            Set<id> lstIds=jobIds.keyset();
            string soql = 'SELECT '+getFieldList('TR1__Job__c') +', (Select id, TR1__Master_Skill_Name__c, TR1__Skill_Code__c, TR1__Type__c from TR1__Skills__r) FROM TR1__Job__c Where id in:lstIds';
            List<SObject> results = Database.query(soql);
            for(SObject rec:results)
                jobIds.put(rec.id,(TR1__Job__c)rec);   
        }
        if(applicationIds.keyset().size()>0)
        {
            Set<id> lstIds=applicationIds.keyset();
            string soql = 'SELECT '+getFieldList('TR1__Application_V2__c') +' FROM TR1__Application_V2__c Where id in:lstIds';
            List<SObject> results = Database.query(soql);
            for(SObject rec:results)
                applicationIds.put(rec.id,(TR1__Application_V2__c)rec);   
        }
        if(contactIds.keyset().size()>0)
        {
            Set<id> lstIds=contactIds.keyset();
            string soql = 'SELECT '+getFieldList('Contact') +',(SELECT Id, Extracted_Skill__c from ATSExtractedCandidateSkills__r Where Extracted_Skill__c!=NULL and Extracted_Skill__c!=\'\') FROM Contact Where id in:lstIds';
            system.debug(soql);
            List<SObject> results = Database.query(soql);
            for(SObject rec:results)
                contactIds.put(rec.id,(Contact)rec);   
        }
        
        Map<string,Torc_User__c>mapOwnerToTorcowner = new Map<string,Torc_User__c>();
        Map<id,Torc_API_Call__c>mapJobtoAPICall = new Map<id,Torc_API_Call__c>();
        Map<id,Torc_API_Call__c>mapCandidatetoAPICall = new Map<id,Torc_API_Call__c>();
        set<id> currentAPISet=new set<id>();
        for(Torc_API_Call__c sobj:lstrecord)
        {
            currentAPISet.add(sObj.id);
            if(sObj.type__c=='USER')
            {
                mapCandidatetoAPICall.put(sobj.Contact__c,sObj);
            }
            if(sObj.type__c=='Job')
            {
                mapJobtoAPICall.put(sobj.job__c,sObj);
                TR1__Job__c rec = jobIds.get(sObj.Job__c);
                if(rec.Responsible_Recruiter__c!=NULL)
                    mapOwnerToTorcowner.put(rec.responsible_recruiter_email__c.toLowerCase(),null);
            }
            if(sObj.type__c=='Match')
            {
                TR1__Application_V2__c rec = applicationIds.get(sObj.Application__c);
                mapOwnerToTorcowner.put(rec.creator_s_Email__c.toLowerCase(),null);
            }
        }
        set<id>jobsToSkip=new set<id>();
        Datetime skipCreateTime = datetime.now().addMinutes(-6);
        for(Torc_Api_Call__c tapi:[Select Id, Job__c,Torc_Id__c,createdDate from Torc_Api_Call__c where Job__c in:jobIds.keyset() AND Operation__c='INSERT' AND Processed__c=FALSE and id not in:currentAPISet And Createddate > :skipCreateTime])
        {
            if(tApi.Createddate < mapJobtoAPICall.get(tApi.Job__c).Createddate)
                jobsToSkip.add(tAPI.Job__c);
        }
        set<id>candidatesToSkip=new set<id>();
        for(Torc_Api_Call__c tapi:[Select Id, Contact__c,Torc_Id__c,createdDate from Torc_Api_Call__c where contact__c in:contactIds.keyset() AND Operation__c='INSERT' AND Processed__c=FALSE and id not in:currentAPISet  And Createddate > :skipCreateTime])
        {
            if(tApi.Createddate < mapCandidatetoAPICall.get(tApi.Contact__c).Createddate)
                candidatesToSkip.add(tAPI.Contact__c);
        }
        if(mapOwnerToTorcowner.keyset().size()>0)
        {
            for(Torc_user__c tu:[Select id, email__c, username__c,external_id__c from Torc_user__c 
                                    WHERE email__c in:mapOwnerToTorcowner.keyset()
                                        AND Status__c='ACTIVE'
                                        AND usertype__c='CUSTOMER'
                                        AND username__c!=NULL 
                                        AND username__c!=''
                                        AND CognitoGroups__c includes('Admin','UserManagers','JobManagers')
                                    ])
            {
                mapOwnerToTorcowner.put(tu.email__c.toLowerCase(),tu);
            }
        }                    

        List<TR1__Job__c> lstJob=new List<TR1__Job__c>();
        List<Contact> lstContact=new List<Contact>();
        Map<string,Torc_user__c> mapTorcuser=new Map<string,Torc_user__c>();
        base_HttpService httpService = new base_HttpService();
        Map<id,contentversion> resumes = getResumes(lstRecord);
        List<Torc_API_Call__c> skippedAPICalls = new List<Torc_API_Call__c>();
        List<contentVersion> lstContentVersion =new List<contentversion>();
        Map<id,Torc_API_Call__c> mapApis = new Map<id,Torc_API_Call__c>();
        for(Torc_API_Call__c sobj:lstrecord)
        {
        try
        {
            system.debug(sobj);
            if(sObj.type__c=='Job')
            {
                TR1__Job__c rec = jobIds.get(sObj.Job__c);
                mapApis.put(rec.id,sObj);
                if(jobsToSkip.contains(rec.id))
                {
                    system.debug('SKIPPING JOB BECAUSE ALREADy INSERT RUNNING');
                    sObj.result__c = 'SKIP';
                    sObj.skip_count__c = sObj.skip_count__c==NULL?1:sObj.skip_count__c+1;
                    skippedAPICalls.add(sObj);
                    
                }
                else
                {
                    Torc_User__c tu = null;
                    if(rec.responsible_recruiter_email__c!=NULL && mapOwnerToTorcowner.get(rec.responsible_recruiter_email__c.toLowerCase())!=null)
                        tu=mapOwnerToTorcowner.get(rec.responsible_recruiter_email__c.toLowerCase());
                    String platformJobJSON = RD1ToTorc_Job.getGraphQLJson(rec,rec.Torc_Id__c==NULL,tu);
                    sobj.input__c = platformJobJSON==NULL?NULL:platformJobJSON.left(32000);
                    system.debug('=======JOB JSON=====================');
                    system.debug(platformJobJSON);
                    String response = test.isRunningTest()?'':httpService.callOperation(platformJobJSON);
                    //String response = httpService.callOperation(platformJobJSON);
                    system.debug('=======JOB RESPONSE=====================');
                    System.debug(response);
                    
                    RD1ToTorc_Job.Platform_JobResponse platformJobResponse = RD1ToTorc_Job.parse(response);
                    RD1ToTorc_Job.PlatformJob_Response responseValues = platformJobResponse.getResponseValues(); 
                    sObj.result__c = response.left(32000);
                    sObj.Torc_Id__c = responseValues!=NULL?responseValues.id:NULL;           
                    if (responseValues != null && rec.Torc_Id__c==NULL)
                    { 
                        lstJob.add(new TR1__Job__c(id=sobj.Job__c,Torc_Id__c = responseValues.id));
                    }
                    else
                    {
                        string err = platformJobResponse.getError();
                        if(err!=NULL && err!='')
                        {
                            lstJob.add(new TR1__Job__c(id=sobj.Job__c,Torc_Sync_Error__c = err.left(255)));
                            sObj.result__c = err.right(2000);
                            sObj.is_Error__c = true;
                        }    
                    } 
                }    
                //torcRD1Integration.skipTorcPlatformUpdateJOB = true;   
            }    
            else if(sObj.type__c=='User')
            {
                Contact rec = ContactIds.get(sObj.Contact__c);
                mapApis.put(rec.id,sObj);
                system.debug(resumes.get(rec.id));
                if(candidatesToSkip.contains(rec.id))
                {
                    system.debug('SKIPPING JOB BECAUSE ALREADy INSERT RUNNING');
                    sObj.result__c = 'SKIP';
                    sObj.skip_count__c = sObj.skip_count__c==NULL?1:sObj.skip_count__c+1;
                    skippedAPICalls.add(sObj);
                }
                else
                {
                    String platformUserJSON;
                    //platformUserJSON = RD1ToTorc_User.getGraphQLJson(rec,sObj.Operation__c=='INSERT');
                    platformUserJSON = RD1ToTorc_User.getGraphQLJson(rec,resumes.get(rec.id));
                    sobj.input__c = platformUserJSON==NULL?NULL:platformUserJSON.left(32000);
                    system.debug('=======User JSON=====================');
                    system.debug(platformUserJSON);
                    String response = test.isRunningTest()?'':httpService.callOperation(platformUserJSON);
                    sObj.result__c = response.left(32000);
                    RD1ToTorc_User.Platform_TorcUserResponse platformJobResponse = RD1ToTorc_User.parse(response);
                    system.debug(platformJobResponse);
                    if (platformJobResponse != null 
                            && platformJobResponse.data!=NULL 
                            && platformJobResponse.data.submitSFDCUserSync!=NULL
                            && sObj.Operation__c=='INSERT')
                    { 
                        contact con = new contact(id=sobj.contact__c,Torc_Id__c = platformJobResponse.data.submitSFDCUserSync.id);
                        //mapTorcuser.put(con.Torc_Id__c,null);
                        lstContact.add(con);
                    } 
                    else if (platformJobResponse != null 
                            && platformJobResponse.errors!=NULL 
                            && platformJobResponse.errors.size()>0
                            && platformJobResponse.errors[0].message!=NULL)
                    { 
                        contact con = new contact(id=sobj.contact__c);
                        con.Torc_Sync_Error__c = platformJobResponse.errors[0].message.right(2000);
                        sObj.result__c = platformJobResponse.errors[0].message.right(2000);
                        sObj.is_Error__c = true;
                        lstContact.add(con);
                    }
                    sObj.Torc_Id__c = (platformJobResponse!=NULL && platformJobResponse.data!=NULL && platformJobResponse.data.submitSFDCUserSync!=NULL)?platformJobResponse.data.submitSFDCUserSync.id:NULL;           
                    system.debug('=======user RESPONSE=====================');
                    System.debug(response);        
                }                            
                torcRD1Integration.skipTorcPlatformUpdateUSER = true;
            }
            if(sObj.type__c=='Resume' && sObj.body__c!=NULL)
            {
                list<string> l=sObj.body__c.split('/');
                if(l.size()>0)
                {
                    string fileName = l[l.size()-1];
                    Contentversion cv = uploadresume(sObj.body__c,fileName , sobj.Contact__c); 
                    if(cv!=NULL)
                        lstContentVersion.add(cv);
                }        
            } 
            
            if(sObj.type__c=='Note')
            {
                Contact con=null;
                TR1__Job__c job=NULL;
                if(sObj.Contact__c!=NULL)
                    con = contactIds.get(sObj.Contact__c);
                if(sObj.Job__c!=NULL)
                    job = jobIds.get(sObj.Job__c);    
                    
                Task note =  NoteIds.get(sObj.Body__c);   
                if((con!=NULL || job!=NULL) && note!=NULL)
                {
                    String platformUserJSON;
                    
                    platformUserJSON = RD1ToTorc_Notes.getGraphQLJson(note,sObj.Operation__c=='INSERT',con,job);
                    sobj.input__c = platformUserJSON==NULL?NULL:platformUserJSON.left(32000);
                    system.debug('=======Note JSON=====================');
                    system.debug(platformUserJSON);
                    String response = test.isRunningTest()?'':httpService.callOperation(platformUserJSON);
                    system.debug(response);
                    //RD1ToTorc_Notes.Platform_NoteResponse platformJobResponse = RD1ToTorc_User.parse(response);
                    //system.debug(platformJobResponse);
                } 
            }   
            
            
            
           if(sObj.type__c=='Match')
            {
                TR1__Application_V2__c rec = applicationIds.get(sObj.Application__c);
                torc_user__c tu= rec.Source__c!='Torc Match'?mapOwnerToTorcowner.get(rec.creator_s_Email__c.toLowerCase()):NULL;
                String platformJSON = RD1ToTorc_Match.getGraphQLJson(rec,tu);
                system.debug(platformJSON);
                
                sobj.input__c = platformJSON==NULL?NULL:platformJSON.left(32000);
                
                String response = test.isRunningTest()?'':httpService.callOperation(platformJSON);
                sObj.result__c = response.left(32000);
                system.debug('=======match RESPONSE=====================');
                System.debug(response);                
                RD1ToTorc_Match.Platform_MatchResponse platformMatchResponse = RD1ToTorc_Match.parse(response);
                System.debug(platformMatchResponse);
                RD1ToTorc_Match.PlatformMatch_Response responseValues = platformMatchResponse.getResponseValues();            
                System.debug(responseValues);
                if (responseValues != null && sObj.Operation__c=='INSERT')
                { 
                    System.debug(responseValues.id);
                } 
                torcRD1Integration.skipTorcPlatformUpdateMATCH = true; 
            } 
            /*else if(sObj.type__c=='Torc_Match')
            {
                Torc_Match__c rec = (Torc_Match__c)JSON.deserialize(sObj.Body__c, Torc_Match__c.class);
                String platformJSON = RD1ToTorc_Match.getGraphQLJson(null,rec,sObj.Operation__c);
                String response = httpService.callOperation(platformJSON);
                sObj.result__c = response.left(32000);
                system.debug('=======match RESPONSE=====================');
                System.debug(response);
                RD1ToTorc_Match.Platform_MatchResponse platformMatchResponse = RD1ToTorc_Match.parse(response);
                System.debug(platformMatchResponse);
            }*/
            }
            catch(exception ex)
            {
                sObj.SFDC_Error__c =  'Error:'+ex.getMessage().left(270);
                sObj.result__c = ex.getStackTraceString().left(3000);
                sObj.is_Error__c = true;
            }     
            sobj.processed__c = true;    
        }
        
        if(lstJob.size()>0)
        {
            for(tr1__Job__c j:lstJob)
                torcRD1Integration.skipTorcPlatformUpdateForTheseJOBs.add(j.id);
            torcRD1Integration.runningtorcCodeToUpdateData=true;
            Database.SaveResult[] results = database.Update(lstJob,false);
            for (Integer i = 0; i < results.size(); i++) 
            {
                if (!results[i].isSuccess() && results[i].getErrors()!=null && results[i].getErrors().size()>0) 
                {
                    Torc_API_Call__c original = mapApis.get(lstJob[i].id);
                    if(original!=NULL)
                    {
                        original.SFDC_Error__c =  results[i].getErrors()[0].getMessage().left(200);
                        original.is_Error__c = true;
                    }    
                }    
            }        
        }
        if(lstContact.size()>0)
        {
            torcRD1Integration.runningtorcCodeToUpdateData=true;
            Database.SaveResult[] results = database.Update(lstContact,false);
            for (Integer i = 0; i < results.size(); i++) 
            {
                if (!results[i].isSuccess() && results[i].getErrors()!=null && results[i].getErrors().size()>0) 
                {
                    Torc_API_Call__c original = mapApis.get(lstContact[i].id);
                    if(original!=NULL)
                    {
                        original.SFDC_Error__c =  results[i].getErrors()[0].getMessage().left(200);
                        original.is_Error__c = true;
                    }    
                }    
            }  
        }
        if(lstContentVersion.size()>0)
        {
            insert lstContentVersion;
        }
        upsert lstrecord;
        if(skippedAPICalls.size()>0)
        {
            set<id>setToProcess=new set<id>();
            string nm = 'torc-rd1-';
            for(Torc_API_Call__c sObj:skippedAPICalls)
            {
                if(sObj.Skip_Count__c<10)
                {
                    sObj.processed__c = false;
                    setToProcess.add(sObj.id);
                    nm = 'torc-rd1-' +sObj.id;
                }    
                else
                {
                    sObj.processed__c = true;
                    sObj.SFDC_Error__c = 'Parmanent SKIP';
                }
            }
            update skippedAPICalls;
            if(setToProcess.size()>0)
            {
                torcRD1Integrationbatch runSkipped=new torcRD1Integrationbatch(setToProcess);
                Datetime runTime = Datetime.now().addMinutes(1);
                String cronExp = String.format('{0} {1} {2} {3} {4} ? {5}', new List<String>{
                    String.valueOf(runTime.second()),
                    String.valueOf(runTime.minute()),
                    String.valueOf(runTime.hour()),
                    String.valueOf(runTime.day()),
                    String.valueOf(runTime.month()),
                    String.valueOf(runTime.year())
                });    
                nm = nm +userInfo.getuserId()+runTime.ToString();
                System.schedule(nm, cronExp, runSkipped);
            }    
        }
    }
    global void finish(Database.BatchableContext bc)
    {
        system.debug('----IN FINISH-------');
    }
    public static Map<id,contentversion> getResumes(List<Torc_API_Call__c> lstRecord)
    {
        set<id>parents=new set<id>();
        Map<id,contentversion> resumes=new Map<id,contentversion>();
        if(Torc_Rd1_Integration__c.getInstance().skip_Resume__c)
            return resumes;

        for(Torc_API_Call__c sobj:lstrecord)
        {
            system.debug(sobj);
            if(sObj.type__c=='User' && sObj.Contact__c!=NULL)
                parents.add(sObj.Contact__c);
        }
        if(parents.size()>0)
        {
            Map<id,id>contentVersionIds=new Map<id,id>();
            for(ContentDocumentLink con:[Select id,LinkedEntityId, ContentDocumentId from ContentDocumentLink where LinkedEntityId in:parents])
            {
                contentVersionIds.put(con.ContentDocumentId,con.LinkedEntityId);
            }
            if(contentVersionIds.keyset().size()>0)
            {
                for(ContentVersion c:[SELECT Id,  Title, FileType,VersionData, ContentDocumentId , ContentSize, FileExtension, resume_from_torc__c, ContentLocation
                                      FROM ContentVersion
                                      WHERE is_Resume__c= TRUE AND ContentDocumentId in :contentVersionIds.keyset() Order By Lastmodifieddate DESC])
                {
                    if(resumes.get(contentVersionIds.get(c.ContentDocumentId))==NULL)
                        resumes.put(contentVersionIds.get(c.ContentDocumentId),c);
                }
            }
        }
        return resumes;        
        /*for(contentversion c:[SELECT Id,  Title, FileType,VersionData, ContentSize, FileExtension, resume_from_torc__c,
                                    FirstPublishLocationId, ContentLocation  from contentversion where 
                                    is_resume__c=true AND 
                                    IsLatest=true AND FirstPublishLocationId in :parents Order By Lastmodifieddate DESC])
        {
            if(resumes.get(c.FirstPublishLocationId)==NULL)
                resumes.put(c.FirstPublishLocationId,c);
        }*/                                    
        
    }
    
    public static contentVersion uploadresume(String fileUrl, String fileName, String linkedRecordId) 
    {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(fileUrl);
        request.setMethod('GET');    
        try 
        {
            HttpResponse response;
            response = http.send(request);
            if (response.getStatusCode() == 200) 
            {
                Blob fileBody = response.getBodyAsBlob();
                ContentVersion cv = new ContentVersion();
                if (!fileName.toLowerCase().endsWith('.pdf')) 
                {
                    fileName += '.pdf';
                }
                cv.Resume_From_Torc__c = true;
                cv.is_resume__c = true;
                cv.File_Category__c = 'Resume';
                cv.Title = fileName;
                cv.PathOnClient = '/' + fileName;
                cv.VersionData = fileBody;
                cv.FirstPublishLocationId=linkedRecordId;
                return cv;
/*                insert cv;
                ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                if (linkedRecordId != null) 
                {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = insertedCv.ContentDocumentId;
                    cdl.LinkedEntityId = linkedRecordId;
                    cdl.ShareType = 'V';
                    insert cdl;
                }*/
            } 
            else 
            {
                System.debug('Failed to download file. Status: ' + response.getStatus());
            }
        } 
        catch (Exception e) 
        {
            System.debug('Exception: ' + e.getMessage());
        }
        return null;
    }
    public static String getFieldList(String objectApiName) 
    {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        return String.join(new List<String>(fieldMap.keySet()), ',');
    }
}