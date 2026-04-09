trigger InternalPlacementTrigger on Internal_Placement__c (before insert, before update, before delete, after insert, after update, after delete) 
{
    if(Torc_Constants__c.getInstance().Disable_Opportunity_Trigger__c) return;
    if(trigger.isBefore)
    {
        if(Trigger.isInsert || trigger.isUpdate)
        {
            for(Internal_Placement__c rec:Trigger.new)
            {
                if(trigger.isInsert) rec.Placement__c=NULL;
                rec.Name = (rec.User_Name__c+'-'+rec.Category__c).left(80);
                if(trigger.isInsert || rec.Engagement_Start_Date__c!=trigger.oldMap.get(rec.id).Engagement_Start_Date__c
                                    || rec.Engagement_Duration_weeks__c!=trigger.oldMap.get(rec.id).Engagement_Duration_weeks__c)
                {                    
                    integer i=(Integer)rec.Engagement_Duration_weeks__c;
                    rec.Engagement_End_Date__c = rec.Engagement_Start_Date__c.adddays(Integer.valueOf(i*7)-1);
                    if(i<rec.Engagement_Duration_weeks__c)
                        rec.Engagement_End_Date__c = placement.addWorkingDays(rec.Engagement_End_Date__c,(Integer)((rec.Engagement_Duration_weeks__c-i)/0.2));
                }       
            }
        }
        if(!Torc_Constants__c.getInstance().Skip_Placement__c)
             placement.InternalPlacementAddEditUpdate(trigger.isInsert?NULL:trigger.oldMap,trigger.isDelete?NULL:trigger.new,trigger.isInsert,trigger.isUpdate,trigger.isDelete);
    }
    else if(!Torc_Constants__c.getInstance().Skip_Placement__c && trigger.isafter)
    {
        set<id>placementIds=new set<id>();
        if(trigger.isDelete)
        {
            for(Internal_Placement__c rec:trigger.Old)
                if(rec.Placement__c!=NULL)
                    placementIds.add(rec.Placement__c);
        }
        else
        {
            for(Internal_Placement__c rec:trigger.New)
            {
                if(trigger.IsInsert && rec.Placement__c!=NULL)
                    placementIds.add(rec.Placement__c);
                else if(trigger.IsUpdate)
                {
                    Internal_Placement__c orec=trigger.oldmap.get(rec.Id);
                    if(rec.Engagement_Start_Date__c != oRec.Engagement_Start_Date__c  
                        || rec.Engagement_End_Date__c != oRec.Engagement_End_Date__c  
                        || rec.Weekly_Talent_Rate__c !=orec.Weekly_Talent_Rate__c
                        || rec.Placement__c!=oRec.Placement__c
                        || rec.Category__c!=oRec.Category__c
                        )
                        {
                            if(rec.Placement__c!=NULL)
                                placementIds.add(rec.Placement__c);
                            if(Orec.Placement__c!=NULL)
                                placementIds.add(oRec.Placement__c);
                        }
                }    
            }           
        }
        if(placementIds.size()>0)
            placement.setupPlacementData(placementIds);
    }
    
    
    if(trigger.isAfter)
    {
        set<id> placementids=new set<id>();
        if(!trigger.isDelete)
        {
            for(Internal_Placement__c  oli:trigger.new)
            {
                if(trigger.isInsert || oli.Placement__c!=trigger.oldmap.get(oli.id).Placement__c)
                {
                    if(oli.Placement__c!=null)placementids.add(oli.Placement__c);
                    if(trigger.isUpdate && trigger.oldmap.get(oli.id).Placement__c!=null)placementids.add(trigger.oldmap.get(oli.id).Placement__c);
                }
                if(trigger.isUpdate && (
                                oli.Engagement_Start_Date__c!=trigger.oldmap.get(oli.id).Engagement_Start_Date__c ||
                                oli.Engagement_End_Date__c!=trigger.oldmap.get(oli.id).Engagement_End_Date__c ||
                                oli.Talent_Hourly_Pay_Rate__c!=trigger.oldmap.get(oli.id).Talent_Hourly_Pay_Rate__c ||
                                oli.Category__c!=trigger.oldmap.get(oli.id).Category__c ||
                                oli.Hours_Week__c!=trigger.oldmap.get(oli.id).Hours_Week__c))
                    placementids.add(oli.Placement__c);                                
            }
        }
        else
        {
            for(Internal_Placement__c  oli:trigger.old)
                if(oli.Placement__c!=NULL)
                    placementids.add(oli.Placement__c);
        }
        if(placementids.size()>0)
            placement.setupPlacementForecast(placementids);
    }
}