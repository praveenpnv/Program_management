trigger TrolleyRecipientTrigger on Trolley_Recipient__c (before Insert, before Update) 
{
    Map<string,Torc_user__c>refIds = new Map<string,Torc_user__c>();
    Map<string,Non_Torc_user__c>refIdsN = new Map<string,Non_Torc_user__c>();
    for(Trolley_Recipient__c rec:trigger.new)
    {
        if(rec.Torc_user__c==NULL && rec.non_Torc_user__c==NULL)
        {
            refIds.put(rec.referenceId__c.toLowerCase(),null);
            refIdsN.put(rec.referenceId__c.toLowerCase(),null);
        }
    }
    for(Torc_user__c tu:[Select ID,external_Id__c from Torc_user__c where external_Id__c in:refIds.keyset()])
    {
        refIds.put(tu.external_id__c.toLowerCase(),tu);
    }
    for(Non_Torc_user__c tu:[Select ID,external_Id__c from Non_Torc_user__c where external_Id__c in:refIds.keyset()])
    {
        refIdsN.put(tu.external_id__c.toLowerCase(),tu);
    }
    for(Trolley_Recipient__c rec:trigger.new)
    {
        if(rec.Torc_user__c==NULL)
        {
            if(refIds.get(rec.referenceId__c.toLowerCase())!=NULL)
                rec.Torc_User__c=refIds.get(rec.referenceId__c.toLowerCase()).id;
        }
        if(rec.non_Torc_user__c==NULL)
        {
            if(refIdsN.get(rec.referenceId__c.toLowerCase())!=NULL)
                rec.non_Torc_User__c=refIdsN.get(rec.referenceId__c.toLowerCase()).id;
        }
    }
}