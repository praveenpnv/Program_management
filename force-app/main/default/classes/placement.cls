Public class placement
{
    public static string developerRoleName='Developer';
    public static string CSMRoleName='CSM';
    public static string TalentSpecialistRoleName = 'Talent Specialist';
    public static string OpportunityOwnerRoleName = 'AE';
    
    
    public static void InternalPlacementAddEditUpdate(Map<id,Internal_Placement__c>oldmap,List<Internal_Placement__c>TriggerNew,boolean isInsert,boolean isUpdate, boolean isDelete)
    {
        list<Internal_Placement__c> listToSet = new list<Internal_Placement__c>();
        Set<id> idToUnSet = new Set<Id>();
        Set<id> iplatformIdToUnSet = new Set<Id>();
        if(isDelete)
        {
            for(Internal_Placement__c oli:oldMap.values())
            {
                if(oli.Placement__c!=NULL)
                {
                    idToUnSet.add(oli.id);
                    iplatformIdToUnSet.add(oli.Placement__c);
                }
            }
        }
        else
        {
            for(Internal_Placement__c oli:TriggerNew)
            {
                if(isInsert || (isUpdate && (oli.Placement__c==NULL || oli.Category__c!= oldMap.get(oli.id).Category__c)))
                {
                    listToSet.add(oli);
                    if(isUpdate && oli.Category__c!= oldMap.get(oli.id).Category__c)
                    {
                        idToUnSet.add(oli.id);
                        iplatformIdToUnSet.add(oli.Placement__c);
                    }
                    oli.Placement__c = null;  
                }
            }
        }
        system.debug(idToUnSet);
        if(idToUnSet.size()>0)
        {
            Placement.unSetPlacementObject(iplatformIdToUnSet, idToUnSet);
        }
        if(listToSet.size()>0)
        {
            Placement.setupPlacementObject(listToSet);
        }
    }
    
    
    
    
    
    
    
    public static void oppLineItemAddEditUpdate(Map<id,opportunityLineItem>oldmap,List<opportunityLineItem>TriggerNew,boolean isInsert,boolean isUpdate, boolean isDelete)
    {
        list<OpportunityLineItem> listToSet = new list<OpportunityLineItem>();
        Set<id> idToUnSet = new Set<Id>();
        Set<id> iplatformIdToUnSet = new Set<Id>();
        if(isDelete)
        {
            for(OpportunityLineItem oli:oldMap.values())
            {
                if(oli.Is_Won__c && oli.Placement__c!=NULL)
                {
                    idToUnSet.add(oli.id);
                    iplatformIdToUnSet.add(oli.Placement__c);
                }
            }
        }
        else
        {
            for(OpportunityLineItem oli:TriggerNew)
            {
                if(oli.Is_Won__c && isInsert && oli.Torc_user__c!=NULL)
                {
                    listToSet.add(oli);
                }
                if(!oli.Is_Won__c && isInsert)
                {
                    oli.Placement__c=NULL;
                }
                if(oli.Is_Won__c && isUpdate && (oli.Torc_user__c!=oldMap.get(oli.id).Torc_User__c || (oli.Placement__c==NULL && oldMap.get(oli.id).Placement__c==NULL)))
                {
                    if(oli.Torc_user__c!=NULL)
                        listToSet.add(oli);
                    if(oldMap.get(oli.id).Placement__c!=NULL)
                    {
                        idToUnSet.add(oli.id);
                        iplatformIdToUnSet.add(oldMap.get(oli.id).Placement__c);
                    }
                    oli.Placement__c = NULL;
                }
            }
        }
        if(idToUnSet.size()>0)
        {
            Placement.unSetPlacementObject(iplatformIdToUnSet, idToUnSet);
        }
        if(listToSet.size()>0)
        {
            Placement.setupPlacementObject(listToSet);
        }
    }
    
    
    public static void setupPlacementObject(List<Internal_Placement__c> listoLine)
    {
        set<id>userIds=new set<id>();
        
        for(Internal_Placement__c oline:listoLine)
        {
            userIds.add(oline.Torc_user__c);
        }
        Map<String,Placement__c> mapPlacement = new Map<String,Placement__c>();
        for(Placement__c p:[SELECT ID,IPC__c, Main_opportunity__c, Internal_Placement__c,Latest_Internal_Placement__c,Internal_Placement__r.Category__c ,Torc_user__c, Latest_Opportunity__c,Latest_Opportunity__r.closeDate,Exclude__c
                                ,Latest_Internal_Placement__r.Engagement_Start_Date__c,Latest_Internal_Placement__r.Engagement_End_Date__c
                             from Placement__c 
                             WHERE Torc_user__c in:userIds AND (Internal_Placement__c!=NULL OR Main_Opportunity__c=NULL)])
        {
            mapPlacement.put(p.Internal_Placement__r.Category__c+'-'+p.Torc_user__c,p);
        }
        
        Map<Id,Placement__c> mapOliToPlacement=new Map<Id,Placement__c>();
        for(Internal_Placement__c oline:listoLine)
        {
            Placement__c placementObj = mapPlacement.get(oline.category__c+'-'+oline.Torc_user__c);
            if(placementObj==NULL)
            {
                placementObj = new Placement__c(Torc_User__c=oLine.Torc_User__c,IPC__c = oLine.Category__c);
                mapPlacement.put(oline.category__c+'-'+oline.Torc_user__c,placementObj);
            }
            placementObj.exclude__c = false;           
            if(placementObj.Internal_Placement__c==NULL)
            {
                placementObj.Internal_Placement__c = oLine.Id;
            }
            if(placementObj.Latest_Internal_Placement__c==NULL || placementObj.Latest_Internal_Placement__r.Engagement_End_Date__c<oLine.Engagement_End_Date__c)
            {
                placementObj.Latest_Internal_Placement__c = oLine.id;
            }
            system.debug(placementObj);
            mapOliToPlacement.put(oline.id,placementObj);
       }
       system.debug(mapPlacement.values());
       upsert mapPlacement.values();
       system.debug(listoLine);
       for(Internal_Placement__c oline:listoLine)
       {
           oLine.Placement__c = mapOliToPlacement.get(oLine.id).id;
           system.debug(oLine);
       }
    }
    public static void setupPlacementData(set<id>placementIds)
    {
        for(List<Placement__c> lstP:[Select Id, Latest_Opportunity_Line_Item__c,Latest_Opportunity_Line_Item__r.Opportunity.CloseDate, Total_To_Pay__c, Torc_User_Contact__c, Total_Price__c,First_LineItem__c, last_LineItem__c,
                                        (Select Id,Opportunity.Amount,TotalPrice, Total_Payment__c ,
                                            OpportunityId,Opportunity.CloseDate,
                                            Engagement_Start_Date__c,Engagement_End_Date__c from Opportunity_Product__r
                                            Order By Opportunity.CloseDate,Engagement_Start_Date__c
                                            ) ,
                                            (Select Id, Total_Payment__c , Category__c,
                                            Engagement_Start_Date__c,Engagement_End_Date__c from Internal_Placement__r) 
                                            from Placement__c where id in:placementIds])
        {
            for(Placement__c p:lstP)
            {
                OpportunityLineItem first=null;
                OpportunityLineItem last=null;
                Internal_Placement__c fIP=null;
                Internal_Placement__c lIP=null;
                p.Total_Price__c = 0;
                p.Total_To_Pay__c = 0;
                for(OpportunityLineItem oli:p.Opportunity_Product__r)
                {
                    p.Total_Price__c += oli.TotalPrice;
                    p.Total_To_Pay__c += (oli.Total_Payment__c!=NULL?oli.Total_Payment__c:0);
                    if(oli.Opportunity.Amount>0)
                    {
                        if(first==NULL || first.Engagement_Start_Date__c==NULL || 
                                (oli.Engagement_Start_Date__c!=NULL && oli.Engagement_Start_Date__c<first.Engagement_Start_Date__c))
                        first = oli;
                        if(last==NULL || first.Engagement_End_Date__c==NULL || 
                                (oli.Engagement_End_Date__c!=NULL && oli.Engagement_End_Date__c >last.Engagement_End_Date__c))
                        last = oli;
                    }  
                    if(p.Latest_Opportunity_Line_Item__c==NULL || p.Latest_Opportunity_Line_Item__r.Opportunity.CloseDate <oli.Opportunity.CloseDate)
                       p.Latest_Opportunity_Line_Item__c =oli.Id;
                }
                p.First_LineItem__c = first==NULL?null:first.id;
                p.Last_LineItem__c = last==NULL?NULL:last.id;
                for(Internal_Placement__c oli:p.Internal_Placement__r)
                {
                    p.Total_To_Pay__c += (oli.Total_Payment__c!=NULL?oli.Total_Payment__c:0);
                    if(oli.Total_Payment__c>0)
                    {
                        if(fIP==NULL || fIP.Engagement_Start_Date__c==NULL || 
                                (oli.Engagement_Start_Date__c!=NULL && oli.Engagement_Start_Date__c<fIP.Engagement_Start_Date__c))
                        fIP = oli;
                        if(lip==NULL || lip.Engagement_Start_Date__c==NULL || 
                                (oli.Engagement_End_Date__c!=NULL && oli.Engagement_End_Date__c > fIP.Engagement_End_Date__c))
                        lIP = oli;
                    }    
                }
                if(fIP!=NULL)
                    p.Internal_Placement__c = fIP.id;
                if(lip!=NULL)
                    p.latest_Internal_Placement__c = lIP.id;    
            }
            system.debug(lstp);
            update lstP;
        }
    }
    public static void setupPlacementObject(List<opportunityLineItem> listoLine)
    {
        set<id>oppIds=new set<id>();
        
        for(opportunityLineItem oli: listoLine)
        {
            oppIds.add(oli.Opportunityid);
        }
        Map<Id,Opportunity> mapOpties=new Map<Id,Opportunity>([Select Id, CloseDate from Opportunity where id in :oppids]);
        
        oppIds.clear();
        set<id>userIds=new set<id>();
        
        for(opportunityLineItem oline:listoLine)
        {
            id mainOptyId = oLine.Main_Opportunity__c==NULL?oLine.OpportunityId:oLine.Main_Opportunity__c;
            oppIds.add(mainOptyId);
            userIds.add(oline.Torc_user__c);
        }
        Map<String,Placement__c> mapPlacement = new Map<String,Placement__c>();
        for(Placement__c p:[SELECT ID,Main_opportunity__c,Torc_user__c, Latest_Opportunity__c,Latest_Opportunity__r.closeDate,Exclude__c
                             from Placement__c WHERE Main_opportunity__c in:oppIds AND Torc_user__c in:userIds])
        {
            mapPlacement.put(p.Main_opportunity__c+'-'+p.Torc_user__c,p);
        }
        
        Map<Id,Placement__c> mapOliToPlacement=new Map<Id,Placement__c>();
        for(opportunityLineItem oline:listoLine)
        {
            Opportunity opp= mapopties.get(oline.Opportunityid);
            id mainOptyId = oLine.Main_Opportunity__c==NULL?oLine.OpportunityId:oLine.Main_Opportunity__c;
            
            Placement__c placementObj = mapPlacement.get(mainOptyId+'-'+oline.Torc_user__c);
            
            if(placementObj==NULL)
            {
                placementObj = new Placement__c(Torc_User__c=oLine.Torc_User__c, Main_Opportunity__c=mainOptyId);
                mapPlacement.put(mainOptyId+'-'+oline.Torc_user__c,placementObj);
            }
            system.debug(placementObj);
            system.debug(placementObj.Latest_Opportunity__c); 
            placementObj.exclude__c = false;           
            if(placementObj.Latest_Opportunity__c==NULL || placementObj.Latest_Opportunity__r.closeDate < opp.CloseDate)
            {
                placementObj.Latest_Opportunity__c = opp.Id;
                placementObj.Latest_Opportunity_Line_Item__c = oLine.Id;
            }
            system.debug(placementObj);
            mapOliToPlacement.put(oline.id,placementObj);
       }
       upsert mapPlacement.values();
       system.debug(listoLine);
       for(opportunityLineItem oline:listoLine)
       {
           oLine.Placement__c = mapOliToPlacement.get(oLine.id).id;
           system.debug(oLine.Placement__c);
           system.debug(oLine);
       }
    }
    Public static void unSetPlacementObject(SET<id> placementIds, SET<id> OpportunityLineItemIds)
    {
        Map<id,List<OpportunityLineItem>> mapplacemenToOli = new Map<id,List<OpportunityLineItem>>();
        Map<id,List<Internal_Placement__c>> mapplacemenToIP = new Map<id,List<Internal_Placement__c>>();
        for(OpportunityLineItem Ol:[Select Id, OpportunityId,placement__c,Main_Opportunity__c
                                       from OpportunityLineItem 
                                       Where Placement__c in :placementIds AND ID NOT in:OpportunityLineItemIds  
                                       AND Opportunity.Create_Placement_Now__c=true
                                       Order By Opportunity.CloseDate])
        {
            IF(mapplacemenToOli.get(Ol.placement__c)==NULL)
               mapplacemenToOli.put(Ol.placement__c, new List<OpportunityLineItem>());
            mapplacemenToOli.get(Ol.placement__c).add(ol);    
        }  
        
        for(Internal_Placement__c Ol:[Select Id,placement__c,category__c
                                       from Internal_Placement__c 
                                       Where Placement__c in :placementIds AND ID NOT in:OpportunityLineItemIds 
                                       Order By Engagement_End_Date__c])
        {
            IF(mapplacemenToIP.get(Ol.placement__c)==NULL)
               mapplacemenToIP.put(Ol.placement__c, new List<Internal_Placement__c>());
            mapplacemenToIP.get(Ol.placement__c).add(ol);    
        }    
        List<Placement__c> deleteList = new List<Placement__c>();
        List<Placement__c> updateList = new List<Placement__c>();                                  
        for(id pId:placementIds)
        {
            List<OpportunityLineItem> lol=mapplacemenToOli.get(pId);
            List<Internal_Placement__c> lip=mapplacemenToIP.get(pId);
            if((lOl==NULL || lOl.size()==0) && (lip==NULL || lip.size()==0))
            {
                deleteList.add(new Placement__c(id=pId,Exclude__c = true));
            }   
            else if(lOl!=NULL && lOl.size()>0)
            {
                
                id mainOptyId = lOl[0].Main_Opportunity__c==NULL?lOl[0].OpportunityId:lOl[0].Main_Opportunity__c;
                updateList.add( new Placement__c(id=pId,
                                     Latest_Opportunity__c=lOl[lOl.size()-1].OpportunityId,
                                     Latest_Opportunity_Line_Item__c=lOl[lOl.size()-1].Id,
                                     Main_Opportunity__c=mainOptyId
                                     )); 
            }  
            else if(lip!=NULL && lip.size()>0)
            {
                
                id mainOptyId = lip[0].id;
                updateList.add( new Placement__c(id=pId, 
                                                Internal_Placement__c=mainOptyId,
                                                Latest_Internal_Placement__c = lip[lip.size()-1].id,
                                                IPC__c = lip[lip.size()-1].Category__c
                                                )); 
            }  
        }
        if(deleteList.size()>0)
            Delete deleteList;
        if(updateList.size()>0)
            update updateList;                               
    }


    
    
    public static Date getfirstDayOfWeek(Date dt)
    {
        string wday = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('EEE');
        integer addday =(wDay=='Sun'?0:(wDay=='Mon'?1:(wDay=='Tue'?2:(wDay=='Wed'?3:(wDay=='Thu'?4:(wDay=='Fri'?5:6))))));
        dt=dt.adddays(addday*-1);
        return dt;
    }
    public static Date getFirstDayOfMonth(Date dt)
    {
        return Date.newInstance(dt.year(),dt.Month(),1);
    }
    public static Date getLastDayOfMonth(Date dt)
    {
        return Date.newInstance(dt.year(),dt.Month()+1,1).adddays(-1);
    }
    
    public static Date addWorkingDays(Date dt, Integer days)
    {
        system.debug(dt);
        system.debug(days);
        integer num = 0;
        while(num<days)
        {
            dt=dt.adddays(1);
            string wday = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('EEE');
            num += (wDay=='Sun' || wDay=='Sat')?0:1;
            
        }    
        return dt;
    }
    public static Integer getWorkingDays(Date fromDt, Date toDt)
    {
        integer num = 0;
        while(fromDt <=toDt)
        {
            string wday = DateTime.newInstance(fromDt.year(),fromDt.month(),fromDt.day()).format('EEE');
            num += (wDay=='Sun' || wDay=='Sat')?0:1;
            fromDt=fromDt.adddays(1);
        }    
        return num;
    }
    Public class weekHours
    {
        Public Decimal Mon=0;
        Public Decimal Tue=0;
        Public Decimal Wed=0;
        Public Decimal Thu=0;
        Public Decimal Fri=0;
    }
    public class dataRowRaper
    {
        public string type='';
        public string subtype='';
        Public Date Engagement_Start_Date;
        Public Date Engagement_End_Date;
        Public Decimal Hours_Week = 0;
        Public Decimal Weekly_Bill_Rate = 0;
        Public Decimal Weekly_Talent_Rate = 0;
        Public Decimal Customer_Hourly_Bill_Rate = 0;
        Public Decimal Customer_Hourly_Bill_Rate_Direct = 0;
        Public Decimal Talent_Hourly_Pay_Rate = 0;

        public void updatePlacement(Placement__c pl,Map<Date,Placement_Forecast__c> mapDate,Map<Date,WeekHours> mapWeekHours)
        {
            Date dt = Engagement_Start_Date;
            dt = placement.getfirstDayOfWeek(dt);
            while(dt<Engagement_End_Date)
            {
                Date localFirstDate = dt;
                dt=dt.adddays(6);
                Date locallastDate = dt;
                Integer StartDateMonth = localFirstDate.Month();
                Integer EndDateMonth = locallastDate.Month();
                if(localFirstDate<Engagement_Start_Date)
                    localFirstDate = Engagement_Start_Date;
                if(locallastDate > Engagement_End_Date)
                    locallastDate = Engagement_End_Date;
                    
                if(mapDate.get(dt)==NULL)
                {
                   mapDate.put(dt,new Placement_Forecast__c(LineItem_Count__c = 0, Placement__c = pl.id,Week_Ending_Date__c=dt,Default_Hours_Week__c=0,Talent_Rate__c=0,Bill_Rate__c=0)); //,Split_1_Bill_Rate__c=0,Split_1_Default_Hours__c=0,Split_1_Talent_Rate__c=0
                   mapWeekHours.put(dt,new WeekHours());
                }
                Placement_Forecast__c pf = mapDate.get(dt);
                pf.lineItem_Count__c = pf.lineItem_Count__c==NULL?1:pf.lineItem_Count__c+1;
                Integer workingDays = getWorkingDays(localFirstDate,locallastDate);
                Decimal hours = (Hours_Week * workingDays/5.0);
                decimal h = (workingDays==0 || subtype==Torc_Constants__c.getinstance().Hiring_Product__c)?0:(Weekly_Bill_Rate>=0?hours:(-1*hours))/workingDays;
                Date Dt2 = dt.adddays(-6);
                for(integer i=1;i<=5;i++)
                {
                    if(Dt2.adddays(i)>=localFirstDate && Dt2.adddays(i)<=locallastDate)
                    {
                        if(i==1) mapWeekHours.get(dt).Mon+=h;
                        if(i==2) mapWeekHours.get(dt).Tue+=h;
                        if(i==3) mapWeekHours.get(dt).Wed+=h;
                        if(i==4) mapWeekHours.get(dt).Thu+=h;
                        if(i==5) mapWeekHours.get(dt).Fri+=h;
                    }
                }
                if(type=='ol' && subtype==Torc_Constants__c.getinstance().Hiring_Product__c)
                {
                    if(pf.Direct_Revenue_Only__c==NULL)pf.Direct_Revenue_Only__c=0;
                    pf.Direct_Revenue_Only__c += Customer_Hourly_Bill_Rate_Direct;
                }
                else
                {
                    pf.Bill_Rate__c += (Customer_Hourly_Bill_Rate * hours);
                    pf.Talent_Rate__c += (Talent_Hourly_Pay_Rate * hours);
                    pf.Default_Hours_Week__c +=   Weekly_Talent_Rate>=0?hours:(-1*hours);
                    pf.Default_Hourly_Customer_Rate__c = pf.Default_Hours_Week__c==0?0:pf.Bill_Rate__c/pf.Default_Hours_Week__c;
                    pf.Default_Hourly_Talent_Rate__c = pf.Default_Hours_Week__c==0?0:pf.Talent_Rate__c/pf.Default_Hours_Week__c;
                }
                dt=dt.adddays(1);    
            }
        }
        public dataRowRaper(OpportunityLineItem ol)
        {
            type = 'OL';
            subtype = ol.Product_Type__c;
            Engagement_Start_Date = ol.Engagement_Start_Date__c;
            Engagement_End_Date = subtype==Torc_Constants__c.getinstance().Hiring_Product__c?ol.Engagement_Start_Date__c: ol.Engagement_End_Date__c;
            Hours_Week = ol.Hours_Week__c;
            Weekly_Bill_Rate = ol.Weekly_Bill_Rate__c;
            Weekly_Talent_Rate = ol.Weekly_Talent_Rate__c;
            Customer_Hourly_Bill_Rate = ol.Customer_Hourly_Bill_Rate__c;
            Customer_Hourly_Bill_Rate_Direct = ol.Direct_revenue__c;
            Talent_Hourly_Pay_Rate =ol.Talent_Hourly_Pay_Rate__c;
        }
        public dataRowRaper(Internal_Placement__c ol)
        {
            type = 'IP';
            Engagement_Start_Date = ol.Engagement_Start_Date__c;
            Engagement_End_Date = ol.Engagement_End_Date__c;
            Hours_Week = ol.Hours_Week__c;
            Weekly_Bill_Rate = 0;
            Weekly_Talent_Rate = ol.Weekly_Talent_Rate__c;
            Customer_Hourly_Bill_Rate = 0;
            Customer_Hourly_Bill_Rate_Direct=0;
            Talent_Hourly_Pay_Rate =ol.Talent_Hourly_Pay_Rate__c;
        }
        public dataRowRaper(Engagement_Vacation__c ol, boolean forRefill)
        {
            type = 'EV';
            Engagement_Start_Date = forRefill? ol.Shift_To_Date__c: ol.Engagement_Start_Date__c;
            Engagement_End_Date = forRefill? ol.Shift_To_End_Date__c: ol.Engagement_End_Date__c;
            Hours_Week = ol.Hours_Week__c;
            
            if(ol.Weekly_Bill_Rate__c!=NULL) 
                Weekly_Bill_Rate = forRefill? ol.Weekly_Bill_Rate__c : ol.Weekly_Bill_Rate__c*-1;
            if(ol.Weekly_Talent_Rate__c!=NULL) 
                Weekly_Talent_Rate = forRefill?ol.Weekly_Talent_Rate__c:ol.Weekly_Talent_Rate__c*-1;
            if(ol.Customer_Hourly_Bill_Rate__c!=NULL)    
                Customer_Hourly_Bill_Rate = forRefill?ol.Customer_Hourly_Bill_Rate__c:ol.Customer_Hourly_Bill_Rate__c*-1;
            if(ol.Talent_Hourly_Pay_Rate__c!=NULL)
                Talent_Hourly_Pay_Rate =forRefill?ol.Talent_Hourly_Pay_Rate__c:ol.Talent_Hourly_Pay_Rate__c*-1;
        }
    }
    Public static void setupPlacementForecast(set<id>placementIds)
    {
        system.debug('In Forecast');
        Map<id,Placement__c> mapPlacement =new Map<id,Placement__c>([SELECT ID,
                                                                        (Select ID,Week_Ending_Date__c, 
                                                                        Default_Hours_Week__c, Manually_Updated__c,
                                                                        Talent_Rate__c, Bill_Rate__c, 
                                                                        //Split_1_Bill_Rate__c, Split_1_Default_Hours__c, Split_1_Talent_Rate__c,
                                                                        Engagement_Start__c,Engagement_End__c,
                                                                        Manually_Forecasted_Hours__c, Direct_Revenue_Only__c,
                                                                        //Actual_Hours__c, 
                                                                        Manual_Hourly_talent_rate__c,Manual_Hourly_Customer_rate__c,
                                                                        Default_Hourly_Customer_Rate__c, Default_Hourly_Talent_Rate__c,lineItem_Count__c
                                                                        //,Delivered__c              
                                                                        FROM Placement_Forecasts__r) ,
                                                                        
                                                                        (SELECT ID, Direct_revenue__c, Product_Type__c, Placement__c , Engagement_Start_Date__c,Engagement_End_Date__c, Hours_Week__c, 
                                                                        Weekly_Bill_Rate__c , Weekly_Talent_Rate__c,
                                                                        Customer_Hourly_Bill_Rate__c, Talent_Hourly_Pay_Rate__c
                                                                        FROM Opportunity_Product__r),
                                                                        
                                                                        (SELECT ID, Placement__c , Engagement_Start_Date__c,Engagement_End_Date__c, Hours_Week__c, 
                                                                         Weekly_Talent_Rate__c, Talent_Hourly_Pay_Rate__c
                                                                        FROM Internal_Placement__r),
                                                                        
                                                                        (SELECT ID, Placement__c , Engagement_Start_Date__c,Engagement_End_Date__c, Hours_Week__c, 
                                                                        Weekly_Bill_Rate__c , Weekly_Talent_Rate__c,
                                                                        Customer_Hourly_Bill_Rate__c, Talent_Hourly_Pay_Rate__c,
                                                                        Shift_To_Date__c, Shift_To_End_Date__c
                                                                        FROM Engagement_Vacations__r)
                                                                        
                                                                    from Placement__c 
                                                                    Where ID in:placementIds]);
        List<Placement_Forecast__c> upsertList=new List<Placement_Forecast__c>();
        List<Placement_Forecast__c> deleteList=new List<Placement_Forecast__c>();
        for(Placement__c placement:mapPlacement.values())
        {
            system.debug(placement);
            Map<Date,Placement_Forecast__c> mapDate=new Map<Date,Placement_Forecast__c>();
            Map<Date,WeekHours> mapWeekHours=new Map<Date,WeekHours>();
            for(Placement_Forecast__c pf:placement.Placement_Forecasts__r)
            {
                mapDate.put(pf.Week_Ending_Date__c, pf);
                mapWeekHours.put(pf.Week_Ending_Date__c,new WeekHours());
                pf.Default_Hours_Week__c = 0;
                pf.Talent_Rate__c = 0;
                pf.Bill_Rate__c = 0;
                pf.Default_Hourly_Customer_Rate__c=0;
                pf.Default_Hourly_Talent_Rate__c=0;
                pf.LineItem_Count__c = 0;
                pf.Direct_Revenue_Only__c = 0;
            }
            for(OpportunityLineItem oli:placement.Opportunity_Product__r)
            {
                dataRowRaper drt=new dataRowRaper(oli);
                drt.updatePlacement(Placement,mapDate,mapWeekHours);
            }
            for(Internal_Placement__c oli:placement.Internal_Placement__r)
            {
                dataRowRaper drt=new dataRowRaper(oli);
                drt.updatePlacement(Placement,mapDate,mapWeekHours);
            }
            for(Engagement_Vacation__c oli:placement.Engagement_Vacations__r)
            {
                dataRowRaper drt=new dataRowRaper(oli,false);
                drt.updatePlacement(Placement,mapDate,mapWeekHours);
                drt=new dataRowRaper(oli,true);
                drt.updatePlacement(Placement,mapDate,mapWeekHours);
            }
            system.debug(mapDate);
            system.debug(mapWeekHours);
            Date workingfDate=NULL;
            Date workinglDate=null;
            Date veryfDate=NULL;
            Date verylDate=null;
            for(Date dt:mapDate.keySet())
            {
                if(veryfDate==NULL || veryfDate>dt) veryfDate=dt;
                if(verylDate==NULL || verylDate<dt) verylDate=dt;
                
                if(mapDate.get(dt).Manually_Forecasted_Hours__c ==NULL || mapDate.get(dt).Manually_Updated__c!=TRUE)
                {
                    mapDate.get(dt).Manually_Forecasted_Hours__c = mapDate.get(dt).Default_Hours_Week__c;
                    mapDate.get(dt).Manual_Hourly_Talent_Rate__c = mapDate.get(dt).Default_Hourly_Talent_Rate__c;
                    mapDate.get(dt).Manual_Hourly_Customer_Rate__c = mapDate.get(dt).Default_Hourly_Customer_Rate__c;
                }
                if(mapDate.get(dt).Default_Hours_Week__c !=0 || 
                    (mapDate.get(dt).Manually_Forecasted_Hours__c !=0 && mapDate.get(dt).Manually_Forecasted_Hours__c !=NULL) ||
                    (mapDate.get(dt).Direct_Revenue_Only__c !=0 && mapDate.get(dt).Direct_Revenue_Only__c !=NULL)
                    //||(mapDate.get(dt).Delivered__c)
                    )
                {
                    if(workingfDate==NULL || workingfDate>dt) workingfDate=dt;
                    if(workinglDate==NULL || workinglDate<dt) workinglDate=dt;
                }
            }
            system.debug(veryfDate);
            system.debug(verylDate);
            if(veryfDate==NULL || verylDate==null) continue;
            Date dt=veryfDate;
            while(dt<=verylDate)
            {
                if(mapDate.get(dt)==NULL)
                {
                    mapDate.put(dt,new Placement_Forecast__c(LineItem_Count__c = 0, Placement__c = placement.id,Week_Ending_Date__c=dt,Default_Hours_Week__c=0,Talent_Rate__c=0,Bill_Rate__c=0,Direct_Revenue_Only__c=0)); //Split_1_Bill_Rate__c=0,Split_1_Default_Hours__c=0,Split_1_Talent_Rate__c=0
                    mapWeekHours.put(dt,new WeekHours());
                }
                Placement_Forecast__c rec=mapDate.get(dt);
                
                if((workingfDate==NULL || workingLdate==NULL ||  dt<workingfDate || dt > workingLdate) && rec.id!=NULL)
                    deleteList.add(mapDate.get(dt));
                else if((dt>=workingfDate && dt <= workingLdate))
                    upsertList.add(rec);    
                
                rec.Engagement_Start__c = null;
                rec.Engagement_End__c = null;
                Weekhours wh = mapWeekHours.get(dt);
                Date dt2=dt.adddays(-6);
                rec.Engagement_Start__c = wh.Mon!=0?dt2.adddays(1):wh.Tue!=0?dt2.adddays(2):wh.Wed!=0?dt2.adddays(3):wh.Thu!=0?dt2.adddays(4):wh.Fri!=0?dt2.adddays(5):NULL;
                rec.Engagement_End__c = wh.Fri!=0?dt2.adddays(5):wh.Thu!=0?dt2.adddays(4):wh.Wed!=0?dt2.adddays(3):wh.Tue!=0?dt2.adddays(2):wh.Mon!=0?dt2.adddays(1):NULL;
                dt=dt.adddays(7);        
            }
            Decimal dh,mfh;
            dh=mfh = 0;
            date lastDate=null;
            for(date dtx:mapDate.keyset())
            {
                if(lastDate==NULL || lastDate<dtx) lastDate=dtx;
                Placement_Forecast__c pf = mapDate.get(dtx);
                mfh += pf.Manually_Forecasted_Hours__c==NULL?0:pf.Manually_Forecasted_Hours__c;
                dh +=pf.Default_Hours_Week__c;
            }
            if(dh!=mfh && mapDate.values().size()>0 && lastDate!=NULL)
            {
                mapDate.get(lastDate).Manually_Forecasted_Hours__c += (dh-mfh);
            }
        }
        system.debug(deleteList);
        system.debug(upsertList);
        if(deleteList.size()>0)
            delete deleteList;
        if(upsertList.size()>0)
            Upsert upsertList;    
        system.debug('Out Forecast');
    }
    public static void placementForecastDelete(List<Placement_Forecast_Split__c> lst)
    {
        system.debug('in forecast split delete Placement code----');
        set<id> monthlyForecastChk=new set<id>();
        List<Placement_Monthly_Forecast__c> deleteList = new List<Placement_Monthly_Forecast__c>();
        for(Placement_Forecast_Split__c rec:lst)
        {
            if(rec.Placement_Monthly_Forecast__c!=NULL)
                monthlyForecastChk.add(rec.Placement_Monthly_Forecast__c);
        }   
        for(Placement_Monthly_Forecast__c pm:[Select ID,(Select ID from Placement_Forecast_splits__r Limit 1) 
                                                    from Placement_Monthly_Forecast__c
                                                    WHERE id in:monthlyForecastChk])
        {
            if(pm.Placement_Forecast_splits__r.size()==0)
                deleteList.add(new Placement_Monthly_Forecast__c(id=pm.id));
        }       
        system.debug(deleteList);
        if(deleteList.size()>0)
            delete deleteList;                                                                                    
    }
    public static date getconditionalforecastmonthstartdate(date ed)
    {
        return date.newInstance(ed.year(),ed.Month(),1);
        /*(date sd =ed.adddays(-7); 
        if(sd.month()==ed.month())
            return date.newInstance(sd.year(),sd.Month(),1);
        Date fdofED = date.newInstance(ed.year(),ed.Month(),1);
        system.debug(fdofED);
        system.debug(fdofed.daysbetween(ed));
        if(fdofed.daysbetween(ed)>=3)
            return fdofED;
        return date.newInstance(sd.year(),sd.Month(),1);    */
    }
    public static void placementForecastInsert(List<Placement_Forecast_Split__c> lst)
    {
        set<Date> lstDate = new set<Date>();
        set<id>placementIds = new set<Id>();
        for(Placement_Forecast_Split__c rec:lst)
        {
            placementIds.add(rec.Placement__c);
            Date sd = getconditionalforecastmonthstartdate(rec.End_Date__c);
            lstDate.add(sd);
        }
        Map<id,Map<Date,Placement_Monthly_Forecast__c>> mapM=new Map<id,Map<Date,Placement_Monthly_Forecast__c>>();
        for(Placement_Monthly_Forecast__c pm:[Select ID, Placement__c,Start_Date__c,End_Date__c from Placement_Monthly_Forecast__c
                                                        Where Placement__c in:placementIds and Start_Date__c in:lstDate])
        {
            if(mapM.get(pm.Placement__c)==NULL)
               mapM.put(pm.Placement__c, new Map<Date,Placement_Monthly_Forecast__c>()); 
            if(mapM.get(pm.Placement__c).get(pm.Start_Date__c)==NULL)
                mapM.get(pm.Placement__c).put(pm.Start_Date__c,pm);
        }
        List<Placement_Monthly_Forecast__c> forcastRecords = new List<Placement_Monthly_Forecast__c>();
        for(Placement_Forecast_Split__c rec:lst)
        {
            Date sd = getconditionalforecastmonthstartdate(rec.End_Date__c);
            if(mapM.get(rec.Placement__c)==NULL || mapM.get(rec.Placement__c).get(sd)==NULL)
            {
                Placement_Monthly_Forecast__c pm = new Placement_Monthly_Forecast__c(Placement__c = rec.Placement__c);
                pm.Name = sd.year()+'-'+ string.ValueOf(sd.Month()).LeftPad(2,'0')+'-'+ string.ValueOf(sd.Day()).LeftPad(2,'0');
                pm.Start_Date__c = sd;
                pm.End_Date__c = date.newInstance(sd.year(),sd.Month()+1,1).adddays(-1);
                if(mapM.get(pm.Placement__c)==NULL)
                   mapM.put(pm.Placement__c, new Map<Date,Placement_Monthly_Forecast__c>()); 
                mapM.get(pm.Placement__c).put(sd,pm);   
                forcastRecords.add(pm);
            }
        } 
        if(forcastRecords.size()>0)
            insert forcastRecords;                                                   
        for(Placement_Forecast_Split__c rec:lst)
        {
            Date sd = getconditionalforecastmonthstartdate(rec.End_Date__c);
            rec.Placement_Monthly_Forecast__c = mapM.get(rec.Placement__c).get(sd).id;   
        } 
    }
}