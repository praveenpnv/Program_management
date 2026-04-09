global class QBAPICallBatch implements Database.Batchable<SObject>,Database.Stateful,Database.AllowsCallouts 
{
    public static void processNow(string groupName)
    {
        QBAPICallBatch myBatchObject = new QBAPICallBatch(groupName); 
        Id batchId = Database.executeBatch(myBatchObject,10);
    }
    public string groupNameToUse;
    Public QBAPICallBatch(string groupName)
    {
        groupNameToUse = groupName;
    }
    global Database.QueryLocator start( Database.BatchableContext bc )
    { 
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
        string s = 'Select ID, Name, Non_Torc_user__c, Sequence__c, Input__c,Output__c, Group__c,Processed__c,Delete__c FROM QB_API_Call__c WHERE Processed__c=FALSE AND Group__c=:groupNameToUse';
        return Database.getQueryLocator(s);
    }

    global void execute(Database.BatchableContext bc, List<SObject> lstRecord) 
    {
        QBHttpService qb = QBAccountingService.getQBHttpService();
        map<string,Non_Torc_user__c> mapnonTorc = new map<string,Non_Torc_user__c>();
        for(sObject tb:lstrecord)
        {
            QB_API_Call__c rec=(QB_API_Call__c)tb;
            string input = rec.Input__c;
            
            if(rec.Name=='bill')
                input = input.replace('[BILL_NUMBER_SFDC]',rec.Sequence__c);
            
            string recName = rec.name;
            if(rec.Delete__c)
                recName +='?operation=delete';
            try
            {
                if(rec.Name=='NonTorc-VendorQB')
                {
                    JSONParser jp = JSON.createParser((rec.Input__c));
                    QBAccountingService.QBVendor qbV = (QBAccountingService.QBVendor) jp.readValueAs(QBAccountingService.QBVendor.class);
                    qbV = QBAccountingService.createVendorinQb(qbV);
                    if(qbV!=NULL)
                    {
                        if(mapnonTorc.get(rec.Non_Torc_user__c)==NULL)
                            mapnonTorc.put(rec.Non_Torc_user__c,new Non_Torc_user__c(id=rec.Non_Torc_user__c));
                        Non_Torc_user__c tu= mapnonTorc.get(rec.Non_Torc_user__c);
                        tu.Quick_Books_vendor_Id__c = qbV.Id;
                        tu.Quickbooks_Vendor__c = qbV.DisplayName;
                    }
                }
                else if(rec.Name=='NonTorc-VendorTrolley')
                {
                    JSONParser jp = JSON.createParser((rec.Input__c));
                    TrolleyService.T_recipient tRec = (TrolleyService.T_recipient) jp.readValueAs(TrolleyService.T_recipient.class);
                    TrolleyService.createRecipient(tRec);
                    if(mapnonTorc.get(rec.Non_Torc_user__c)==NULL)
                        mapnonTorc.put(rec.Non_Torc_user__c,new Non_Torc_user__c(id=rec.Non_Torc_user__c));
                    Non_Torc_user__c tu= mapnonTorc.get(rec.Non_Torc_user__c);
                    tu.Trolley_Creation_Requested__c = true;
                }
                else
                {
                    rec.Output__c = qb.postObject(recName,input);
                }    
                rec.Processed__c = true;
            }
            catch(exception ex)
            {
                system.debug(ex);
            }
        }
        if(mapnonTorc.keyset().size()>0)
        {
            update mapnonTorc.values();
        }
        update lstRecord;
    }
  global void finish(Database.BatchableContext bc)
  {
  }
}