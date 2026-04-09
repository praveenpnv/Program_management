Public class AWSDataLoaderQueue implements Queueable, database.AllowsCallouts
{
    public static void runProcess()
    {
        runProcess(false);
    }
    public static void runProcess(boolean isTest)
    {
        System.enqueueJob(new AWSDataLoaderQueue(0,null,1,isTest,0,null,null));
    }
    public static void runProcessForSingleId(string idOfRec,string onObject)
    {
        System.enqueueJob(new AWSDataLoaderQueue(0,null,1,test.isRunningTest(),0,idOfRec,onObject));
    }
    public static void runProcessForMatchOnly()
    {
        System.enqueueJob(new AWSDataLoaderQueue(0,null,1,test.isRunningTest(),0,'MATCHONLY',null));
    }
    private Integer currentPass;
    private AWSDataLoad.AWSLastEvaluatedKeySuperSet lastRunKey;
    private AWS_Sync__c awsrec;
    private Boolean runMore;
    public boolean isTestRun;
    Public integer upsertCount;
    Public static boolean isTestRunStatic = false;
    public string singleId;
    public string onObject;
    public AWSDataLoaderQueue(integer cOrder, AWSDataLoad.AWSLastEvaluatedKeySuperSet lastRunK,Integer cPass,boolean isTest,integer upsCount,string idofRec,string onObj)
    {
        setUp(cOrder, lastRunK,cPass,isTest,upsCount,idofRec,onObj);
    }
    public void setUp(integer cOrder, AWSDataLoad.AWSLastEvaluatedKeySuperSet lastRunK,Integer cPass,boolean isTest,integer upsCount,string idofRec,string onObj)
    {
        onObject = onObj;
        singleId = idOfRec;
        upsertCount = upsCount;
        isTestRun = isTest;
        currentPass = cPass;
        lastRunKey = lastRunK;
        system.Debug('---------------------------------------------------------------------------------------');
        system.debug('.........'+cOrder+'....'+lastRunK+'.......'+cPass+'....'+onObj+'.....'+idOfRec+'....');
        system.Debug('---------------------------------------------------------------------------------------');
        awsrec = null;
        if(singleId =='MATCHONLY')
        {
            for(AWS_Sync__c r:[Select Use_Query__c, Max_Limit__c ,Fields__c,Run_From__c,ID,Name, Table_Name__c, Order__c from AWS_Sync__c Where Name = 'Match' LIMIT 1])
                awsrec=r;
        }
        else if(singleId!=NULL && cOrder <100)
        {
            
            for(AWS_Sync__c r:[Select Use_Query__c, Max_Limit__c ,Fields__c,Run_From__c,ID,Name, Table_Name__c, Order__c from AWS_Sync__c Where Name = :onObject LIMIT 1])
                awsrec=r;
        }
        else if(lastRunKey==NULL)
        {
            for(AWS_Sync__c r:[Select Use_Query__c, Max_Limit__c ,Fields__c,Run_From__c,ID,Name, Table_Name__c, Order__c from AWS_Sync__c Where Order__c>:cOrder AND Skip__c=FALSE order By Order__c LIMIT 1])
                awsrec=r;
        }
        else
        {
            awsrec = [Select Use_Query__c, Fields__c, Max_Limit__c , Run_From__c,ID,Name, Table_Name__c, Order__c from AWS_Sync__c Where Order__c = :cOrder AND Skip__c=FALSE];
        }
        if(awsrec==NULL || currentPass>=200)
        {
            runMore = FALSE;    
            return;
        }    
        runMore = true;    
    }
    public void execute(QueueableContext context) 
    {
        if(runMore)
        {
            system.debug('OPERATION :'+awsrec.Name);    
            system.debug('LastRunKeyIS:'+lastRunKey);
            String scanBodyJSON = AWS_Query.getTableQuery(awsrec, lastRunKey,singleId);
            string soq= (singleId!=NULL && singleId!='')?'Query':'Scan';
            if(Torc_Constants__c.getInstance().AWS_Always_Query__c==TRUE && awsrec.Use_Query__c)
                soq = 'Query';
            system.debug('QUERY/SCAN JSON :'+scanBodyJSON);
            system.debug('QUERY OR SCAN :'+soq);    
            
            string body = AWS_Query.scanQueryTable(scanBodyJSON,istestRun,awsrec.Name,soq);
            body = AWSDataLoad.bodyreparse(body);
            if(singleId=='MATCHONLY') AWSDataLoad.onlyLoadmatchInShadow =true;
            
            lastRunKey = AWSDataLoad.loadNow(body, awsrec);
            system.debug('NEXT:LastRunKeyIS:'+lastRunKey);
            if(AWS_Query.isInValidLastKey(lastRunKey))
            {    
                lastRunKey = null;
                if(singleId==NULL)
                {
                    awsrec.Run_From__c = (awsrec.Max_Limit__c==NULL ||awsrec.Max_Limit__c==0)?Datetime.Now():awsrec.Run_From__c.adddays(Integer.valueOf(awsrec.Max_Limit__c));
                    update awsrec;
                }
                else
                    return;    
            }
            AWSDataLoaderQueue aq = new AWSDataLoaderQueue(awsrec.Order__c.IntValue(),lastRunKey,currentPass+1,isTestRun,upsertCount,singleId, onObject);
            if(!istestRun)
            {
                if(singleId==NULL ||  singleId=='MATCHONLY')
                    System.enqueueJob(aq);
            }
            else
                aq.execute(null); 
        }    
    }
}