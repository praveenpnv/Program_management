Public class TrolleyReceipientQueue implements Queueable, database.AllowsCallouts
{
    public static void runProcess(boolean isTest)
    {
        System.enqueueJob(new TrolleyReceipientQueue(1,isTest));
    }
    public integer pageNumber;
    public boolean istestRun;
    public string singleRecId;
    public TrolleyReceipientQueue(integer pgN,boolean isTest)
    {
        pageNumber=pgN;
        istestRun = istest;
        singleRecId=null;
    }
    public TrolleyReceipientQueue(integer pgN,boolean isTest,string singleRecId1)
    {
        pageNumber=pgN;
        istestRun = istest;
        singleRecId= singleRecId1;
    }
    public void execute(QueueableContext context) 
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'RETRIVEREC';
            
        string reqpath = 'recipients';
        if(singleRecId!=NULL)
            reqpath += '/'+singleRecId;
        
        reqpath += '?page='+pageNumber+'&pageSize='+'50';
        
        string body = TrolleyBase.callAPI('GET',null,reqpath);
        JSONParser jp = JSON.createParser(body);
        TrolleyService.T_recipients t = (TrolleyService.T_recipients)jp.readValueAs(TrolleyService.T_recipients.class);
        
        
        if(singleRecId!=NULL)
        {
            t.recipients = new List<TrolleyService.T_recipient>();
            t.recipients.add(t.recipient);
        }
        system.debug(body);        
        system.debug(pageNumber+'---'+t.recipients.size());

        List<TrolleyService.T_recipient> lst = t.recipients;
        List<Trolley_Recipient__c> upsertList=new List<Trolley_Recipient__c>();
        for(TrolleyService.T_recipient trollyObj:lst)
        {
            upsertList.add(setupRecord(trollyObj));
        }
        upsert upsertList external_Id__c;
        
        if(t.recipients.size()>=50)
        {
            TrolleyReceipientQueue aq = new TrolleyReceipientQueue(pageNumber+1,istestRun);
            if(!istestRun)
                System.enqueueJob(aq);
        }        
    }
    public static Trolley_Recipient__c setupRecord(TrolleyService.T_recipient trollyObj)
    {
        Trolley_Recipient__c rec= new Trolley_Recipient__c();
        rec.external_Id__c = trollyObj.id;
        rec.referenceId__c = trollyObj.referenceId;
        rec.Name = trollyObj.name==NULL?'':trollyObj.name.left(80);
        rec.Last_Name__c = trollyObj.LastName;
        rec.First_Name__c = trollyObj.Firstname;
        rec.Payout_method__c = trollyObj.payoutMethod;
        rec.Status__c = trollyObj.status;
        rec.Country__c = (trollyObj.address!=NULL && trollyObj.address.country!=NULL)?trollyObj.address.country:NULL;
        rec.estimated_Fee__c = trollyObj.estimatedFees==Null?0:Decimal.valueOf(trollyObj.estimatedFees);
        if(trollyObj.accounts!=NULL && trollyObj.accounts.size()>0)
        {
            for(TrolleyService.T_account act:trollyObj.accounts)
            {
                if(Act.primary==true)
                    rec.Active_Payment_Account_ID__c = act.id;
            }
        }
        return rec;
    }    
}