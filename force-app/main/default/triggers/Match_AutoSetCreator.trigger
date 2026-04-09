trigger Match_AutoSetCreator on Torc_Match__c (before insert, before update) 
{
    Set<String> usernames = new Set<String>();
    for (Torc_Match__c rec : Trigger.new) 
    {
        if(trigger.isInsert || (trigger.isUpdate && rec.creator__c!=trigger.oldmap.get(rec.id).creator__c))
        {
            if (rec.creator__c!=NULL && rec.creator__c!='' ) 
                usernames.add(rec.creator__c.toLowercase());
            else
                rec.Creator_Torc_User__c = NULL;    
        }
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
    for (Torc_Match__c rec : Trigger.new) 
    {
        if (rec.creator__c!=NULL && rec.creator__c!='' && userNameToIdMap.containsKey(rec.creator__c.tolowercase())) 
                rec.Creator_Torc_User__c = userNameToIdMap.get(rec.creator__c.tolowercase());
        if (rec.matcher__c!=NULL && rec.matcher__c!='' && userNameToIdMap.containsKey(rec.matcher__c.tolowercase())) 
                rec.Matcher_Torc_User__c = userNameToIdMap.get(rec.matcher__c.tolowercase());
    }
}