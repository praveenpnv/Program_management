trigger DocusignStatusAfterTrigger on dfsle__EnvelopeStatus__c(after insert, after update) 
{
    List<Non_Torc_user__c> lstntu=new List<Non_Torc_user__c>();
    
    MAP<String,string> MapEids=new MAP<String,string>();
    for(dfsle__EnvelopeStatus__c rec:trigger.new)
    {
        if((Trigger.IsInsert || (rec.dfsle__Status__c!=trigger.oldmap.get(rec.id).dfsle__Status__c)) 
            && rec.dfsle__DocuSignId__c!='' 
            && rec.dfsle__DocuSignId__c!=NULL)
                 MapEids.put(rec.dfsle__DocuSignId__c,rec.dfsle__Status__c);
    
        if(rec.Non_Torc_user__c!=NULL && (trigger.isInsert || trigger.oldmap.get(rec.id).Non_Torc_user__c==NULL))
                lstntu.add(new Non_Torc_user__c(id=rec.Non_Torc_user__c, Latest_DocuSign_Status__c =rec.id));
    
    }
    if(lstntu.size()>0)
        update lstntu;
    system.debug(MapEids);
    List<Account> lstAccount=new List<Account>();

    FOR(List<dfsle__Envelope__c> lst :[SELECT  dfsle__SourceId__c,dfsle__DocuSignId__c from dfsle__Envelope__c
                                    WHERE dfsle__DocuSignId__c in:MapEids.keyset()
                                        AND dfsle__EnvelopeConfiguration__c = :Torc_Constants__c.getInstance().MSA_Template_Id__c
                                        AND dfsle__SourceId__c!=NULL]
       )
       {
           system.debug(lst);
           for(dfsle__Envelope__c r:lst)
               if(r.dfsle__SourceId__c.left(3)=='001')
                   lstAccount.add(new Account(Id=r.dfsle__SourceId__c,MSA_Status__c = mapEids.get(r.dfsle__DocuSignId__c)));
       }                   
       system.debug(lstAccount);             
       if(lstAccount.size()>0)
           update lstAccount; 
}