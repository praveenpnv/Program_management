global class candidateStatusChangeHandleBatch implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    public static void processNow()
    {
        processNow(false);
    }
    public static void processNow(boolean onlyQueryDebug)
    {
        processNow('MAKEAVAILABLE',onlyQueryDebug);
        processNow('MAKESUSPENSE',onlyQueryDebug);
    }
    public static void processNow(string operationName,boolean onlyQueryDebug)
    {
        if(Torc_Constants__c.getInstance().Contact_Status_Automation__c)
        {
            candidateStatusChangeHandleBatch btch = new candidateStatusChangeHandleBatch(operationName,onlyQueryDebug); 
            Id batchId = Database.executeBatch(btch,200);
        }
    }
    public string operationName;
    public boolean onlyQueryDebug;
    Public candidateStatusChangeHandleBatch(string operationName1,boolean onlyQueryDebug1)
    {
        operationName = operationName1;
        onlyQueryDebug = onlyQueryDebug1;
    }
    global Database.QueryLocator start( Database.BatchableContext bc )
    { 
        
        
        String d90DaysAgo1 = DateTime.now().adddays(-90).formatGmt('yyyy-MM-dd');
        String d90DaysPast1 = DateTime.now().adddays(90).formatGmt('yyyy-MM-dd');
        String d7DaysAgo1 = DateTime.now().adddays(-7).formatGmt('yyyy-MM-dd');
        String d21DaysAgo1 = DateTime.now().adddays(-21).formatGmt('yyyy-MM-dd');
        String d21DaysAgoDT = DateTime.now().adddays(-21).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'z\'');        
        DateTime contactCreatedBy = Torc_Constants__c.getInstance().Contact_Status_Automation_Time__c;
        contactCreatedBy = contactCreatedBy==NULL?DateTime.now().adddays(-25):contactCreatedBy;
        string contactCreatedBy1 = contactCreatedBy.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'z\'');        
        
        string statusNew_Suspand = '(TR1__Candidate_Status__c=\'New\' OR TR1__Candidate_Status__c=\'Suspense\')';
        string soql = 'Select ID, TR1__Candidate_Status__c FROM Contact WHERE RecordType.Name = \'Candidate\' AND Createddate>='+contactCreatedBy1;
        
        
        IF(operationName=='MAKEAVAILABLE')
        {            
            string dateInterview = '((Date_of_the_First_Interview__c=TODAY OR Date_of_the_Second_Interview__c = TODAY) AND '+statusNew_Suspand+')';
        
            string dateAvailable = '((Availability_date__c<>NULL AND Availability_date__c < '+d90DaysPast1+' AND Availability_date__c >= TODAY)  AND '+statusNew_Suspand+')';
            
            string ClientInterview = '(Latest_Client_interview_Date__c<>NULL AND Latest_Client_interview_Date__c < '+d7DaysAgo1+' AND TR1__Candidate_Status__c=\'Interviewing\')';
        
            soql=soql+' AND (' + dateInterview+' OR '+dateAvailable+' OR '+ClientInterview+')';
        }
        IF(operationName=='MAKESUSPENSE')
        {
            string No_Note_Interview_AppBeyond = '( (Latest_Note_Date__c=NULL OR Latest_Note_Date__c<'+d21DaysAgo1+') AND '+
            '(Latest_Application_Beyond_Screen_Date__c=NULL OR Latest_Application_Beyond_Screen_Date__c<'+d21DaysAgo1+') AND  '+
            '(Latest_Interview_Date__c=NULL OR Latest_Interview_Date__c<'+d21DaysAgo1+') AND  '+            
            '(Date_of_the_First_Interview__c=NULL OR Date_of_the_First_Interview__c<'+d21DaysAgo1+') AND  '+
            '(Date_of_the_Second_Interview__c = null OR Date_of_the_Second_Interview__c<'+d21DaysAgo1+') AND  TR1__Candidate_Status__c=\'New\')';
            
            string No_Note_Interview_App = '( (Latest_Note_Date__c=NULL OR Latest_Note_Date__c<'+d90DaysAgo1+') AND '+
            '(Latest_Application_Date__c=NULL OR Latest_Application_Date__c<'+d90DaysAgo1+') AND  '+
            '(Latest_Interview_Date__c=NULL OR Latest_Interview_Date__c<'+d21DaysAgo1+') AND  '+            
            '(Date_of_the_First_Interview__c=NULL OR Date_of_the_First_Interview__c<'+d90DaysAgo1+') AND  '+
            '(Date_of_the_Second_Interview__c = null OR Date_of_the_Second_Interview__c<'+d90DaysAgo1+') AND  TR1__Candidate_Status__c=\'Available\')';
            
            soql=soql+' AND createdDate<'+d21DaysAgoDT+' AND (' + No_Note_Interview_AppBeyond+' OR '+No_Note_Interview_App +')';
            
            /*
            Latest_Application_Beyond_Screen_Date__c
            Latest_Application_Date__c
            Latest_Client_interview_Date__c
            Latest_Interview_Date__c
            Latest_Note_Date__c
            Latest_Candidate_Action_Note_Date__c
            Availability_date__c
            Date_of_the_First_Interview__c
            Date_of_the_Second_Interview__c
            */
        }
        if(Test.isRunningTest() || onlyQueryDebug)
            soql = soql+' LIMIT 10';
        system.debug('QUERY '+ operationName+' : '+ soql);
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
        for(sObject s:lstRecord)
        {
            contact c=(contact) s;
            system.debug('========');
            system.debug(c);
            IF(operationName=='MAKEAVAILABLE')
                c.TR1__Candidate_Status__c = 'Available';
            IF(operationName=='MAKESUSPENSE')
                c.TR1__Candidate_Status__c = 'Suspense';    
            system.debug(c); 
            system.debug('========');   
        }
        if(!onlyQueryDebug)
        {
            torcRD1Integration.alwaysRunQueue=TRUE;
            update lstRecord;
        }    
    }
  global void finish(Database.BatchableContext bc)
  {
  }
}