trigger torcRD1Integration_Task_Trigger on Task (after insert) 
{
if(Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c)
{
    List<Task> lstToProcess=new List<Task>();
    Map<string,Contact>mapcontact=new Map<string,Contact>();
    Map<string,TR1__Job__c>mapJob=new Map<string,TR1__Job__c>();
    for(Task rec:trigger.new)
    {
        string s= torcRD1Integration.getrecordidFromTR1Location(rec.TR1__Location__c);
        if(s!=NULL && rec.Subject=='Notes' && rec.Torc_Id__c==NULL)
        {
            mapcontact.put(s,null);
            mapJob.put(s,null);
        }     
    }
    if(mapcontact.keyset().size()>0)
    {
        for(Contact c:[Select id,Torc_Id__c from Contact where id in:mapcontact.keyset() AND Torc_Id__c!=NULL AND Torc_Id__c!=''])
            mapcontact.put(c.id,c);
        for(TR1__Job__c c:[Select id,Torc_Id__c from TR1__Job__c where id in:mapcontact.keyset() AND Torc_Id__c!=NULL AND Torc_Id__c!=''])
            mapJob.put(c.id,c);
        for(Task rec:trigger.new)
        {
            string s= torcRD1Integration.getrecordidFromTR1Location(rec.TR1__Location__c);
            if(s!=NULL && (mapcontact.get(s)!=NULL || mapJob.get(s)!=NULL))
            {
                lstToProcess.add(rec);
            }
        }
        if(lstToProcess.size()>0)
            torcRD1Integration.UpdateToTorc_Notes(lstToProcess,mapcontact,mapJob);                     
    }
}
}