trigger torcRD1Integration_Torc_Match_Trigger on Torc_Match__c (after insert, after update,before insert, before update) 
{
    /*if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
    if(trigger.isBefore)
    {
        for(Torc_Match__c rec:trigger.new)
        {
            if(trigger.isinsert ||rec.Status__c!=trigger.oldMap.get(rec.id).Status__c
                                ||rec.subStatus__c!=trigger.oldMap.get(rec.id).subStatus__c
                                ||rec.reasonForRejection__c!=trigger.oldMap.get(rec.id).reasonForRejection__c
                                ||rec.freelancerPitch__c!=trigger.oldMap.get(rec.id).freelancerPitch__c
                                ||rec.Delete_From_Platform__c!=trigger.oldMap.get(rec.id).Delete_From_Platform__c
                                )
                                
                        rec.sync_request_time__c = datetime.now();     
            
        }
    }
    else
        torcRD1Integration.UpdateToRD1_Match(trigger.oldMap,trigger.newmap,trigger.isInsert, trigger.isupdate);*/
}