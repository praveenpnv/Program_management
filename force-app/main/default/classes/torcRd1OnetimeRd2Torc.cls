global class torcRd1OnetimeRd2Torc implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    global integer nextRun = 10;
    public static void process(string soql, integer delay, integer bSize)
    {
        torcRd1OnetimeRd2Torc myBatchObject = new torcRd1OnetimeRd2Torc(soql,delay); 
        Id batchId = Database.executeBatch(myBatchObject,bSize);
    }
    public string soqlQuery;
    public integer delaySec;
    Public torcRd1OnetimeRd2Torc(string soql,integer delay)
    {
        soqlQuery=soql;
        delaySec = delay;
    }
    global Database.QueryLocator start(Database.BatchableContext bc)
    { 
        return Database.getQueryLocator(soqlQuery);
    }

    global void execute(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
        List<Torc_API_Call__c> lstTorcAPICalls=new List<Torc_API_Call__c>();
        for(sObject tb:lstrecord)
        {
            contact tj=(contact)tb;
            Torc_API_Call__c rec=new Torc_API_Call__c(type__c='User',Contact__c=tj.id,Operation__c='INSERT');
            rec.Body__c = JSON.serialize(tj);
            lstTorcAPICalls.add(rec);
        }
        upsert lstTorcAPICalls;
        if(!Torc_Rd1_Integration__c.getInstance().Use_Flow_for_API_Call__c)
        {
            set<id> recids=new set<id>();
            for(Torc_API_Call__c r:lstTorcAPICalls)
                recIds.add(r.id);
            torcRD1Integrationbatch runSkipped=new torcRD1Integrationbatch(recids);
            Datetime runTime = datetime.Now().addseconds(nextRun);
            nextRun +=delaySec;
            String cronExp = String.format('{0} {1} {2} {3} {4} ? {5}', new List<String>{
                String.valueOf(runTime.second()),
                String.valueOf(runTime.minute()),
                String.valueOf(runTime.hour()),
                String.valueOf(runTime.day()),
                String.valueOf(runTime.month()),
                String.valueOf(runTime.year())
            });    
            System.schedule('torcIntegrate-'+userInfo.getuserId()+runTime.ToString(), cronExp, runSkipped);  
        }     
    }
    global void finish(Database.BatchableContext bc)
    {
    }
}