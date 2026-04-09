trigger candidateStatusChangePowerNote on Task (after insert) 
{
    if(!Torc_Constants__c.getInstance().Contact_Status_Automation__c)
            return;
    Set<id>contactsAllthe=new set<id>();
    for(Task rec:trigger.new)
    {
        string whoId=rec.WhoId;
        if(WhoId!=NULL && WhoId.left(3)=='003' && rec.TR1__Original_Power_Note__c)
        {
            contactsAllthe.add(rec.WhoId);
        }        
    }
    if(contactsAllthe.size()>0)
    {
        Map<id,Contact> mapContacts = new Map<id,Contact>([Select Id, TR1__Candidate_Status__c,Latest_Note_Date__c, Latest_Candidate_Action_Note_Date__c From Contact where id in:contactsAllthe and Recordtype.Name='Candidate']);
        for(Task rec:trigger.new)
        {
            string whoId=rec.WhoId;
            if(WhoId!=NULL && WhoId.left(3)=='003' && rec.TR1__Original_Power_Note__c && mapContacts.get(whoId)!=NULL)
            {
                Contact c=mapContacts.get(whoId);
                c.Latest_Note_Date__c = date.today();
                if(rec.Sub_Action__c == 'Candidate Actions: Talent Visit New Candidate'
                    ||rec.Sub_Action__c ==  'Candidate Actions: Talent Visit ExistingCandidate'
                    ||rec.Sub_Action__c ==  'Candidate Actions: Webcam Interview'
                    ||rec.Sub_Action__c ==  'Candidate Actions: Recruiter Phone Screen')
                {
                    c.Latest_Candidate_Action_Note_Date__c = date.today();
                    if(c.TR1__Candidate_Status__c=='New' || c.TR1__Candidate_Status__c=='Suspense')
                        c.TR1__Candidate_Status__c='Available';
                }
            }        
        }
        torcRD1Integration.runningtorcCodeToUpdateData = true;
        try{
        update mapContacts.values();
        }
        catch(exception ex)
        {
        }
    }
}