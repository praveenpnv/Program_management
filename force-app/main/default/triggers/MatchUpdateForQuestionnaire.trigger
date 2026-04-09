trigger MatchUpdateForQuestionnaire on Torc_Match__c (after update, after insert,before insert, before update) 
{
    if(trigger.isBefore)
    {
        system.debug('=======IN MatchUpdateForQuestionnaire BEFORE');
        List<Torc_Match__c> lstToWork = new List<Torc_Match__c>();
        set<id>torcJobOpportunityids=new set<id>();
        for(Torc_Match__c tm:trigger.new)
        {
            if(tm.Torc_Job_Opportunity__c!=NULL && tm.Torc_User_Ref__c != NULL && tm.Status__c=='ACCEPTED' && (trigger.isInsert || tm.Status__c!=trigger.oldmap.get(tm.id).Status__c))
            {
                lstToWork.add(tm);
                torcJobOpportunityids.add(tm.Torc_Job_Opportunity__c);
            }
        }    
        system.debug(lstToWork);
        if(torcJobOpportunityids.size()>0)
        {
            Map<id,Torc_job_opportunity__c> JobMap= new Map<id,Torc_job_opportunity__c>([Select id, 
                                                (Select id, EOR_OR_IC__c 
                                                 from opportunities__r 
                                                 where isWon=TRUE Order by Closedate DESC LIMIT 1) 
                                             From Torc_job_opportunity__c 
                                             where id in :torcJobOpportunityids]);

           for(Torc_Match__c tm: lstToWork)
           {
               Torc_job_opportunity__c tj = JobMap.get(tm.Torc_Job_Opportunity__c);
               opportunity opp = tj.opportunities__r.size()>0?tj.opportunities__r[0]:null;
               system.debug(tm);
               system.debug(tj);
               system.debug(opp);
               tm.EOR_OR_IC__c = opp==NULL?NULL:opp.EOR_OR_IC__c;
           }
        }
    }
    else
    {
        Map<id,Torc_User__c> maptu= new Map<id,Torc_User__c>();
        for(Torc_Match__c tm:trigger.new)
        {
            if(tm.Send_Questionnaire_check__c && tm.Torc_User_Ref__c != NULL && tm.Status__c=='ACCEPTED' && (trigger.isInsert || tm.Status__c!=trigger.oldmap.get(tm.id).Status__c))
                maptu.put(tm.Torc_User_Ref__c,new Torc_User__c(id=tm.Torc_User_Ref__c, Latest_Accepted_Match__c=tm.id));
        }
        if(maptu.values().size()>0)
            update maptu.values();
    }         
}