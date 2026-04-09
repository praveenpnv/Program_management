trigger OpportunityPlatformUpdate on Opportunity (after insert,after update) 
{
    if(Torc_Constants__c.getInstance().Disable_Opportunity_Trigger__c) return;
    Set<Id> oppIds = new Set<Id>();
    Set<Id> joboppIds = new Set<Id>();
    for(Opportunity opp:trigger.new)
    {
        if(opp.Torc_Opportunity__c)
        {
            if(opp.Amount >0 && opp.IsWon && opp.Job_Opportunity__c!=NULL && (trigger.isInsert || trigger.oldMap.get(opp.id).isWon==FALSE))
            {
                oppIds.add(opp.id);
                joboppIds.add(opp.Job_Opportunity__c);
            }
            if(opp.Amount>0 && opp.StageName=='Closed Lost' && opp.Job_Opportunity__c!=NULL && (trigger.isInsert || trigger.oldMap.get(opp.id).StageName!='Closed Lost'))
            {
                oppIds.add(opp.id);
                joboppIds.add(opp.Job_Opportunity__c);
            }
        }
    }
    if(oppIds.size()>0 && Torc_Constants__c.getInstance().Disable_Opportunity_Platform_Update__c==False)
    {
        base_HttpService.OpportunityStatucChange(oppIds,joboppIds);
    }

}