trigger PlacementToPlacementDetailTrigger on Placement__c (after update) 
{
    List<Placement_Detail_History__c> l=new List<Placement_Detail_History__c>();
    for(Placement__c rec:trigger.new)
    {
        if(rec.Detail__c!=trigger.oldMap.get(rec.id).Detail__c)    
            l.add(new Placement_Detail_History__c(Field__c='Detail', Placement__c = rec.id,Old_Value__c=trigger.oldMap.get(rec.id).Detail__c,new_Value__c = rec.Detail__c));
    }
    if(l.size()>0)
        insert l;

}