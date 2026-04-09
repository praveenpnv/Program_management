trigger TorcUserPlacementUpdate on Torc_User__c (after update) 
{
    set<id> setIds=new set<id>();
    for(Torc_User__c tu:trigger.New)
    {
        if(tu.Given_name__c!=trigger.oldMap.get(tu.id).Given_name__c 
            || tu.Family_name__c!=trigger.oldMap.get(tu.id).Family_name__c
            || tu.Email__c!=trigger.oldMap.get(tu.id).Email__c)
            setids.add(tu.id);    
    }
    if(setids.size()>0)
    {
        for(List<Placement__c> p:[Select ID from Placement__c where id in:setids])
            update p;
    }
}