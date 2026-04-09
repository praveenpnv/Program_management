trigger torcRD1Integration_RD1_Job_Trigger on TR1__Job__c(after insert, after update,before insert, before update) 
{
    if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
    if(trigger.isBefore)
    {
        for(TR1__Job__c rec:trigger.new)
        {
            if(trigger.isInsert)rec.Torc_Id__c=NULL;
            if(trigger.isInsert ||rec.Torc_Id__c!=NULL) rec.applicable_for_torc_sync__c = true;
            if(!torcRD1Integration.supportingOpco(rec.User_Opco__c)) rec.applicable_for_torc_sync__c = false;
            
            if(trigger.isinsert ||rec.Torc_Job_Type__c!=trigger.oldMap.get(rec.id).Torc_Job_Type__c
                                || torcRD1integrationMapping.isAddressChanged(rec,trigger.oldMap.get(rec.id))
                                ||rec.Responsible_Recruiter__c!=trigger.oldMap.get(rec.id).Responsible_Recruiter__c
                                ||rec.Remote_Work_Mode__c!=trigger.oldMap.get(rec.id).Remote_Work_Mode__c
                                ||rec.TR1__Status__c!=trigger.oldMap.get(rec.id).TR1__Status__c
                                ||rec.Primary_Timezone__c!=trigger.oldMap.get(rec.id).Primary_Timezone__c
                                ||rec.TR1__Closed_Reason__c!=trigger.oldMap.get(rec.id).TR1__Closed_Reason__c
                                ||rec.timeOverlap__c!=trigger.oldMap.get(rec.id).timeOverlap__c
                                ||rec.Job_Type__c!=trigger.oldMap.get(rec.id).Job_Type__c
                                ||rec.Torc_Organization__c!=trigger.oldMap.get(rec.id).Torc_Organization__c
                                ||rec.TR1__Client_Job_Description__c!=trigger.oldMap.get(rec.id).TR1__Client_Job_Description__c
                                ||rec.TR1__Experience_Requirements__c!=trigger.oldMap.get(rec.id).TR1__Experience_Requirements__c
                                ||rec.TR1__Responsibilities__c!=trigger.oldMap.get(rec.id).TR1__Responsibilities__c
                                ||rec.TR1__Number_of_Openings__c!=trigger.oldMap.get(rec.id).TR1__Number_of_Openings__c
                                ||rec.TR1__Job_Title__c!=trigger.oldMap.get(rec.id).TR1__Job_Title__c
                                ||rec.TR1__Years_of_Experience__c!=trigger.oldMap.get(rec.id).TR1__Years_of_Experience__c
                                ||rec.Job_priority__c!=trigger.oldMap.get(rec.id).Job_priority__c
                                ||rec.TR1__Maximum_Pay_Rate__c!=trigger.oldMap.get(rec.id).TR1__Maximum_Pay_Rate__c
                                ||rec.TR1__Minimum_Pay_Rate__c!=trigger.oldMap.get(rec.id).TR1__Minimum_Pay_Rate__c
                                ||rec.TR1__Salary_High__c!=trigger.oldMap.get(rec.id).TR1__Salary_High__c
                                ||rec.TR1__Salary_Low__c!=trigger.oldMap.get(rec.id).TR1__Salary_Low__c
                                ||rec.TR1__Estimated_Start_Date__c!=trigger.oldMap.get(rec.id).TR1__Estimated_Start_Date__c
                                ||rec.TR1__Estimated_End_Date__c!=trigger.oldMap.get(rec.id).TR1__Estimated_End_Date__c
                                ||rec.Workregime__c!=trigger.oldMap.get(rec.id).Workregime__c
                                ||rec.TR1__Account_Name__c!=trigger.oldMap.get(rec.id).TR1__Account_Name__c
                                ||rec.Internal_Notes_Long__c!=trigger.oldMap.get(rec.id).Internal_Notes_Long__c
                                ||rec.Torc_Location_Type__c!=trigger.oldMap.get(rec.id).Torc_Location_Type__c
                                ||rec.Developer_Region__c!=trigger.oldMap.get(rec.id).Developer_Region__c
                                ||rec.Developer_Countries__c!=trigger.oldMap.get(rec.id).Developer_Countries__c
                                ||rec.Torc_Search_Country__c!=trigger.oldMap.get(rec.id).Torc_Search_Country__c
                                ||rec.Torc_Search_State__c!=trigger.oldMap.get(rec.id).Torc_Search_State__c
                                ||rec.Torc_Search_City__c!=trigger.oldMap.get(rec.id).Torc_Search_City__c
                                ||rec.End_Client__c!=trigger.oldMap.get(rec.id).End_Client__c
                                ||rec.TR1__Account__c!=trigger.oldMap.get(rec.id).TR1__Account__c
                                ||rec.SkillUpdateTime__c!=trigger.oldMap.get(rec.id).SkillUpdateTime__c
                                ||rec.applicable_for_torc_sync__c!=trigger.oldMap.get(rec.id).applicable_for_torc_sync__c
                                ||(rec.Torc_id__c==NULL && rec.applicable_for_torc_sync__c)
                                
                                )
                        rec.sync_request_time__c = datetime.now();     
            
        }
    }
    else
        torcRD1Integration.UpdateToTorc_Job(trigger.oldMap,trigger.newmap,trigger.isInsert, trigger.isupdate);
}