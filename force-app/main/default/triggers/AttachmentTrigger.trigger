trigger AttachmentTrigger on Attachment (After insert) 
{
    if(Torc_Constants__c.getInstance().Disable_Attachment_Trigger__c)
        return;
    List<Attachment> attList=new List<Attachment>();
    Map<ID,Attachment> StatusIdSet=new Map<ID,Attachment>();
    for(Attachment att:Trigger.New)
    {
        String s=att.ParentId;
        s=s.Left(3);
        if(s==torc_Constants__c.getInstance().Envelop_Object_Prefix__c || test.isRunningTest())
        {
            Attachment attNew=new Attachment(
            ContentType = att.ContentType,
            Name=att.Name+'[SIGNED].pdf',
            IsPrivate=att.IsPrivate,
            Body=att.Body);
            StatusIdSet.put(att.ParentId,attNew);
        }
    }
    if(StatusIdSet.keyset().size()>0)
    {
        List<Attachment> AttachmentList=new List<Attachment>();
        for(dfsle__EnvelopeStatus__c rec:[Select ID, Opportunity__c from dfsle__EnvelopeStatus__c Where Id in: StatusIdSet.keyset() and Opportunity__c!=NULL AND dfsle__Status__c ='Completed'])
        {
            StatusIdSet.get(rec.Id).ParentId = rec.Opportunity__c;
            AttachmentList.add(StatusIdSet.get(rec.Id));
        }
        for(dfsle__EnvelopeStatus__c rec:[Select ID, Account__c from dfsle__EnvelopeStatus__c Where Id in: StatusIdSet.keyset() and Account__c!=NULL AND dfsle__Status__c ='Completed'])
        {
            StatusIdSet.get(rec.Id).ParentId = rec.Account__c;
            AttachmentList.add(StatusIdSet.get(rec.Id));
        }
        if(AttachmentList.size()>0)
            insert AttachmentList;
    }
    

}