global class torcRD1IntegrationOnetimeBatch implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    public static void processSFDCContactreferencesetup()
    {
        for(List<Contact>lst:[Select Id, Torc_Id__c,Torc_User_ref__c from Contact where Torc_Id__c!=NULL AND Torc_User_ref__c=NULL LIMIT 1000])
        {
            for(contact c:lst)
            {
                c.Torc_User_ref__r = new Torc_User__c(External_Id__c = c.Torc_Id__c);
            }
            upsert lst; 
        }
    }
    public static void processCleanUpAPICallObject(integer batchSize)
    {
        torcRD1IntegrationOnetimeBatch myBatchObject = new torcRD1IntegrationOnetimeBatch(null,null,null,'CLEANUPAPI'); 
        Id batchId = Database.executeBatch(myBatchObject,batchSize);
        //myBatchObject.start();
    } 
    public static void processSFDCToTorc(integer batchSize, string whereCond,string orderB,  integer Lim)
    {
        torcRD1IntegrationOnetimeBatch myBatchObject = new torcRD1IntegrationOnetimeBatch(whereCond,orderB,Lim,'SFDC2TORC'); 
        Id batchId = Database.executeBatch(myBatchObject,batchSize);
        //myBatchObject.start();
    }
    
    public static void processTorcToSFDC(integer batchSize,string whereCond,string orderB,  integer Lim)
    {
        torcRD1IntegrationOnetimeBatch myBatchObject = new torcRD1IntegrationOnetimeBatch(whereCond,orderB,Lim,'TORC2SFDC'); 
        Id batchId = Database.executeBatch(myBatchObject,batchSize);
        //myBatchObject.start();
    }
    
    public string operation;
    public string whereCondition;
    public integer recLimit;
    public string orderBy;
    Public torcRD1IntegrationOnetimeBatch(string whereCond, string orderB, integer Lim,string ope)
    {
        whereCondition = whereCond;
        recLimit = Lim;
        orderBy = orderB;
        operation=ope;    
    }
    global Database.QueryLocator start(Database.BatchableContext bc)
    { 
        if(orderBy==NULL || orderBy=='') orderBy = 'createddate';
        if(recLimit==NULL || recLimit<=0) recLimit = 45000;
        
        string soql = 'Select ID, sync_request_time__c  FROM ';
        if(operation=='SFDC2TORC')
        {
            soql = soql + ' Contact WHERE recordtypeId=\''+Torc_RD1_Integration__c.getinstance().Candidate_recordType_Id__c+'\'';
            soql = soql + ' AND Torc_Id__c = NULL ';
            
        }
        else if(operation=='TORC2SFDC')
        {
            soql = 'Select ID, sync_request_time__c,updater__c  FROM ';
            soql = soql +' Torc_User__c WHERE  Delete_From_Platform__c =FALSE and userType__c=\'FREELANCER\'';
        }
        else if(operation=='CLEANUPAPI')
        {
            soql='Select id from Torc_API_Call__c Where id<>NULL ';
        }
        if(whereCondition!=NULL && whereCondition!='')
                soql =soql + ' AND ' +whereCondition;
        soql =soql + ' ORDER BY ' +orderBy;               
        soql =soql + ' LIMIT ' +recLimit;                   
        system.debug(soql);           
        return Database.getQueryLocator(soql);
        //execute(Database.query(soql));
    }

    global void execute(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
        system.debug(lstrecord.size());
        List<Torc_API_Call__c> lstTorcAPICalls=new List<Torc_API_Call__c>();
        for(sObject tb:lstrecord)
        {
            if(operation=='SFDC2TORC')
            {
                contact tj=(contact)tb;
                Torc_API_Call__c rec=new Torc_API_Call__c(type__c='User',Contact__c=tj.id,Operation__c='INSERT');
                rec.Body__c = JSON.serialize(tj);
                lstTorcAPICalls.add(rec);
            }    
            else if(operation=='TORC2SFDC')
            {
                Torc_user__c c=(Torc_user__c)tb;
                c.sync_request_time__c = datetime.now();
                c.updater__c = 'SFDC_For_Update';
                system.debug(c);
            }    
        }
        if(operation=='SFDC2TORC')
        {
            upsert lstTorcAPICalls;
            set<id> recids=new set<id>();
            for(Torc_API_Call__c r:lstTorcAPICalls)
                recIds.add(r.id);
            System.enqueueJob(new torcRD1IntegrationQueue(recIds));
            //torcRD1Integrationbatch.runProcessNow(lstTorcAPICalls);
        }
        if(operation=='TORC2SFDC')
        {
            torcRD1Integration.ForcedRunTorc2Rd1 = TRUE;
            torcRD1Integration.alwaysRunQueue = TRUE;
            update lstrecord;
        }    
        if(operation=='CLEANUPAPI')
            delete lstrecord;    
    }
    global void finish(Database.BatchableContext bc)
    {
    }
}