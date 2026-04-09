trigger TorcUserTrigger on Torc_User__c (after insert, after update) 
{
    Set<String> setToKeepDelete= new Set<String>();
    Map<String,Torc_User_Skill__c> lstToUpsert = new Map<String,Torc_User_Skill__c>();
    Set<id>userIds=new Set<Id>();
    for(Torc_User__c tu:Trigger.New)
    {
        if(trigger.isInsert || tu.Skills_Id__C!=trigger.oldMap.get(tu.id).Skills_Id__C || tu.Skill_Experience__c!=trigger.oldMap.get(tu.id).Skill_Experience__c)
        {        
            if(tu.Skills_Id__C!=NULL)
            {
                List<string> skIds=tu.Skills_Id__C.split(',');
                List<string> skExps=new List<string>();
                if(tu.Skill_Experience__c!=NULL)
                    skExps = tu.Skill_Experience__c.split(',');
                
                for(integer i=0;i<skIds.size();i++)
                {
                    string s = skIds[i];
                    string extkey = tu.External_Id__c+' = ' + s;
                    setToKeepDelete.add(extkey);
                    Torc_User_Skill__c tus = new Torc_User_Skill__c(External_Id__c = extkey,Torc_User__c=tu.id, Torc_Skill__r=new Torc_Skill__c(External_Id__c=s));
                    if(skExps.size()>i)
                        tus.Experience__c = skExps[i];
                    lstToUpsert.put(extkey,tus);
                    userIds.add(tu.id);
                }
            }
            else
                userIds.add(tu.id);
        }
    }
    if(trigger.isUpdate)
    {
        for(List<Torc_User_Skill__c> l:[Select ID from Torc_User_Skill__c Where Torc_User__c in:userIds and External_id__C NOT in:setToKeepDelete])
            delete l;
    }
    upsert lstToUpsert.values() External_Id__c;
}