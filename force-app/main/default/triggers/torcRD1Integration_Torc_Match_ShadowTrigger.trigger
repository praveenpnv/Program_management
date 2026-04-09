trigger torcRD1Integration_Torc_Match_ShadowTrigger on Torc_Match_Shadow__c (before insert, before update,after insert, after update) 
{
    if(trigger.isBefore)
    {
        Set<String> usernames = new Set<String>();
        for (Torc_Match_Shadow__c rec : Trigger.new) 
        {
            if(trigger.isInsert || (trigger.isUpdate && rec.matcher__c!=trigger.oldmap.get(rec.id).matcher__c))
            {
                if (rec.matcher__c!=NULL && rec.matcher__c!='' ) 
                    usernames.add(rec.matcher__c.toLowercase());
                else
                    rec.Matcher_Torc_User__c = NULL;    
            }
        }
        Map<String, Id> userNameToIdMap = new Map<String, Id>();
        if (!usernames.isEmpty())
        {
            for (Torc_user__c user : [SELECT Id, Name,userName__c FROM Torc_user__c WHERE userName__c IN :usernames]) 
                userNameToIdMap.put(user.userName__c.toLowercase(), user.Id);
        }
        for (Torc_Match_Shadow__c rec : Trigger.new) 
        {
            if (rec.matcher__c!=NULL && rec.matcher__c!='' && userNameToIdMap.containsKey(rec.matcher__c.tolowercase())) 
                    rec.Matcher_Torc_User__c = userNameToIdMap.get(rec.matcher__c.tolowercase());
        }
        if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
        for(Torc_Match_Shadow__c rec:trigger.new)
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
    {
        if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
        torcRD1Integration.UpdateToRD1_Match(trigger.oldMap,trigger.newmap,trigger.isInsert, trigger.isupdate);   
    }    
}