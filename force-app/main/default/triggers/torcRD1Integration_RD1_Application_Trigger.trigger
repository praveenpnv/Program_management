trigger torcRD1Integration_RD1_Application_Trigger on TR1__Application_V2__c (after insert, after update,before insert, before update) 
{
    if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
    if(trigger.isBefore)
    {
        for(TR1__Application_V2__c rec:trigger.new)
        {
            if(trigger.isInsert || 
                rec.TR1__Reject__c!=trigger.oldMap.get(rec.id).TR1__Reject__c ||
                rec.Rejection_root__c!=trigger.oldMap.get(rec.id).Rejection_root__c ||
                rec.TR1__Rejection_Reason__c!=trigger.oldMap.get(rec.id).TR1__Rejection_Reason__c ||
                rec.TR1__Stage__c!=trigger.oldMap.get(rec.id).TR1__Stage__c
              )
            {
                rec.sync_request_time__c = datetime.now();     
            }
        }
    }   
    else
        torcRD1Integration.UpdateToTorc_Match(trigger.oldMap,trigger.newmap);
}