trigger JobShare_Job on TR1__Job__c (before insert, before update) //after insert, after update,
{
    if(trigger.isBefore)
    {
       for(TR1__Job__c rec:trigger.new)
       {
           List<string>selectedValues=new List<string>();
           if(rec.Job_Share__c!=NULL)
               selectedValues = rec.Job_Share__c.split(';');
           rec.Share_with_India__c = selectedValues.contains('GDC India');
           //rec.Share_with_Portugal__c = selectedValues.contains('GDC Portugal');
           //rec.Share_with_Romania__c = selectedValues.contains('GDC Romania');
           if(rec.Share_with_India__c==FALSE)
               rec.Responsible_Recruiter_India__c = null;
       } 
    }
    /*else
    {
        set<id>ids = new set<id>();
        Map<id,Map<string, Job_OPCO_Assignment__c>> mapOpco=new Map<id,Map<string, Job_OPCO_Assignment__c>>();
        
        for(TR1__Job__c rec:trigger.new)
        {
            if(trigger.isInsert || 
                    (trigger.isUpdate && 
                        (
                            rec.Job_Share__c!=trigger.oldMap.get(rec.id).Job_Share__c || 
                            rec.User_Opco__c!=trigger.oldMap.get(rec.id).User_Opco__c
                        )   
                    )
            )
            {
                ids.add(rec.id);
                mapOpco.put(rec.id,new Map<string, Job_OPCO_Assignment__c>());
            }
        }
        system.debug(ids);
        
        if(!trigger.isinsert && ids.size()>0)
        {
            for(Job_OPCO_Assignment__c rec:[Select Id, Opco__c,Job__c from Job_OPCO_Assignment__c where Job__c in: ids])
            {
                mapOpco.get(rec.Job__c).put(rec.opco__c,rec);    
            }
        }
        List<Job_OPCO_Assignment__c> deleteList = new List<Job_OPCO_Assignment__c>();
        List<Job_OPCO_Assignment__c> insertList = new List<Job_OPCO_Assignment__c>();
        for(id jobId:ids)
        {
            TR1__Job__c newRec= trigger.newMap.get(jobId);
            TR1__Job__c oldRec= trigger.isInsert?NULL:trigger.oldMap.get(jobId);
            system.debug(newRec.Job_Share__c);
            
            set<string>newOpcos = OpcoAssignment.getOpcosFromString(newRec.Job_Share__c);
            set<string>oldOpcos = trigger.isInsert?new set<string>() : OpcoAssignment.getOpcosFromString(oldRec.Job_Share__c);
            system.debug(newOpcos);
            system.debug(oldOpcos);    
            for(string s:oldOpcos)
            {
                if(!newOpcos.contains(s) && mapOpco.get(jobId).get(s)!=NULL)
                    deleteList.add(mapOpco.get(jobId).get(s));
            }
            for(string s:newOpcos)
            {
                Job_OPCO_Assignment__c joA = mapOpco.get(jobId).get(s);
                if(joA==NULL)
                {
                    joA = new Job_OPCO_Assignment__c(Name = s+'-'+newrec.name, Opco__c =s, Job__c=JobId);
                    insertList.add(joA);
                } 
            }
            if(deleteList.size()>0)
                delete deleteList;
            if(insertList.size()>0)
                insert insertList;    
        }
    }*/
}