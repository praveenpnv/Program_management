trigger OpportunityStageChangeManage on Opportunity (before Insert, before Update) 
{
    if(Torc_Constants__c.getInstance().Disable_Opportunity_Trigger__c) return;
    for(Opportunity opp:Trigger.New)
    {
        if(opp.Torc_Opportunity__c)
        {
            if(trigger.isInsert || opp.StageName!=Trigger.oldmap.get(opp.id).Stagename)
            {
                if(opp.StageName=='Need Posted')
                    opp.Need_Posted_Date__c = DateTime.now();
                if(opp.StageName=='Interview(s) Scheduled')
                    opp.Interview_Scheduled_Date__c = DateTime.now();
                if(opp.StageName=='Agreement in Principle')
                    opp.Agreement_Date__c = DateTime.now();
                if(opp.StageName=='Buyer/Member Matched')
                    opp.Matched_Date__c = DateTime.now();
                if(opp.StageName=='Need Identified')
                    opp.Need_Identification_Date__c = DateTime.now();
                if(opp.StageName=='Closed Won')
                    opp.WON_Date__c = DateTime.now();            
                if(opp.StageName=='Closed Lost')
                    opp.Lost_Date__c = DateTime.now();             
            }
        }    
    }
}