public without sharing class torcRd1OnetimeRd2TorcController
{
    public String  soqlQuery       { get; set; }
    public Integer batchSize       { get; set; }
    public Boolean pollEnabled     { get; private set; }
    public Integer processedCount  { get; private set; }
    public Integer totalCount  { get; private set; }
    Public List<Contact> lstContacts{ get; private set; }

    public torcRd1OnetimeRd2TorcController() 
    {
        this.batchSize      = 75;
        this.pollEnabled    = false;
        this.processedCount = 0;
        totalCount = 0;
        lstContacts=new List<Contact>();
    }
    public PageReference startProcess() 
    {
        lstContacts = database.query(soqlQuery);
        processedCount = 0;
        totalCount = lstContacts.size();
        if (lstContacts.size() == 0) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No matching Contacts pending. Nothing to process.'));
            pollEnabled = false;
        } 
        else 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                'Queued ' + lstContacts.size() + ' Contacts.'));
            pollEnabled = true;
        }
        return null;
    }
    public void poll() 
    {
        processNextBatch();
        if (processedCount >= lstContacts.size()) 
        {
            pollEnabled = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Processing complete. Updated ' + processedCount + ' of ' + lstContacts.size() + ' Contacts.'));
        }
    }
    public Integer getRemainingCount() 
    {
        return Math.max(0, (lstContacts.size() - processedCount));
    }
    public Decimal getPercentDone() 
    {
        return (lstContacts.size() == 0) ? 0 : ( (Decimal.valueOf(processedCount) * 100) / Decimal.valueOf(lstContacts.size()) );
    }
    public void processNextBatch() 
    {
        system.debug('=========================START=========='+processedCount+'=====OF===='+lstContacts.size());
        List<Torc_API_Call__c> lstTorcAPICalls=new List<Torc_API_Call__c>();
        for(integer i=0;i<batchSize;i++)
        {
            if(processedCount>=lstContacts.size())
               break;
            contact tj=lstContacts[processedCount];
            Torc_API_Call__c rec=new Torc_API_Call__c(type__c='User',Contact__c=tj.id,Operation__c='INSERT');
            rec.Body__c = JSON.serialize(tj);
            lstTorcAPICalls.add(rec);
            processedCount++;
        }
        if(lstTorcAPICalls.size()>0)
        {
            upsert lstTorcAPICalls;
            set<id> recids=new set<id>();
            for(Torc_API_Call__c r:lstTorcAPICalls)
                recIds.add(r.id);
            System.enqueueJob(new torcRD1IntegrationQueue(recIds));
        }    
        system.debug('=========================END=========='+processedCount);        
    }
}