trigger TorcHistoryTrigger on Torc_History__c (after insert, after update) 
{
    MAP<id,Torc_Job_Opportunity__c> lstJO = new MAP<ID,Torc_Job_Opportunity__c>();
    Map<Id,Torc_Match__c> lstM = new Map<Id,Torc_Match__c>();
    for(Torc_History__c rec:trigger.New)
    {
        if(rec.Torc_Job_Opportunity__c!=NULL && rec.Attribute__c=='status')
        {
             if(lstJO.get(rec.Torc_Job_Opportunity__c)==NULL)
                lstJO.put(rec.Torc_Job_Opportunity__c, new Torc_Job_Opportunity__c(id=rec.Torc_Job_Opportunity__c));
             if(rec.NewValue__c =='ACTIVE')
                 lstJO.get(rec.Torc_Job_Opportunity__c).Activated_At__c=rec.createdAt__c;
             if(rec.NewValue__c =='PENDINGAPPROVAL')
                 lstJO.get(rec.Torc_Job_Opportunity__c).PENDINGAPPROVAL_At__c=rec.createdAt__c;    
        }
        if(rec.Torc_Match__c!=NULL && rec.Attribute__c=='status')
        {
            if(lstM.get(rec.Torc_Match__c)==NULL)
                lstM.put(rec.Torc_Match__c, new Torc_Match__c(id=rec.Torc_Match__c));
            if(rec.NewValue__c=='APPLIED')
               lstM.get(rec.Torc_Match__c).Applied_At__c =  rec.createdAt__c;
            if(rec.NewValue__c=='MATCHED')
               lstM.get(rec.Torc_Match__c).Match_At__c =  rec.createdAt__c;   
            
            if(rec.NewValue__c=='ACCEPTED')
               lstM.get(rec.Torc_Match__c).ACCEPTED_At__c =  rec.createdAt__c;   
            if(rec.NewValue__c=='MOREINFO')
               lstM.get(rec.Torc_Match__c).MOREINFO_At__c =  rec.createdAt__c;   
            if(rec.NewValue__c=='SHORTLISTED')
               lstM.get(rec.Torc_Match__c).SHORTLISTED_At__c =  rec.createdAt__c;   
            if(rec.NewValue__c=='SKIPPED')
               lstM.get(rec.Torc_Match__c).SKIPPED_At__c =  rec.createdAt__c;   
            if(rec.NewValue__c=='REJECTEDBYCUSTOMER' || rec.NewValue__c=='REJECTEDBYMEMBER')
               lstM.get(rec.Torc_Match__c).REJECTED_At__c =  rec.createdAt__c;   
        }
    }
    if(lstJO.values().size()>0)
        update lstJO.values();
    if(lstM.values().size()>0)
        update lstM.values();    
}