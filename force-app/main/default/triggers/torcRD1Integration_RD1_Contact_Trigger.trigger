trigger torcRD1Integration_RD1_Contact_Trigger on Contact(after insert, after update,before insert, before update) 
{
    if (UserInfo.getUsername() == 'dataloader@randstaddigital.com.uat') {
       return;
   }
   
    if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c && !Torc_Rd1_Integration__c.getinstance().Only_Connect_Operation__c) return;
    if(trigger.isBefore)
    {
        for(Contact rec:trigger.new)
        {
            if(trigger.isInsert || rec.Torc_Id__c!=NULL) rec.applicable_for_torc_sync__c = true;
            if(!torcRD1Integration.supportingOpco(rec.User_Opco__c) || rec.email==NULL) rec.applicable_for_torc_sync__c = false;
            
            if(trigger.isInsert ||rec.FirstName!=trigger.oldMap.get(rec.id).FirstName
                                ||rec.LastName!=trigger.oldMap.get(rec.id).LastName
                                ||rec.Mktg_Contact_OK__c!=trigger.oldMap.get(rec.id).Mktg_Contact_OK__c
                                ||rec.TR1__Candidate_Status__c!=trigger.oldMap.get(rec.id).TR1__Candidate_Status__c
                                ||rec.DO_NOT_USE__c!=trigger.oldMap.get(rec.id).DO_NOT_USE__c
                                ||rec.TR1__Notice_Period__c!=trigger.oldMap.get(rec.id).TR1__Notice_Period__c
                                ||rec.Notice_Period__c!=trigger.oldMap.get(rec.id).Notice_Period__c
                                ||rec.Whatsapp_Allowed__c!=trigger.oldMap.get(rec.id).Whatsapp_Allowed__c
                                ||rec.TR1__Desired_Hourly__c!=trigger.oldMap.get(rec.id).TR1__Desired_Hourly__c
                                ||rec.Desired_day_rate__c!=trigger.oldMap.get(rec.id).Desired_day_rate__c
                                ||rec.TR1__Desired_Salary__c!=trigger.oldMap.get(rec.id).TR1__Desired_Salary__c
                                ||rec.Years_of_experience__c!=trigger.oldMap.get(rec.id).Years_of_experience__c
                                ||rec.Availability_date__c!=trigger.oldMap.get(rec.id).Availability_date__c
                                ||rec.TR1__LinkedIn_ProfileUrl__c!=trigger.oldMap.get(rec.id).TR1__LinkedIn_ProfileUrl__c
                                ||rec.Phone!=trigger.oldMap.get(rec.id).Phone
                                ||rec.SkillUpdateTime__c!=trigger.oldMap.get(rec.id).SkillUpdateTime__c
                                ||rec.Last_Resume_Update__c!=trigger.oldMap.get(rec.id).Last_Resume_Update__c)
                rec.sync_request_time__c = datetime.now();                                                                
        }
    }
    else
    {
        torcRD1Integration.UpdateToTorc_user(trigger.oldMap,trigger.newmap,trigger.isInsert, trigger.isupdate);
        Map<id,torc_user__c>lst=new Map<id,torc_user__c>();
        for(Contact c:trigger.new)
        {
            if(c.Torc_User_ref__c!=NULL && (trigger.isInsert || c.Torc_User_ref__c!=trigger.oldmap.get(c.id).Torc_User_ref__c))
            {
                lst.put(c.Torc_User_ref__c,new torc_user__c(id=c.Torc_User_ref__c, RD1_Candidate__c=c.id,sfdcExternalId__c=c.id));
                
            }
        }    
        if(lst.values().size()>0)
        {
            torcRD1Integration.runningtorcCodeToUpdateData = true;
            torcRD1Integration.skipSFDCUpdateUSER = true;
            system.debug(lst.values());
            upsert lst.values();
            torcRD1Integration.skipSFDCUpdateUSER = false;
        }
    }
}