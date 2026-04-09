trigger DocusignEnvolopTrigger on dfsle__Envelope__c (Before Insert, before Update,after insert, after update)
{
    List<Non_Torc_user__c> lstntu=new List<Non_Torc_user__c>();
    for(dfsle__Envelope__c rec:Trigger.New)
    {
        if(trigger.isBefore)
        {
            if(rec.dfsle__SourceId__c!=NULL && rec.dfsle__SourceId__c.length()>=15 && rec.dfsle__SourceId__c.left(3)=='006')
                rec.Opportunity__c = rec.dfsle__SourceId__c;
            if(rec.dfsle__SourceId__c!=NULL && rec.dfsle__SourceId__c.length()>=15 && rec.dfsle__SourceId__c.left(3)=='a1U')
                rec.Non_Torc_user__c = rec.dfsle__SourceId__c;
        }
        else
        {
            if(rec.Non_Torc_user__c!=NULL && (trigger.isInsert || trigger.oldmap.get(rec.id).Non_Torc_user__c==NULL))
                lstntu.add(new Non_Torc_user__c(id=rec.Non_Torc_user__c, Latest_DocuSign_Envelope__c =rec.id));
        }
    }
    if(lstntu.size()>0)
        update lstntu;

}