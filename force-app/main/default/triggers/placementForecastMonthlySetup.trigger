trigger placementForecastMonthlySetup on Placement_Forecast__c (before delete) 
{
    system.debug('in forecast delete----');
    if(trigger.isBefore && trigger.isDelete)
    {
        set<id> pfIds=new set<id>();
        for(Placement_Forecast__c r:trigger.old)
            pfids.add(r.id);
        for(List<Placement_Forecast_split__c> l:[Select ID from Placement_Forecast_split__c where Placement_Forecast__c in: pfids])
        {
            system.debug(l);
            delete l;
        }
    }   
}