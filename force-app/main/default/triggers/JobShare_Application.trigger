trigger JobShare_Application on TR1__Application_V2__c (before Insert,after insert, after update) 
{
    if(trigger.isbefore)
    {
        if(trigger.isinsert)
        {
            for(TR1__Application_V2__c rec:trigger.New)
                if(rec.Application_Owner__c==NULL)
                    rec.Application_Owner__c = UserInfo.getUserId();
        }        
    }
    else
    {
        Map<Id,Set<string>> contactToOpcoMap=new Map<Id,Set<string>>();
        for(TR1__Application_V2__c rec:trigger.New)
        {
            if(trigger.isInsert || (trigger.isUpdate && (rec.TR1__Applicant__c != trigger.oldMap.get(rec.id).TR1__Applicant__c)))
            {
                if(rec.Application_OPCO__c!=rec.Candidat_s_OPCO__c || rec.Candidat_s_OPCO__c!=rec.Job_s_Opco__c)
                {
                    if(contactToOpcoMap.get(rec.TR1__Applicant__c)==NULL)
                        contactToOpcoMap.put(rec.TR1__Applicant__c,new set<string>());
                    if(rec.Job_s_Opco__c!=NULL)
                        contactToOpcoMap.get(rec.TR1__Applicant__c).add(rec.Job_s_Opco__c);    
                    if(rec.Application_OPCO__c!=NULL)
                        contactToOpcoMap.get(rec.TR1__Applicant__c).add(rec.Application_OPCO__c);        
                }
                
            }
        }
        if(contactToOpcoMap.keyset().size()>0)
        {
            for(List<Contact> lstC:[Select Id, Other_OPCO_to_Share__c from Contact where id in:contactToOpcoMap.keyset()])
            {
                for(Contact c:lstC)
                {
                    if(c.Other_OPCO_to_Share__c!=NULL)
                    {
                        list<string> oldSet=c.Other_OPCO_to_Share__c.split(';');
                        Set<String> existingList = new Set<String>();
                        for (String value : oldSet) 
                            if (!String.isBlank(value)) 
                                existingList.add(value);
                        contactToOpcoMap.get(c.id).addAll(existingList);
                    }
                    c.Other_OPCO_to_Share__c = ';'+String.join(contactToOpcoMap.get(c.id), ';')+';';
                }
                update lstC;
            }
        }
    }        

}