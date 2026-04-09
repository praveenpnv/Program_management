trigger candidateStatusChangeContact on Contact (before insert, before update ) 
{
    if(!Torc_Constants__c.getInstance().Contact_Status_Automation__c)
            return;
    if(trigger.isBefore)
    {
        for(Contact c:trigger.new)
        {
            if((
                (c.Availability_date__c!=NULL && c.Availability_date__c < date.today().adddays(90) && c.Availability_date__c >= date.today()) ||
                (c.Date_of_the_First_Interview__c == date.today() || c.Date_of_the_Second_Interview__c == date.today())
                
                ) && (c.TR1__Candidate_Status__c=='New' || c.TR1__Candidate_Status__c=='Suspense'))
                
                    c.TR1__Candidate_Status__c = 'Available';
            if(trigger.isUpdate && 
                c.Latest_Client_Interview_date__c!=trigger.oldMap.get(c.id).Latest_Client_Interview_date__c &&
                c.Latest_Client_Interview_date__c!=NULL && 
                trigger.oldMap.get(c.id).Latest_Client_Interview_date__c!=NULL &&
                trigger.oldMap.get(c.id).Latest_Client_Interview_date__c > c.Latest_Client_Interview_date__c
                )
                    c.Latest_Client_Interview_date__c = trigger.oldMap.get(c.id).Latest_Client_Interview_date__c;
                    
           if(trigger.isUpdate && c.Latest_Client_Interview_date__c!=NULL && 
               (c.Latest_Interview_date__c==NULL ||  c.Latest_Client_Interview_date__c>c.Latest_Interview_date__c))
                    c.Latest_Interview_date__c = c.Latest_Client_Interview_date__c;         
        }
    }    

}