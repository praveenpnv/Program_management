trigger CreatePlacementForecastSplit on Placement_Forecast__c (after Insert) //,after Update
{
    List<Placement_Forecast_Split__c> lst = new List<Placement_Forecast_Split__c>();

    for(Placement_Forecast__c pf:trigger.New)
    {
        if(trigger.isInsert || pf.Split_Count__c==0)
        {
            Date wend = pf.Week_Ending_Date__c;
            Date wSt = wend.adddays(-6);
            Placement_Forecast_Split__c sp1 = new Placement_Forecast_Split__c(Placement_Forecast__c=pf.Id,
                                                                              Placement__c = pf.Placement__c, 
                                                                              Start_Date__c=wSt,
                                                                              Type__c='First');
            lst.add(sp1);
            if(wSt.Month()==wEnd.Month())
            {
                sp1.End_Date__c = wEnd;
            } 
            else
            {
                sp1.End_Date__c = Placement.getLastDayOfMonth(wSt);
                Placement_Forecast_Split__c sp2 = new Placement_Forecast_Split__c(Placement_Forecast__c=pf.Id,
                                                                              Placement__c = pf.Placement__c, 
                                                                              Start_Date__c=Placement.getFirstDayOfMonth(wEnd),
                                                                              End_Date__c = wEnd,
                                                                              Type__c='Second');
                lst.add(sp2);
            }  
        }                                                           
    }
    if(lst.size()>0)
    insert lst;
}