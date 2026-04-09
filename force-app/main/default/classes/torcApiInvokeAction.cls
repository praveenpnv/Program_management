public with sharing class torcApiInvokeAction 
{
    @InvocableMethod(label='Notify External (Callout)' description='Builds payload and posts to external service.')
    public static void notify(List<Id> recordIds) 
    {
        if (recordIds == null || recordIds.isEmpty()) return;
        if(recordIds.size()<=30)
        {
            torcRD1Integrationbatch.runProcessNow(recordIds);
        }
        else
        {
            set<id> recids=new set<id>();
            for(id i:recordIds)
            {
                recids.add(i);
            }
            torcRD1Integrationbatch callAPI =new torcRD1Integrationbatch(recids);
            if(!test.isrunningTest())
                Database.executeBatch(callAPI,30); 
        }    
    }
}