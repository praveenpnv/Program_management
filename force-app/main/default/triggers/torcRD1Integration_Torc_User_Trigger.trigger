trigger torcRD1Integration_Torc_User_Trigger on Torc_User__c (after insert, after update,before insert, before update) 
{
    if(Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c==FALSE && Torc_Rd1_Integration__c.getinstance().Only_Connect_Operation__c==FALSE) return;
    if(trigger.isBefore)
    {
        for(Torc_User__c rec:trigger.new)
        {
            system.debug(rec.email__c);
            system.debug(rec.given_Name__c);
            system.debug(rec.sync_Request_Time__c);
            if(trigger.isInsert ||rec.given_Name__c!=trigger.oldMap.get(rec.id).given_Name__c
                                ||rec.status__c!=trigger.oldMap.get(rec.id).status__c
                                ||rec.agreedToMarketing__c!=trigger.oldMap.get(rec.id).agreedToMarketing__c
                                ||rec.family_name__c!=trigger.oldMap.get(rec.id).family_name__c
                                ||rec.email__c!=trigger.oldMap.get(rec.id).email__c
                                ||rec.userName__c!=trigger.oldMap.get(rec.id).userName__c
                                ||rec.linkedin__c!=trigger.oldMap.get(rec.id).linkedin__c
                                ||rec.noticePeriod__c!=trigger.oldMap.get(rec.id).noticePeriod__c
                                ||rec.WhatsAppAllowed__c!=trigger.oldMap.get(rec.id).WhatsAppAllowed__c
                                ||rec.ratePerHour__c!=trigger.oldMap.get(rec.id).ratePerHour__c
                                ||rec.salary__c!=trigger.oldMap.get(rec.id).salary__c
                                ||rec.overallExperience__c!=trigger.oldMap.get(rec.id).overallExperience__c
                                ||rec.sfdcExternalID__c!=trigger.oldMap.get(rec.id).sfdcExternalID__c                                
                                ||rec.resumelocation__c!=trigger.oldMap.get(rec.id).resumelocation__c                                
                                ||rec.userType__c!=trigger.oldMap.get(rec.id).userType__c
                                ||(rec.resumeuploadedByRD__c ==FALSE && rec.resumeUpdateTime__c!=trigger.oldMap.get(rec.id).resumeUpdateTime__c)
                                )
                rec.sync_request_time__c = datetime.now();
           if(rec.sfdcExternalID__c!=NULL && rec.sfdcExternalID__c!='' && rec.sfdcExternalID__c.length()==18 && rec.sfdcExternalID__c.left(3)=='003')
               rec.RD1_Candidate__c = rec.sfdcExternalID__c;
           system.debug(rec.sync_Request_Time__c);    
        }
    }
    else
        torcRD1Integration.UpdateToRD1_User(trigger.oldMap,trigger.newmap,trigger.isInsert, trigger.isupdate);
}