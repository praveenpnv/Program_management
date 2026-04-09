public class torcRD1IntegrationQueue implements Queueable, Database.AllowsCallouts 
{
    private Set<Id> recordIds;
    public torcRD1IntegrationQueue(Set<Id> recordIds) 
    {
        this.recordIds=recordIds;
    }
    public void execute(QueueableContext context) 
    {
        List<Torc_API_Call__c> lstRecord=database.query(torcRD1Integrationbatch.qry +' AND id in :recordIds');
        torcRD1Integrationbatch.runProcessNow(lstRecord);
    }
}