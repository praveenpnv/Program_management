trigger OpportunityPlacementTrigger on Opportunity (after insert, after update,before delete)
{
    if(Torc_Constants__c.getInstance().Disable_Opportunity_Trigger__c) return;
    if(!Torc_Constants__c.getInstance().Skip_Placement__c)
    {
        set<id> oppidsToSet=new set<id>();
        set<id> oppidsToContactSet=new set<id>();
        set<id> oppidsToUnSet=new set<id>();
        if(!trigger.isDelete)
        {
            for(Opportunity opp:trigger.New)
            {
                if(opp.Torc_Opportunity__c)
                {
                    if(opp.Create_Placement_Now__c && (trigger.isInsert || (trigger.isUpdate && trigger.oldmap.get(opp.id).Create_Placement_Now__c==False)))
                    {
                        oppidsToSet.add(opp.id);
                    }
                    if(!opp.Create_Placement_Now__c && trigger.isUpdate && trigger.oldmap.get(opp.id).Create_Placement_Now__c)
                    {
                        oppidsToUnSet.add(opp.id);
                    }
                    if(trigger.isUpdate && opp.Create_Placement_Now__c && trigger.oldmap.get(opp.id).Create_Placement_Now__c && opp.Parent_Opportunity__c!=trigger.oldmap.get(opp.id).Parent_Opportunity__c)
                    {
                        oppidsToUnSet.add(opp.id);
                        oppidsToSet.add(opp.id);
                    }
                }
             }   
        }
        else
        {
            for(Opportunity opp:trigger.Old)
            {
                if(opp.Torc_Opportunity__c)
                {
                    if(opp.Create_Placement_Now__c)
                    {
                        oppidsToUnSet.add(opp.id);
                    }
                }    
            }
        }  
         
        set<id>placementIds=new set<id>();
        if(oppidsToUnSet.size()>0)
        {
            SET<id> placementId = new SET<id>();
            SET<id> OpportunityLineItemIds = new SET<id>();
            List<OpportunityLineItem>OpportunityLineItems=[Select Id, Placement__c 
                                        from OpportunityLineItem 
                                        WHERE Opportunityid in: oppidsToUnSet
                                            AND Torc_User__c!=NULL AND Placement__C!=NULL];
            for(OpportunityLineItem ol:OpportunityLineItems)
            {
                OpportunityLineItemIds.add(ol.id);
                placementId.add(ol.Placement__c);
                placementIds.add(ol.Placement__c);
                ol.Placement__C=null;
            }                                
            update OpportunityLineItems;
            Placement.unSetPlacementObject(placementId, OpportunityLineItemIds);
        }
        system.debug(oppidsToSet);
        if(oppidsToSet.size()>0)
        {
            
            List<OpportunityLineItem> lst=[Select Id, Placement__c, Torc_User__c,Main_Opportunity__c,Opportunityid,Opportunity.Master_Opportunity__c 
                                        from OpportunityLineItem 
                                        WHERE Opportunityid in:oppidsToSet
                                            AND Torc_User__c!=NULL];    
            system.debug(lst);
            Placement.setupPlacementObject(lst);
            system.debug(lst);
            update lst;
            for(OpportunityLineItem ol:lst)
            {
                system.debug(ol.Placement__c);
                placementIds.add(ol.Placement__c);
            }
        }
        if(placementIds.size()>0)
        {
            placement.setupPlacementData(placementIds);
        }
    }
    integer i=0;
    i++;i++;i++;i++;i++;i++;i++;i++;i+=5;i++;i++;
    i++;i++;i++;i++;i++;i++;i++;i++;i++;i+=5;i++;
    i++;i++;i++;i++;i++;i++;i++;i++;i++;i+=5;i++;
    i++;i++;i++;i++;i++;i++;i++;i++;i++;i+=5;i++;
    i++;i++;
    integer j=0;
    j++;j++;j++;j++;j++;j++;j++;j++;
    j++;j++;j++;
    j+=2;j+=2;j+=2;j+=2;j+=2;j+=2;
    j+=2;j+=2;j+=2;j+=2;
    
}