public class torcRD1Integration
{
    public static boolean skipTorcPlatformUpdateUSER=false;
    public static set<id>skipTorcPlatformUpdateForTheseJOBs = new set<id>();
    public static boolean skipSFDCUpdateUSER=false;
    public static boolean skipTorcPlatformUpdateMATCH=false;
    public static boolean DoNotRunMATCHTOApplication=false;
    public static boolean skipTorcPlatformUpdateJOB=false;
    public static boolean HardCallTorcmatchUpdate=false;
    public static boolean runningtorcCodeToUpdateData=false;
    public static boolean alwaysRunQueue=false;
    public static boolean ForcedRunTorc2Rd1=false;
    public static void runbatch(List<Torc_API_Call__c>lstToUpsert)
    {
        system.debug('=====RUNNINGNEWJOBBBBBBBBB=======');
        system.debug(lstToUpsert);
        upsert lstToUpsert;
        if(!Torc_Rd1_Integration__c.getInstance().Use_Flow_for_API_Call__c)
        {
            set<id> recids=new set<id>();
            for(Torc_API_Call__c r:lstToUpsert)
                recIds.add(r.id);
            if(lstToUpsert.size()==1 || alwaysRunQueue)
                System.enqueueJob(new torcRD1IntegrationQueue(recIds));
            else
            {
                torcRD1Integrationbatch callAPI =new torcRD1Integrationbatch(recIds);
                Database.executeBatch(callAPI,10); 
            }
       }         
    }
    /*
    public static boolean ismeaningfulUpdate_Job(Torc_Job_Opportunity__c rec)
    {
        if(rec.updater__c == Torc_Rd1_Integration__c.getInstance().Job_Updater_in_Torc)
            return false;
        if(rec.externalJobId__c==NULL || rec.externalJobId__c.length()<15 || rec.externalJobId__c.left(3)!=  Torc_Rd1_Integration__c.getInstance().Job_prefix__c)
            return false;          
        return true;
    }
    public static void UpdateToRD1_Job(Map<id,Torc_Job_Opportunity__c> oldmap, Map<id,Torc_Job_Opportunity__c> newMap, boolean isInsert, boolean isUpdate)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_Torc_to_RD1__c) Return;
        List<Torc_Job_Opportunity__c> lstToWork=new List<Torc_Job_Opportunity__c>();
        for(Torc_Job_Opportunity__c tj:newMap.values())
        {
            system.debug(tj);
            if(ismeaningfulUpdate_Job(tj))
                lstToWork.add(tj);
        }
        system.debug(lstToWork);
        if(lstToWork.size()>0)
        {
            torcRD1Integration.skipTorcPlatformUpdateJOB=true;
            List<TR1__Job__c> lstToUpsert=new List<TR1__Job__c>();
            for(Torc_Job_Opportunity__c tj:lstToWork)
            {
                TR1__Job__c rec=new TR1__Job__c(Torc_Id__c = tj.external_id__c);
                torcRD1integrationMapping.filldata(rec, null, tj,oldmap==null?null:oldmap.get(tj.id),false);
                lstToUpsert.add(rec);
                system.debug(rec);
            }
            upsert lstToUpsert Torc_Id__c;
        }
    }
    */
    
    public static boolean ismeaningfulUpdate(TR1__Job__c rec,boolean isInsert, TR1__Job__c oldrec)
    {
        if(torcRD1Integration.skipTorcPlatformUpdateForTheseJOBs.contains(rec.id))
            return false;
        if(!supportingOpco(rec.User_Opco__c))
            return false;
        if((isInsert || rec.sync_Request_Time__c!=oldrec.sync_Request_Time__c) && rec.applicable_for_torc_sync__c)
            return true;
        return false;    
    }
    public static void UpdateToTorc_Job(Map<id,TR1__Job__c> oldmap, Map<id,TR1__Job__c> newMap, boolean isInsert, boolean isUpdate)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_RD1_To_Torc__c) Return;
        //if(torcRD1Integration.skipTorcPlatformUpdateJOB) return;
        System.Debug('==================================IN Update To TORC JOB=============================');
        List<TR1__Job__c> lstToWork=new List<TR1__Job__c>();
        for(TR1__Job__c tj:newMap.values())
        {
            if(ismeaningfulUpdate(tj,isInsert, oldmap==NULL?NULL:oldmap.get(tj.id)))
            {
                lstToWork.add(tj);
                torcRD1Integration.skipTorcPlatformUpdateForTheseJOBs.add(tj.id);
            }    
        }
        if(lstToWork.size()>0)
        {
            List<Torc_API_Call__c> lstToUpsert=new List<Torc_API_Call__c>();
            for(TR1__Job__c tj:lstToWork)
            {
                Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Job',Job__c=tj.id,Operation__c=(tj.Torc_Id__c==NULL?'INSERT':'UPDATE'));
                Tr1__Job__c toBody = new Tr1__Job__c(id=tj.id);
                rec.Body__c = JSON.serialize(toBody);
                lstToUpsert.add(rec);
            }
            runbatch(lstToUpsert);  
        }
        //torcRD1Integration.skipTorcPlatformUpdateJOB=true;    
    }
    //------------------------------------------USER Process------------------------------------------------------------------------
    public static boolean isUpdaterSFDC(string str)
    {
        if(str=='' || str==null)
            return true;
        set<string> vals=new set<string>();
        for(string s:Torc_Rd1_Integration__c.getInstance().updater_list_in_torc__c.split(','))
            vals.add(s.trim().toLowercase());
        return vals.contains(str.toLowercase());
        
    }
    public static boolean isResumeUpdated(Torc_User__c rec, Torc_User__c oldRec)
    {
        return (rec.resumeuploadedByRD__c ==FALSE && rec.resumeLocation__c !=NULL && rec.resumeLocation__c!='' && oldRec!=NULL && rec.resumeUpdateTime__c!=oldRec.resumeUpdateTime__c);
    }
    public static boolean ismeaningfulUpdate(Torc_User__c rec,boolean isInsert, Torc_User__c oldRec)
    {
        if(rec.userType__c!='FREELANCER')
            return false;
        if(rec.Status__c=='ARCHIVE')
            return false;    
        if(isResumeUpdated(rec, oldRec))
            return true;
        if(isUpdaterSFDC(rec.updater__c))
            return false;        
        if(isInsert && rec.sfdcExternalID__c!=NULL)
            return false;
        if(rec.sfdcExternalID__c!=NULL &&(rec.sfdcExternalID__c.length()!=18 || rec.sfdcExternalID__c.left(3)!='003'))
            return false;
        system.debug('ITSCOMINGHERE===========');    
        if(isInsert || rec.sync_Request_Time__c!=oldrec.sync_Request_Time__c)
            return true;        
        system.debug('ITSPASSINgCOMINGHERE===========');        
        return false;
    }
    public static boolean supportingOpco(string opco)
    {
        if(Torc_RD1_Integration__c.getInstance().supporting_opco__c==NULL || Torc_RD1_Integration__c.getInstance().supporting_opco__c=='' || opco==NULL || opco=='')
            return true;
        List<string> sset= Torc_RD1_Integration__c.getInstance().supporting_opco__c.split(',');
        for(string s:sSet)
        {
            if(s.trim().toLowercase()==opco.toLowercase())
                return true; 
        }   
        return false;
    }
    public static boolean ismeaningfulUpdate(Contact rec,boolean isInsert, Contact oldRec)
    {
        if(rec.recordTypeId!=Torc_RD1_Integration__c.getInstance().candidate_recordType_Id__c|| rec.Email==NULL || (!supportingOpco(rec.User_Opco__c)))
            return false;        
        if(rec.Torc_Id__c==NULL || isInsert)
            return true;
        if(rec.Last_Resume_Update__c!=NULL && (isInsert ||(oldRec!=NULL && oldRec.Last_Resume_Update__c!=rec.Last_Resume_Update__c)))
                return true;
        if(Torc_RD1_Integration__c.getInstance().candidate_Bi_Directional__c==TRUE && oldrec!=NULL && rec.sync_Request_Time__c!=oldrec.sync_Request_Time__c)
                return true;        
        return false;    
    }
    public static List<contact> quickCreateContactByTorcUser(List<Torc_User__c> lstToWork,Map<id,Torc_User__c> oldmap)
    {
        torcRD1Integration.skipTorcPlatformUpdateUSER=true;        
        map<string,Contact> mapContact=new map<string,Contact>();
        map<string,Contact> mapContactEmail=new map<string,Contact>();
        for(Torc_User__c tj:lstToWork)
        {
            mapContact.put(tj.External_Id__c,null);
            mapContactEmail.put(tj.email__c.toLowercase(),null);
        }    
        system.debug(lstToWork);
        
        For(Contact con:[Select Id, Torc_Id__c,Torc_user_Ref__c,torc_email__c 
                         FROM Contact 
                         WHERE (Torc_Id__c in:mapContact.keyset() OR torc_email__c in:mapContactEmail.keyset()) AND recordTypeId=:Torc_Rd1_Integration__c.getInstance().Candidate_recordtype_Id__c])
        {
            if(con.Torc_Id__c!=NULL && con.Torc_Id__c!='')
                mapContact.put(con.Torc_Id__c, new Contact(id=con.id));
            mapContactEmail.put(con.torc_email__c.toLowercase(), new Contact(id=con.id));    
        }    
        system.debug(mapContactEmail);        
        system.debug(mapContact);
        map<string,string> creatorEmailmap=new map<string,string>();
        for(Torc_User__c tj:lstToWork)
        {
            if(tj.creator__c!=NULL && tj.creator__c!='')
                creatorEmailmap.put(tj.creator__c.toLowerCase(),null);
            if(mapContact.get(tj.External_Id__c)!=NULL)
            {
                mapContact.get(tj.External_Id__c).Torc_user_Ref__c=tj.id;  
            }
            else if(mapContactEmail.get(tj.email__c.toLowercase())!=NULL)
            {
                mapContact.put(tj.External_Id__c,mapContactEmail.get(tj.email__c.toLowercase()));
                mapContact.get(tj.External_Id__c).Torc_user_Ref__c=tj.id;  
                mapContact.get(tj.External_Id__c).torc_id__c=tj.external_id__c;  
            }
            else
            {
                Contact newContact =new Contact(TR1__Candidate_Status__c='New', Torc_Origin__c = true, Torc_user_Ref__c=tj.id, torc_Id__c=tj.External_Id__c,recordTypeId=Torc_Rd1_Integration__c.getInstance().Candidate_recordtype_Id__c, Accountid=Torc_Rd1_Integration__c.getInstance().default_Account__c);
                mapContact.put(tj.External_Id__c,newContact);
            }    
        }
        for(Torc_User__c tu2:[Select id, userName__c, email__c from torc_user__c where userName__c in:creatorEmailmap.keySet()])
        {
            creatorEmailmap.put(tu2.userName__c.toLowerCase(),tu2.email__c.toLowercase());
        }
        Map<string,User>mapEmailToUser=new Map<string,User>();
        for(user u:[Select id,email,Opco__c from user where email in:creatorEmailmap.values() and IsActive=True])
        {
            mapEmailToUser.put(u.email.toLowerCase(),u);
        }
        system.debug(lstToWork);
        
        List<Contact> lstToUpsert=new List<Contact>();
        for(Torc_User__c tj:lstToWork)
        {
            Contact rec=mapContact.get(tj.external_id__c);
            torcRD1integrationMapping.filldataTorcToRD1Contact(rec, tj,oldmap==null?null:oldmap.get(tj.id),null);
            lstToUpsert.add(rec);
            if(rec.id==NULL && tj.creator__c!=NULL && tj.creator__c!='' && creatorEmailmap.get(tj.creator__c.toLowerCase())!=NULL)
            {
                string eml = creatorEmailmap.get(tj.creator__c.toLowerCase());
                if(mapEmailToUser.get(eml.toLowercase())!=NULL)
                {
                    rec.Responsible_Recruiter__c=rec.OwnerId=mapEmailToUser.get(eml.toLowercase()).id;
                    rec.User_Opco__c =  mapEmailToUser.get(eml.toLowercase()).Opco__c;   
                }   
            }    
            if(rec.id==NULL)
            {
                if(rec.Responsible_Recruiter__c==NULL && Torc_RD1_Integration__c.getInstance().Default_Owner__c!=NULL)
                    rec.Responsible_Recruiter__c=rec.OwnerId=Torc_RD1_Integration__c.getInstance().Default_Owner__c;
                if(rec.User_Opco__c==NULL)
                    rec.User_Opco__c='Torc'; 
            }        
        }
        system.debug(lstToUpsert);
        if(lstToUpsert.size()>0)
        {
            List<contact> newlstToUpsert = new List<contact>();
            set<id>contactIds=new set<id>();
            for(contact c:lstToUpsert)
            {
                if(c.id==NULL || (!contactIds.contains(c.id)))
                    newlstToUpsert.add(c);
                if(c.id!=NULL)    
                    contactIds.add(c.id);
            }
            system.debug(newlstToUpsert);
            runningtorcCodeToUpdateData = true;
            Database.UpsertResult[] results = database.upsert(newlstToUpsert,false);  
            system.debug(results);
            lstToUpsert = newlstToUpsert;
        }
        
        return lstToUpsert;
    } 
    public static void UpdateToRD1_User(Map<id,Torc_User__c> oldmap, Map<id,Torc_User__c> newMap, boolean isInsert, boolean isUpdate)
    {
        System.Debug('IN Insert/Update To RD1 USER======1======================='+skipSFDCUpdateUSER);
        
        if(skipSFDCUpdateUSER) return;
        if(Torc_Rd1_Integration__c.getInstance().Skip_Torc_to_RD1__c) Return;
        System.Debug('IN Insert/Update To RD1 USER========2=====================');
        torcRD1Integration.skipTorcPlatformUpdateUSER=true;        

        List<Contact> lstContacts=new List<Contact>();
        for(Torc_User__c tu:newMap.values())
        {
            system.debug(tu.given_Name__c);
            system.debug(tu.family_Name__c);
            system.debug(tu.Email__c);
            system.debug(tu.sync_Request_Time__c);
            
            if(tu.sfdcExternalID__c!=NULL && tu.sfdcExternalID__c!='' && tu.sfdcExternalID__c.length()==18 && tu.sfdcExternalID__c.left(3)=='003')
            {
                if(isinsert || (oldmap!=NULL && tu.sfdcExternalID__c!= oldmap.get(tu.id).sfdcExternalID__c))
                    lstContacts.add(new contact(id=tu.sfdcExternalID__c, torc_id__c =tu.external_Id__c, Torc_user_Ref__c=tu.id));
            }        
        }
        if(lstContacts.size()>0)
        {
            runningtorcCodeToUpdateData = true;
            database.update(lstContacts,false);
        }
        if(ForcedRunTorc2Rd1==False && Torc_Rd1_Integration__c.getinstance().Only_Connect_Operation__c)
            return;
            
        List<Torc_User__c> lstToWork=new List<Torc_User__c>();
        system.debug(newMap.values().size());
        for(Torc_User__c tj:newMap.values())
        {
            if(ismeaningfulUpdate(tj,isInsert,oldmap==NULL?NULL:oldmap.get(tj.id)))
                lstToWork.add(tj);
        }
        system.debug(lstToWork);
        system.debug(lstToWork.size());
        if(lstToWork.size()>0)
        {            
            List<Contact> lstToUpsert = quickCreateContactByTorcUser(lstToWork,oldmap);
            system.debug(lstToUpsert.size());
            if(lstToUpsert.size()>0)
            {
                system.debug(lstToUpsert[0]);
            }
            
            Map<string,string> resumeChangeList=new Map<string,string>();
            for(Torc_User__c tj:lstToWork)
            {
                if(isResumeUpdated(tj, oldmap==null?null:oldmap.get(tj.id))|| ((isInsert || ForcedRunTorc2Rd1) && tj.resumeLocation__c!=NULL && tj.resumeLocation__c!=''))
                {
                    if(!Torc_Rd1_Integration__c.getInstance().skip_Resume__c)
                        resumeChangeList.put(tj.external_id__c,'https://res.cloudinary.com/torc/image/upload/'+tj.resumeLocation__c);
                }
            }
            if(lstToUpsert.size()>0 && resumeChangeList.size()>0)
            {
                List<Torc_API_Call__c> lstResumes=new List<Torc_API_Call__c>();
                for(contact c:[Select id, torc_resume__c,torc_id__c from contact where torc_id__c in:resumeChangeList.keyset()])
                {
                    Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Resume',Contact__c=c.id,Operation__c='INSERT');
                    rec.Body__c = resumeChangeList.get(c.torc_id__c);
                    lstResumes.add(rec);
                }
                runbatch(lstResumes);   
            }
        }
    }
    public static void UpdateToTorc_user(Map<id,Contact> oldmap, Map<id,Contact> newMap, boolean isInsert, boolean isUpdate)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_RD1_To_Torc__c) Return;
        if(torcRD1Integration.skipTorcPlatformUpdateUSER) return;
        
        System.Debug('===IN Update To Torc USER=============================');
        torcRD1Integration.skipTorcPlatformUpdateUSER = true;
        List<Contact> lstToWork=new List<Contact>();
        for(Contact tj:newMap.values())
        {
            if(ismeaningfulUpdate(tj,isInsert, oldmap==NULL?null:oldmap.get(tj.id)))
                lstToWork.add(tj);
        }
        if(lstToWork.size()>0)
        {
            List<Torc_API_Call__c> lstToUpsert=new List<Torc_API_Call__c>();
            for(Contact tj:lstToWork)
            {
                Torc_API_Call__c rec=new Torc_API_Call__c(type__c='User',Contact__c=tj.id,Operation__c=(tj.Torc_Id__c==NULL?'INSERT':'UPDATE'));
                
                Contact toBody = new Contact(id=tj.id);
                rec.Body__c = JSON.serialize(toBody);
                
                
                lstToUpsert.add(rec);
            }
            runbatch(lstToUpsert);
        } 
    }
    
    
    public static boolean ismeaningfulUpdate(TR1__Application_V2__c rec, TR1__Application_V2__c oldRec)
    {
        if((oldRec==NULL || rec.sync_Request_Time__c!=oldrec.sync_Request_Time__c) && 
            rec.Torc_Id_Of_User__c!=NULL && rec.Torc_Id_Of_User__c!='' &&
            rec.Torc_Id_Of_Job__c!=NULL && rec.Torc_Id_Of_Job__c!='')
            return true;
        return false;    
    }
    public static void UpdateToTorc_Match(Map<id, TR1__Application_V2__c> oldmap, Map<id, TR1__Application_V2__c> newMap)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_RD1_To_Torc__c) Return;
        if(torcRD1Integration.skipTorcPlatformUpdateMATCH) return;
        System.Debug('===IN Insert/Update To Torc Match=============================');
        torcRD1Integration.skipTorcPlatformUpdateMATCH = true;
        List<TR1__Application_V2__c> lstToWork=new List<TR1__Application_V2__c>();
        for(TR1__Application_V2__c tj:newMap.values())
        {
            if(ismeaningfulUpdate(tj, oldmap==NULL?null:oldmap.get(tj.id)))
                lstToWork.add(tj);
        }
        if(lstToWork.size()>0)
        {
            List<Torc_API_Call__c> lstToUpsert=new List<Torc_API_Call__c>();
            for(TR1__Application_V2__c tj:lstToWork)
            {
                Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Match',Application__c=tj.id,Operation__c=(oldmap==NULL?'INSERT':'UPDATE'));
                rec.Body__c = JSON.serialize(new TR1__Application_V2__c(id=tj.id));
                lstToUpsert.add(rec);
            }
            runbatch(lstToUpsert);
        }    
    }
    
    public class TR1LocationCls
    {
        public string recordId{get;set;}
        public string source{get;set;}
        public TR1LocationCls(){}
        public TR1LocationCls(string r, string s)
        {
            recordId=r;
            source=s;
        }
    }
    public static string getrecordidFromTR1Location(string json)
    {
        if(json==NULL)return null;
        TR1LocationCls rec = (TR1LocationCls) System.JSON.deserialize(json, TR1LocationCls.class);
        return rec.recordId;
    }
    public static boolean ismeaningfulUpdate(Torc_Note__c rec)
    {
        if(rec.ExternalSystemID__c!=NULL || isUpdaterSFDC(rec.updater__c))
            return false;
        return true;
    }
    public static void UpdateToTorc_Notes(List<Task> lstToProcess,Map<string,Contact>mapcontact,map<string,TR1__Job__c> mapJob)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_RD1_To_Torc__c) Return;
        System.Debug('===IN Update To Torc Notes=============================');
        List<Torc_API_Call__c> lstToUpsert=new List<Torc_API_Call__c>();
        for(Task note:lstToProcess)
        {
            string s= torcRD1Integration.getrecordidFromTR1Location(note.TR1__Location__c);
            if(s!=null)
            {
                if(note!=NULL && mapcontact.get(s)!=NULL)
                {
                    Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Note',Contact__c=mapcontact.get(s).id,Operation__c='INSERT');
                    rec.Body__c = note.id;
                    lstToUpsert.add(rec);
                }
                else if(note!=NULL && mapJob.get(s)!=NULL)
                {
                    Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Note',Job__c=mapJob.get(s).id,Operation__c='INSERT');
                    rec.Body__c = note.id;
                    lstToUpsert.add(rec);
                }
            }    
        } 
        if(lstToUpsert.size()>0)
            runbatch(lstToUpsert);
    }
    public static void UpdateToRD1_Notes(List<Torc_Note__c> lstToProcess)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_RD1_To_Torc__c) Return;
        List<Torc_Note__c> lstToWork=new List<Torc_Note__c>();
        System.Debug('===IN Update To RD1 Notes=============================');
        for(Torc_Note__c tj:lstToProcess)
        {
            if(ismeaningfulUpdate(tj))
                lstToWork.add(tj);
        }
        system.debug(lstToWork);
        if(lstToWork.size()>0)
        {            
            map<string,Contact> mapContact=new map<string,Contact>();
            map<string,TR1__Job__c> mapJob=new map<string,TR1__Job__c>();
            for(Torc_Note__c tj:lstToWork)
            {
                if(tj.userid__c!=NULL)
                    mapContact.put(tj.userid__c,null);
                if(tj.jobOpportunityId__c!=NULL)
                    mapJob.put(tj.jobOpportunityId__c,null);    
            }
            if(mapContact.keyset().size()>0)
            {    
                For(Contact con:[Select Id, Torc_Id__c FROM Contact WHERE Torc_Id__c in:mapContact.keyset()])
                {
                        mapContact.put(con.Torc_Id__c, con);
                }    
            }
            if(mapJob.keyset().size()>0)
            {    
                For(TR1__Job__c con:[Select Id, Torc_Id__c FROM TR1__Job__c WHERE Torc_Id__c in:mapJob.keyset()])
                {
                        mapJob.put(con.Torc_Id__c, con);
                }    
            }    
            List<Task> lstToUpsert=new List<Task>();
            system.debug(mapContact);
            id recId = [SELECT Id from RecordType Where DeveloperName='Power_Notes'].Id;
            for(Torc_Note__c tj:lstToWork)
            {
                Task t =new Task(torc_id__c = tj.external_id__c,recordtypeid=recId, Subject='Notes',Status='Completed',Priority='Normal', Description=tj.content__c);
                if(tj.userid__c!=NULL && mapContact.get(tj.userid__c)!=NULL)
                {
                    t.WhoId=mapContact.get(tj.userid__c).Id;
                    t.TR1__Location__c = JSON.serialize(new TR1LocationCls(t.WhoId,'Record'));
                    lstToUpsert.add(t);
                }
                else if(tj.jobOpportunityId__c!=NULL && mapJob.get(tj.jobOpportunityId__c)!=NULL)
                {
                    t.WhatId=mapJob.get(tj.jobOpportunityId__c).Id;
                    t.TR1__Location__c = JSON.serialize(new TR1LocationCls(t.WhatId,'Record'));
                    lstToUpsert.add(t);
                }    
            }
            if(lstToUpsert.size()>0)
                insert lstToUpsert;
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //--------------Match Process----------------------------------------------------------------------
    
    
    
    public static boolean ismeaningfulUpdate(Torc_Match_Shadow__c rec,boolean isInsert, Torc_Match_Shadow__c oldRec)
    {
        if(isUpdaterSFDC(rec.updater__c) || rec.status__c=='INTERESTED'|| rec.status__c=='PRESHORTLISTED' || rec.status__c=='SHORTLISTED' || rec.status__c=='SKIPPED' || rec.status__c=='TKSHORTLISTED' || rec.status__c=='CZSHORTLISTED')
            return false;  
        if(rec.jobOpportunityId__c ==NULL || rec.userid__c==NULL || rec.jobOpportunityId__c =='' || rec.userid__c=='')
            return false;
        if(isInsert || rec.sync_Request_Time__c!=oldrec.sync_Request_Time__c)
            return true;    
        return false;
    }
    /*public static boolean ismeaningfulUpdate(TR1__Application_V2__c rec,string operation, TR1__Application_V2__c oldRec)
    {
        if(rec.Torc_Id_Of_Job__c==NULL || rec.Torc_Id_Of_User__c ==NULL ||rec.Torc_Id_Of_Job__c=='' || rec.Torc_Id_Of_User__c =='')
            return false;
        if(operation=='DELETE') 
            return true;
            
        return false;    
    }*/
    public static void UpdateToRD1_Match(Map<id,Torc_Match_Shadow__c> oldmap, Map<id,Torc_Match_Shadow__c> newMap, boolean isInsert, boolean isUpdate)
    {
        if(Torc_Rd1_Integration__c.getInstance().Skip_Torc_to_RD1__c || DoNotRunMATCHTOApplication) Return;
        System.Debug('===IN Update To RD1 Match=============================');
        torcRD1Integration.skipTorcPlatformUpdateMATCH=true;
        List<Torc_Match_Shadow__c> lstToWork=new List<Torc_Match_Shadow__c>();
        Map<string,Contact> mapCandidate=new Map<string,Contact>();
        Map<string,TR1__Job__c> mapJob=new Map<string,TR1__Job__c>();
        Map<string,TR1__Application_V2__c>maptorcIdToApp=new Map<string,TR1__Application_V2__c>();
        Map<string,user> createrToSFDCuserMap=new Map<string,user>();
        for(Torc_Match_Shadow__c tj:newMap.values())
        {
            system.debug(tj);
            if(ismeaningfulUpdate(tj,isInsert,oldmap==NULL?NULL:oldmap.get(tj.id)))
            {
                string matchkey = tj.userId__c+'_'+tj.jobOpportunityId__c;
                maptorcIdToApp.put(matchkey,null);
                mapCandidate.put(tj.userId__c,null);
                mapJob.put(tj.jobOpportunityId__c,null);
                if(tj.Matcher_Email__c!=NULL)
                    createrToSFDCuserMap.put(tj.Matcher_Email__c.toLowercase(),null);
                lstToWork.add(tj);
            }    
        }
        if(createrToSFDCuserMap.keyset().size()>0)
        {
            for(user u:[Select id, email from User where Email in:createrToSFDCuserMap.keyset()])
                createrToSFDCuserMap.put(u.Email.toLowercase(),u);
        }
        system.debug(lstToWork);
        if(mapCandidate.keyset().size()>0)
        {
            for(Contact c:[Select ID,Torc_Id__c from Contact where Torc_Id__c in:mapCandidate.keyset()])
                mapCandidate.put(c.Torc_Id__c,c);
        }
        set<string>torcIdsnotinRd1=new set<string>();
        for(string s:mapCandidate.keyset())
        {
            if(mapCandidate.get(s)==NULL)torcIdsnotinRd1.add(s);
        }
        if(torcIdsnotinRd1.size()>0)
        {
            string soql = 'SELECT '+ torcRD1Integrationbatch.getFieldList('Torc_User__c') +' FROM Torc_User__c Where External_Id__c in:torcIdsnotinRd1';
            List<Torc_User__c> results = Database.query(soql);
            QuickCreateContactByTorcUser(results,null);
            for(Contact c:[Select ID,Torc_Id__c from Contact where Torc_Id__c in:mapCandidate.keyset()])
                mapCandidate.put(c.Torc_Id__c,c);
        }
        if(mapJob.keyset().size()>0)
        {
            for(TR1__Job__c c:[Select ID,Torc_Id__c,RecordTypeId,RecordType.Name from TR1__Job__c where Torc_Id__c in:mapJob.keyset()])
                mapJob.put(c.Torc_Id__c,c);
        }
        
        if(lstToWork.size()>0)
        {        
            List<TR1__Application_V2__c> lstToUpsert=new List<TR1__Application_V2__c>();  
            List<recordtype> lstRecordtypes = [SELECT Id, Name, DeveloperName,SobjectType, IsActive  from recordType 
                                                    Where sObjectType in ('TR1__Application_V2__c')];            
            for(TR1__Application_V2__c existingApp:[Select id, Torc_user_Job_Combo__c,Source__c,Tr1__Stage__c, TR1__Reject__c from TR1__Application_V2__c where Torc_user_Job_Combo__c in:maptorcIdToApp.keyset()])
                maptorcIdToApp.put(existingApp.Torc_user_Job_Combo__c,existingApp);
            set<string>existinguniqueSet = new set<string>();
            for(Torc_Match_Shadow__c tj:lstToWork)
            {
                system.debug(mapCandidate.get(tj.userId__c));
                system.debug(mapJob.get(tj.jobOpportunityId__c));
                if(mapCandidate.get(tj.userId__c)!=NULL && mapJob.get(tj.jobOpportunityId__c)!=NULL)
                {
                    string matchkey = tj.userId__c+'_'+tj.jobOpportunityId__c;
                    if(!existinguniqueSet.contains(matchKey))
                    {
                        existinguniqueSet.add(matchKey);  
                        TR1__Application_V2__c rec=maptorcIdToApp.get(matchkey)!=NULL?
                                                                new TR1__Application_V2__c(id=maptorcIdToApp.get(matchkey).id,TR1__Reject__c=maptorcIdToApp.get(matchkey).TR1__Reject__c):
                                                                new TR1__Application_V2__c(TR1__Stage__c='Application',Status__c='Submitted');                                        
                        rec.Torc_matcher__c = tj.matcher__c;
                        rec.Torc_Id__c = tj.Platform_Id__c;
                        rec.Torc_Application_id__c = (tj.applicationId__c==NULL || tj.applicationId__c=='')?'User#' + tj.userid__c:tj.applicationId__c;
                        rec.TR1__Applicant__c = mapCandidate.get(tj.userId__c).id;
                        if(rec.id==NULL)
                        {
                            rec.TR1__Job__c = mapJob.get(tj.jobOpportunityId__c).id;                                                       
                            if(tj.Matcher_Email__c!=NULL && createrToSFDCuserMap.get(tj.Matcher_Email__c.toLowercase())!=NULL)
                                rec.Application_Owner__c = createrToSFDCuserMap.get(tj.Matcher_Email__c.toLowercase()).id;
                        }
                        torcRD1integrationMapping.filldata(rec, tj,oldmap==null?null:oldmap.get(tj.id),false,lstRecordtypes,mapJob.get(tj.jobOpportunityId__c).recordtype.Name);
                        lstToUpsert.add(rec);
                    }    
                }
            }
            system.debug(lstToUpsert);
            if(lstToUpsert.size()>0)
            {
                runningtorcCodeToUpdateData = true;
                Database.UpsertResult[] results = database.upsert(lstToUpsert,false);
                system.debug(results);
            }    
        }
    }
}