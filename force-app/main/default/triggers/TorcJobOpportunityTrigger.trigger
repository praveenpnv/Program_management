trigger TorcJobOpportunityTrigger on Torc_Job_Opportunity__c (after insert, after update) 
{
    {
        Set<String> setToKeepDelete= new Set<String>();
        List<Torc_Job_Opportunity_Skill__c> lstToUpsert = new List<Torc_Job_Opportunity_Skill__c>();
        Set<id>userIds=new Set<Id>();
        for(Torc_Job_Opportunity__c tu:Trigger.New)
        {
            if(tu.Skills_Id__C!=NULL && (trigger.isInsert || tu.Skills_Id__C!=trigger.oldmap.get(tu.id).Skills_Id__C))
            {
                for(string s:tu.Skills_Id__C.split(','))
                {
                    string extkey = tu.External_Id__c+' = ' + s;
                    setToKeepDelete.add(extkey);
                    lstToUpsert.add(new Torc_Job_Opportunity_Skill__c(External_Id__c = extkey,Torc_Job_Opportunity__c=tu.id, Torc_Skill__r=new Torc_Skill__c(External_Id__c=s)));
                    userIds.add(tu.id);
                }
            }
        }
        if(trigger.isUpdate && userIds.size()>0)
        {
            for(List<Torc_Job_Opportunity_Skill__c> l:[Select ID from Torc_Job_Opportunity_Skill__c Where Torc_Job_Opportunity__c in:userIds and External_id__C NOT in:setToKeepDelete])
                delete l;
        }
        if(lstToUpsert.size()>0)
            upsert lstToUpsert External_Id__c;
    }
}