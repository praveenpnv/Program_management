public without sharing class JobMatchController 
{    
    @AuraEnabled(cacheable=true)
    public static String getTorcJobId(String jobRecordId) 
    {
        TR1__Job__c job = [SELECT Torc_Id__c FROM TR1__Job__c WHERE Id = :jobRecordId LIMIT 1];
        return job.Torc_Id__c;
    }
    @AuraEnabled(cacheable=true)
    public static List<Torc_Match__c> getMatches(String torcId) 
    {
        TR1__Job__c trJob=[Select id, Torc_Id__c from TR1__Job__c where id=:torcId];
        
        List<Torc_Match__c> lst=[
            SELECT Id, User_Full_Name__c,torc_user_ref__r.external_id__c,Contact__c
            FROM Torc_Match__c
            WHERE jobOpportunityId__c = :trJob.Torc_Id__c AND 
            Status__c IN ('PRESHORTLISTED','TKSHORTLISTED','CZSHORTLISTED') 
            and torc_user_ref__c!=NULL and Delete_From_Platform__c = FALSE LIMIT 500
        ];
        
        Map<string,Contact> sSet=new Map<string,Contact>();
        for(Torc_Match__c rec:lst)
        {
            sSet.put(rec.torc_user_ref__r.external_id__c,null);
        }
        List<contact> lstContacts=new list<contact>();
        for(Contact c:[Select id,Name,torc_id__c from Contact where torc_id__c in :sSet.keyset()])
            sSet.put(c.torc_id__c,c);
        
        List<Torc_Match__c> finalList = new     List<Torc_Match__c>();
        for(Torc_Match__c rec:lst)
        {
            if(sSet.get(rec.torc_user_ref__r.external_id__c)!=NULL)
            {
                rec.Contact__c = sSet.get(rec.torc_user_ref__r.external_id__c).id;
                finalList.add(rec);
                if(finalList.size()>=20)
                    break;
            }        
        }
        system.debug(finalList.size());
        return finalList;
    }

    @AuraEnabled
    public static void addToList(List<Id> matchIds) 
    {
        /*System.debug('Selected Match IDs: ' + matchIds);
        List<Torc_Match__c>lstM = [Select Id, userId__c,jobOpportunityId__c,Status__c from Torc_Match__c where id in:matchIds];
        for(Torc_Match__c tm:lstM)
        {
            tm.Status__c='MATCHED';
        }
        torcRD1Integration.HardCallTorcmatchUpdate = true;
        update lstM;
        makematchesmatch(lstM);*/
    }
    /*public static void makematchesmatch(List<Torc_Match__c>lstM) 
    {
        List<Torc_API_Call__c> lstToUpsert=new List<Torc_API_Call__c>();
        for(Torc_Match__c tmatch:lstM)
        {
            Torc_API_Call__c rec=new Torc_API_Call__c(type__c='Torc_Match', Torc_Match__c =tMatch.id,Operation__c='UPDATE');
            rec.Body__c = JSON.serialize(tmatch);
            lstToUpsert.add(rec);
        }
        torcRD1Integration.runbatch(lstToUpsert);
    }*/
    @AuraEnabled(cacheable=true)
    public static Datetime getJobCreatedDate(String jobRecordId) 
    {
        //return datetime.now();
        TR1__Job__c job = [SELECT CreatedDate FROM TR1__Job__c WHERE Id = :jobRecordId LIMIT 1];
        return job.CreatedDate;
    }
    @AuraEnabled(cacheable=true)
    public static string getSearchURL(){
        Torc_Rd1_Integration__c rd1Instance = Torc_Rd1_Integration__c.getInstance();
        if (rd1Instance != null) {
            return rd1Instance.Torc_Search_URL__c;
        }
        return '';
    }
    @AuraEnabled(cacheable=true)
    public static String getOrgId() 
    {
        return UserInfo.getOrganizationId().substring(0, 15);
    }
    @AuraEnabled
    public static void setSyncTime(Id recordId) 
    {
        try
        {
            if(Torc_Rd1_Integration__c.getInstance().Sync_Enabled__c)
            {
                string s=recordId;
                if (recordId == null) throw new AuraHandledException('No recordId');
                if(s.left(3)=='003')
                    update new Contact(Id = recordId, sync_request_time__c = System.now(), applicable_for_torc_sync__c=true);
                else    
                {
                    TR1__Job__c j=[Select id, Torc_Id__c,Legacy_BH_Id__c,sync_request_time__c,applicable_for_torc_sync__c from TR1__Job__c where id=:recordId];
                    if(j.Torc_Id__c==NULL && j.Legacy_BH_Id__c!=NULL)
                    {
                        string stt=j.Legacy_BH_Id__c;
                        List<Torc_Job_opportunity__c> tj= [Select id, External_Id__c from Torc_Job_opportunity__c where externalJobId__c = :stt];
                        
                        if(tj.size()>0)
                        {
                            j.Torc_Id__c=tj[0].External_Id__c;
                            update j;
                            return;
                        }
                    }
                    update new tr1__Job__c(Id = recordId, sync_request_time__c = System.now(), applicable_for_torc_sync__c=true);
                }    
            }
        }
        catch(exception ex)
        {
            throw new AuraHandledException('Please edit and save the record first. Contact Admin if you continue see this error.' + ex.getMessage());
        }        
        
    }
}