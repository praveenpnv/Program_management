trigger PlacementForecastSplitTrigger on Placement_Forecast_Split__c (before Insert,after delete) 
{
    system.debug('in forecast split trigger----');
    if(trigger.isBefore && trigger.isInsert)
    {
        system.debug(trigger.new);
        for(Placement_Forecast_Split__c rec:trigger.New)
        {
            rec.Name = rec.End_Date__c.year()+'-'+ string.ValueOf(rec.End_Date__c.Month()).LeftPad(2,'0')+'-'+ string.ValueOf(rec.End_Date__c.Day()).LeftPad(2,'0');
        }
        system.debug(trigger.new);
        placement.placementForecastInsert(trigger.new);        
        system.debug(trigger.new);
    }
    if(trigger.isafter && trigger.isDelete)
    {
        system.debug('in forecast split after delete----');
        placement.placementForecastDelete(trigger.old);
    } 

}