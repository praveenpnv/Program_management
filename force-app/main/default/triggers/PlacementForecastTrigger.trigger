trigger PlacementForecastTrigger on Placement_Forecast__c (before insert, before Update) 
{
    for(Placement_Forecast__c rec:trigger.New)
    {
        rec.Name = rec.Week_Ending_Date__c.year()+'-'+ string.ValueOf(rec.Week_Ending_Date__c.Month()).LeftPad(2,'0')+'-'+ string.ValueOf(rec.Week_Ending_Date__c.Day()).LeftPad(2,'0');
        rec.Torc_User__c = rec.Torc_user_Id__c;
    }

}