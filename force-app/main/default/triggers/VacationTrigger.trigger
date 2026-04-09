trigger VacationTrigger on Engagement_Vacation__c(before insert, before update,after insert, after update, after delete) 
{
    if(Torc_Constants__c.getInstance().Disable_Engagement_vacation_Trigger__c) return;
    set<id>placementIds=new set<id>();
    List<Engagement_Vacation__c> l=trigger.isDelete?trigger.Old:trigger.new;
    for(Engagement_Vacation__c rec:l)
    {
        if((trigger.isInsert || trigger.isUpdate) && trigger.isBefore)
        {
            if(trigger.isInsert)
                rec.Placement__c=NULL;
                
            rec.Name = rec.User_Name__c.left(80);
            if(rec.Internal_Placement__c==NULL && rec.Opportunity__c==NULL)
            {
                rec.addError('Please select Internal Placement Or Opportunity');
            }
            else if(rec.Internal_Placement__c!=NULL && rec.Opportunity__c!=NULL)
            {
                rec.addError('Please select either Internal Placement Or Opportunity. Can not select both');
            }
            else 
            {
                decimal diff=(rec.Engagement_Duration_weeks__c-(rec.Engagement_Duration_weeks__c.intValue()));
                if(diff!=0 && diff!=0.2 && diff!=0.4 && diff!=0.6 && diff!=0.8)
                {
                    rec.addError('Vacation Duration week should be something like X.0, X.2, X.4, X.6 or X.8');
                    continue;
                }    
                if(trigger.isInsert || rec.Engagement_Start_Date__c!=trigger.oldMap.get(rec.id).Engagement_Start_Date__c
                                    || rec.Engagement_Duration_weeks__c!=trigger.oldMap.get(rec.id).Engagement_Duration_weeks__c)
                {                    
                    integer i=(Integer)rec.Engagement_Duration_weeks__c;
                    rec.Engagement_End_Date__c = rec.Engagement_Start_Date__c.adddays(Integer.valueOf(i*7)-1);
                    if(i<rec.Engagement_Duration_weeks__c)
                        rec.Engagement_End_Date__c = placement.addWorkingDays(rec.Engagement_End_Date__c,(Integer)((rec.Engagement_Duration_weeks__c-i)/0.2));
                }
                if(trigger.isInsert || (rec.Opportunity__c!=trigger.oldMap.get(rec.id).Opportunity__c)|| (rec.Internal_Placement__c!=trigger.oldMap.get(rec.id).Internal_Placement__c) || rec.Placement__c==NULL || rec.Shift_To_Date__c==NULL)
                {    
                    QBOpportunitySetup.updateVacationRecord(rec);
                }
                if(rec.Placement__c==NULL)
                {
                    rec.addError('Did not find right Placement for this vacation. Please make sure right closed Opportunity or Internal placement is selected where same Member is assigned.');
                }
                else if(trigger.isInsert || rec.Shift_To_Date__c!=trigger.oldMap.get(rec.id).Shift_To_Date__c || rec.Engagement_Duration_weeks__c!=trigger.oldMap.get(rec.id).Engagement_Duration_weeks__c)
                {                    
                    if(rec.Shift_To_Date__c!=NULL)
                    {
                        integer i=(Integer)rec.Engagement_Duration_weeks__c;
                        rec.Shift_To_End_Date__c = rec.Shift_To_Date__c.adddays(Integer.valueOf(i*7)-1);
                        if(i<rec.Engagement_Duration_weeks__c)
                            rec.Shift_To_End_Date__c = placement.addWorkingDays(rec.Shift_To_End_Date__c,(Integer)((rec.Engagement_Duration_weeks__c-i)/0.2));
                    }                            
                }      
            }
        }
        else
        {
            if(trigger.isDelete)
            {
                if(trigger.oldMap.get(rec.id).Placement__c!=NULL) placementIds.add(trigger.oldMap.get(rec.id).Placement__c);
            }
            else if((trigger.isInsert || trigger.isUpdate) && trigger.isAfter)
            {
                if(trigger.isInsert || 
                    (
                          rec.Engagement_Start_Date__c!=trigger.oldMap.get(rec.id).Engagement_Start_Date__c|| 
                          rec.Engagement_Duration_weeks__c!=trigger.oldMap.get(rec.id).Engagement_Duration_weeks__c  ||
                          rec.Shift_To_Date__c!=trigger.oldMap.get(rec.id).Shift_To_Date__c ||
                          rec.Placement__c!=trigger.oldMap.get(rec.id).Placement__c
                    ))
                {
                    if(rec.Placement__c!=NULL) placementIds.add(rec.Placement__c);
                    if(trigger.isUpdate && trigger.oldMap.get(rec.id).Placement__c!=NULL) placementIds.add(trigger.oldMap.get(rec.id).Placement__c);                    
                }  
            }
        }
    }
    if(placementIds.size()>0)
        placement.setupPlacementForecast(placementIds);
}