global class AWSCleanup implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    public static void processNow()
    {
        processNow('AWS_Event__c',4);
        processNow('Log_API_Data__c',4);
        processNow('Torc_User__c',4);
        processNow('Torc_API_Call__c',4);
        processNow('RD_Change_Event_Log__c',15);
    }
    public static void processNow(string objectName,integer nodays)
    {
        AWSCleanup btch = new AWSCleanup(objectname,nodays); 
        Id batchId = Database.executeBatch(btch,10000);
    }
    public string objName;
    public integer numberOfdays;
    Public AWSCleanup(string objectName,integer nodays)
    {
        objName = objectName;
        numberOfdays = nodays;
    }
    global Database.QueryLocator start( Database.BatchableContext bc )
    { 
        Date dt = date.today().adddays(numberOfdays*-1);
        string s = 'Select ID FROM '+ objName +' WHERE CreatedDate <:dt';
        IF(objName=='Torc_User__c')
        {
            s = s+' AND Delete_From_Platform__c = TRUE ';
        }
        if(Test.isRunningTest())
            s = s+' LIMIT 10';
        system.debug('QUERY : '+ s);
        return Database.getQueryLocator(s);
    }

    global void execute(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
        system.debug('Rcords:'+lstRecord.size());
        delete lstRecord;
    }
  global void finish(Database.BatchableContext bc)
  {
  }
}