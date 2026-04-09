trigger opportunityProductTrigger on OpportunityLineItem (before Insert, before Update, before Delete,after insert, after update, after delete) 
{
    if(Torc_Constants__c.getInstance().Disable_Opportunity_Trigger__c) return;
    if(trigger.isBefore)
    {
        if(Trigger.isInsert || trigger.isUpdate)
        {
            Map<string,Torc_User__c>userNames = new Map<string,Torc_User__c>();
            set<id>tuIds=new set<id>();
            for(OpportunityLineItem rec:trigger.New)
            {
                if(rec.Talent_Username__c==NULL || rec.Talent_Username__c.trim()=='')
                {
                    rec.Torc_User__c = null;
                    rec.talent_Name__c = '';
                }
                else if(trigger.isInsert || (trigger.isUpdate && rec.Talent_Username__c!=trigger.OldMap.get(rec.id).Talent_Username__c) || rec.Torc_User__c==NULL)
                {
                    userNames.put(rec.Talent_Username__c.toLowerCase(),NULL);
                }
            }
            if(userNames.keyset().size()>0)
            {
                for(Torc_User__c tu:[Select ID, Name,Full_Name__c from Torc_User__c where Name in:userNames.keyset()])
                {
                    userNames.put(tu.Name.toLowerCase(),tu);
                    tuIds.add(tu.id);
                }
                for(OpportunityLineItem rec:trigger.New)
                {
                    
                    If(rec.Talent_Username__c==NULL || rec.Talent_Username__c.trim()=='')
                    {
                        rec.Torc_User__c = null;
                        rec.talent_Name__c = '';
                    }    
                    else if(trigger.isInsert || (trigger.isUpdate && rec.Talent_Username__c!=trigger.OldMap.get(rec.id).Talent_Username__c) || rec.Torc_user__c==NULL)
                    {
                        Torc_User__c tu = userNames.get(rec.Talent_Username__c.toLowerCase());
                        if(tu!=NULL)
                        {
                             rec.Torc_user__c = tu.id;
                             rec.Talent_Name__c = tu.Full_Name__c==NULL?'':tu.Full_Name__c.left(80);    
                        }     
                    }
                }    
            }
            if(tuIds.size()>0)
                OpportunityDocusignMemberRedirect.CreateMemberContact(tuIds);
         }  
         if(!Torc_Constants__c.getInstance().Skip_Placement__c)
             placement.oppLineItemAddEditUpdate(trigger.isInsert?NULL:trigger.oldMap,trigger.isDelete?NULL:trigger.new,trigger.isInsert,trigger.isUpdate,trigger.isDelete);
    }
    else if(!Torc_Constants__c.getInstance().Skip_Placement__c && trigger.isafter)
    {
        set<id>placementIds=new set<id>();
        if(trigger.isDelete)
        {
            for(OpportunityLineItem rec:trigger.Old)
                if(rec.Placement__c!=NULL)
                    placementIds.add(rec.Placement__c);
        }
        else
        {
            for(OpportunityLineItem rec:trigger.New)
            {
                if(trigger.IsInsert && rec.Placement__c!=NULL)
                    placementIds.add(rec.Placement__c);
                else if(trigger.IsUpdate)
                {
                    OpportunityLineItem orec=trigger.oldmap.get(rec.Id);
                    if(rec.Engagement_Start_Date__c != oRec.Engagement_Start_Date__c  
                        || rec.Engagement_End_Date__c != oRec.Engagement_End_Date__c  
                        || rec.Weekly_Bill_Rate__c !=orec.Weekly_Bill_Rate__c
                        || rec.Weekly_Talent_Rate__c !=orec.Weekly_Talent_Rate__c
                        || rec.Placement__c!=oRec.Placement__c)
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
            for(OpportunityLineItem  oli:trigger.new)
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
                                oli.Customer_Hourly_Bill_Rate__c!=trigger.oldmap.get(oli.id).Customer_Hourly_Bill_Rate__c ||
                                oli.Hours_Week__c!=trigger.oldmap.get(oli.id).Hours_Week__c))
                    placementids.add(oli.Placement__c);                                
            }
        }
        else
        {
            for(OpportunityLineItem  oli:trigger.old)
                if(oli.Placement__c!=NULL)
                    placementids.add(oli.Placement__c);
        }
        if(placementids.size()>0)
            placement.setupPlacementForecast(placementids);
    }
    
}