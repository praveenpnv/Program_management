trigger DocusignStatusTrigger on dfsle__EnvelopeStatus__c(Before Insert, before Update)
{
    List<Opportunity> lst = new List<Opportunity>();
    for(dfsle__EnvelopeStatus__c rec:Trigger.New)
    {
        if(rec.dfsle__SourceId__c!=NULL && rec.dfsle__SourceId__c.length()>=15 && rec.dfsle__SourceId__c.left(3)=='006')
        {
            rec.Opportunity__c = rec.dfsle__SourceId__c;
            if(trigger.isInsert)
                lst.add(new Opportunity(id=rec.Opportunity__c, Latest_Docusign_ID__c = rec.dfsle__DocuSignId__c));
        }
        if(rec.dfsle__SourceId__c!=NULL && rec.dfsle__SourceId__c.length()>=15 && rec.dfsle__SourceId__c.left(3)=='001')
        {
            rec.Account__c = rec.dfsle__SourceId__c;
        }
        if(rec.dfsle__SourceId__c!=NULL && rec.dfsle__SourceId__c.length()>=15 && rec.dfsle__SourceId__c.left(3)=='a1U')
        {
            rec.Non_Torc_User__c = rec.dfsle__SourceId__c;
        }    
    }
    if(lst.size()>0)
        update lst;
}