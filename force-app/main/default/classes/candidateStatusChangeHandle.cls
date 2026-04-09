public class candidateStatusChangeHandle
{
    public static void handleApplicationChange(Map<id,TR1__Application_V2__c> newMap,Map<id,TR1__Application_V2__c> oldMap,boolean isInsert)
    {
        if(!Torc_Constants__c.getInstance().Contact_Status_Automation__c)
            return;
        Map<id,Contact>candidatesMap=new Map<id,Contact>();
        for(TR1__Application_V2__c rec:newMap.values())
        {
            if(trigger.isInsert)
            {
                if(candidatesMap.get(rec.TR1__Applicant__c)==NULL)
                    candidatesMap.put(rec.TR1__Applicant__c,new contact(id=rec.TR1__Applicant__c));
                candidatesMap.get(rec.TR1__Applicant__c).Latest_Application_Date__c =Date.today();   
            }
            if(rec.TR1__Stage__c!='Application' && (isInsert || rec.TR1__Stage__c!=oldMap.get(rec.id).TR1__Stage__c))
            {
                if(candidatesMap.get(rec.TR1__Applicant__c)==NULL)
                    candidatesMap.put(rec.TR1__Applicant__c,new contact(id=rec.TR1__Applicant__c));
                candidatesMap.get(rec.TR1__Applicant__c).Latest_Application_Beyond_Screen_Date__c =Date.today();   
            }
            
            if((rec.Candidate_Status__c=='New' ||rec.Candidate_Status__c=='Suspense')  && 
                (isInsert || rec.TR1__Stage__c!=oldMap.get(rec.id).TR1__Stage__c)
                 && rec.TR1__Stage__c !='Closing Report' && rec.TR1__Stage__c!='Application')
            {
                if(candidatesMap.get(rec.TR1__Applicant__c)==NULL)
                    candidatesMap.put(rec.TR1__Applicant__c,new contact(id=rec.TR1__Applicant__c));
                candidatesMap.get(rec.TR1__Applicant__c).TR1__Candidate_Status__c ='Available';   
            }
            
            
            if((rec.Candidate_Status__c=='New' ||rec.Candidate_Status__c=='Suspense' ||rec.Candidate_Status__c=='Available')  && 
                (isInsert || rec.TR1__Stage__c!=oldMap.get(rec.id).TR1__Stage__c || rec.Substage__c!=oldMap.get(rec.id).Substage__c)
                 && rec.TR1__Stage__c =='Send Out' && rec.Substage__c =='Completed')
            {
                if(candidatesMap.get(rec.TR1__Applicant__c)==NULL)
                    candidatesMap.put(rec.TR1__Applicant__c,new contact(id=rec.TR1__Applicant__c));
                candidatesMap.get(rec.TR1__Applicant__c).TR1__Candidate_Status__c ='Interviewing'; 
                candidatesMap.get(rec.TR1__Applicant__c).Latest_Client_Interview_Date__c =Date.Today();   
            }     
        }
        if(candidatesMap.values().size()>0)
        {
            torcRD1Integration.runningtorcCodeToUpdateData = true;
            update candidatesMap.values();
        }    
    }
    public static void handlePlacementChange(Map<id,TR1__Closing_Report__c> newMap,Map<id,TR1__Closing_Report__c> oldMap,boolean isInsert)
    {
        if(!Torc_Constants__c.getInstance().Contact_Status_Automation__c)
            return;
        Map<id,Contact>candidatesMap=new Map<id,Contact>();
        set<id>contactsToMakeAvailable=new set<id>();
        for(TR1__Closing_Report__c rec:newMap.values())
        {
            if(rec.TR1__Person_Placed__c==NULL)continue;
            if((rec.Candidate_Status__c!='Placed (Perm)')  && 
                (isInsert || rec.Placement_Type__c!=oldMap.get(rec.id).Placement_Type__c || rec.Status_US__c!=oldMap.get(rec.id).Status_US__c)
                 && (rec.placement_Type__c =='Permanent') 
                 && (rec.Status_US__c =='Ready for Back Office'))
            {
                if(candidatesMap.get(rec.TR1__Person_Placed__c)==NULL)
                    candidatesMap.put(rec.TR1__Person_Placed__c,new contact(id=rec.TR1__Person_Placed__c));
                candidatesMap.get(rec.TR1__Person_Placed__c).TR1__Candidate_Status__c ='Placed (Perm)';   
            }
        
            if((rec.Candidate_Status__c!='Placed (Solutions)')  && 
                (isInsert || rec.Placement_Type__c!=oldMap.get(rec.id).Placement_Type__c || rec.Status_US__c!=oldMap.get(rec.id).Status_US__c)
                 && (rec.placement_Type__c =='Solutions' || rec.placement_Type__c =='GDC Solutions') 
                 && (rec.Status_US__c =='Ready for Back Office' || rec.Status_US__c=='Offer Accepted'))
            {
                if(candidatesMap.get(rec.TR1__Person_Placed__c)==NULL)
                    candidatesMap.put(rec.TR1__Person_Placed__c,new contact(id=rec.TR1__Person_Placed__c));
                candidatesMap.get(rec.TR1__Person_Placed__c).TR1__Candidate_Status__c ='Placed (Solutions)';   
            }
            
            if((rec.Candidate_Status__c!='Placed')  && 
                (isInsert || rec.Placement_Type__c!=oldMap.get(rec.id).Placement_Type__c || rec.Status_US__c!=oldMap.get(rec.id).Status_US__c)
                 && (rec.placement_Type__c =='Contract' || rec.placement_Type__c =='Contract to Perm' || rec.placement_Type__c =='GDC Staffing') 
                 && (rec.Status_US__c =='Ready for Back Office' || rec.Status_US__c=='Offer Accepted'))
            {
                if(candidatesMap.get(rec.TR1__Person_Placed__c)==NULL)
                    candidatesMap.put(rec.TR1__Person_Placed__c,new contact(id=rec.TR1__Person_Placed__c));
                candidatesMap.get(rec.TR1__Person_Placed__c).TR1__Candidate_Status__c ='Placed';   
            }
            if((rec.Candidate_Status__c!='Available')  && 
                (isInsert || rec.Status_US__c!=oldMap.get(rec.id).Status_US__c)
                 && (rec.Status_US__c =='Closed'))
            {
                contactsToMakeAvailable.add(rec.TR1__Person_Placed__c);
            }
        }    
        system.debug(contactsToMakeAvailable);
        if(contactsToMakeAvailable.size()>0)
        {
            List<Contact> contactsToMakeAvailableList = new List<Contact>();
            for(Contact c:[Select id,(Select id from TR1__Closes__r where Status_US__c ='Ready for Back Office' OR Status_US__c='Offer Accepted' LIMIT 1) from Contact where id in:contactsToMakeAvailable])
            {
                system.debug(c);
                if(c.TR1__Closes__r.size()==0)
                {
                    if(candidatesMap.get(c.id)==NULL)
                        candidatesMap.put(c.id,new contact(id=c.id));
                    candidatesMap.get(c.id).TR1__Candidate_Status__c ='Available'; 
                }
            }
        }
        if(candidatesMap.values().size()>0)
        {
            torcRD1Integration.runningtorcCodeToUpdateData = true;
            update candidatesMap.values();    
        }    
    }
}