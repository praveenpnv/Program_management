trigger candidateStatusChangeInterview on TR1__Send_Out_Schedule_V2__c (after insert) 
{
    if(!Torc_Constants__c.getInstance().Contact_Status_Automation__c)
            return;
    id recTypeId=[SELECT Id from recordtype where DeveloperName='External_Interview' and SobjectType  = 'TR1__Send_Out_Schedule_V2__c'].id;
    Set<id>contactsAllthe=new set<id>();
    for(TR1__Send_Out_Schedule_V2__c rec:trigger.new)
    {
        if(rec.TR1__Interviewee__c!=NULL)
        {
            contactsAllthe.add(rec.TR1__Interviewee__c);
        }        
    }
    if(contactsAllthe.size()>0)
    {
        Map<id,Contact> mapContacts = new Map<id,Contact>([Select Id, TR1__Candidate_Status__c, Latest_Interview_Date__c, Latest_Client_interview_Date__c From Contact where id in:contactsAllthe]);
        Map<id,Contact> newmapContacts=new Map<id,contact>();
        for(TR1__Send_Out_Schedule_V2__c rec:trigger.new)
        {
            if(rec.TR1__Interviewee__c!=NULL)
            {
                Contact c=mapContacts.get(rec.TR1__Interviewee__c);
                if(c!=NULL)
                {
                    date dt = rec.TR1__Date__c==NULL?date.Today():rec.TR1__Date__c;
                    
                    if(c.Latest_interview_Date__c==NULL || c.Latest_interview_Date__c < dt)
                    {
                        c.Latest_interview_Date__c = dt;
                        newmapContacts.put(c.id,c);
                    }    
                    if(rec.recordTypeId==recTypeId && (c.Latest_Client_interview_Date__c==NULL || c.Latest_Client_interview_Date__c<dt))
                    {
                        c.Latest_Client_interview_Date__c = dt;
                        newmapContacts.put(c.id,c);
                    }    
                }    
            }        
        }
        if(newmapContacts.values().size()>0)
        {
            torcRD1Integration.runningtorcCodeToUpdateData = true;
            update newmapContacts.values();
        }    
    }
}