trigger PlacementDetailHistoryTrigger on Placement_Detail_History__c (before insert) 
{
    for(Placement_Detail_History__c r:trigger.new)
    {
        r.name = dateTime.now().format();
    }

}