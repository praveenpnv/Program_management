trigger QuestionnaireTrigger on Freelancer_Questionnaire__c (before insert, before update, after insert, after update) 
{
    if(!Torc_Constants__c.getInstance().Skip_Freelancer_Approval__c)
    {
    if(trigger.isbefore && trigger.isUpdate)
    {
        for(Freelancer_Questionnaire__c r:trigger.new)
        {
            if(r.Approval_Status__c!=trigger.oldmap.get(r.id).Approval_Status__c && (r.Approval_Status__c=='Approved' || r.Approval_Status__c=='Rejected'))
            {
                for(Processinstance pi:[SELECT Id, ProcessDefinitionId, TargetObjectId, Status, CompletedDate, LastActorId 
                                            from Processinstance
                                            where TargetObjectId = :r.id Order by CompletedDate DESC LIMIT 1])
                {
                    
                    for(ProcessInstanceStep pis:[SELECT Id, ProcessInstanceId, StepStatus, ActorId, Comments  
                                                    from ProcessInstanceStep
                                                    WHERE ProcessInstanceId=:pi.id Order by Createddate DESC LIMIT 1])
                    {
                        r.Latest_Actual_Approver__c = pis.ActorId;
                        r.Latest_Approver_Comments__c = pis.Comments;
                    }                                                    
                }
            }   
        }
    }
    if(trigger.isbefore)
    {
        Map<string,Torc_User__c>mapTU=new Map<string,Torc_User__c>();
        for(Freelancer_Questionnaire__c r:trigger.new)
        {
            mapTU.put(r.email__c.toLowercase(),null);
        }
        if(trigger.isInsert)
        {
            for(Torc_user__c tu:[Select id,email__c from Torc_user__c where email__c in:mapTU.keyset()])
                mapTU.put(tu.email__c.toLowercase(),tu);
        }        
        for(Freelancer_Questionnaire__c r:trigger.new)
        {
            if(trigger.isInsert)
            {
                if(mapTU.get(r.email__c.toLowercase())!=NULL)
                    r.Torc_user__c = mapTU.get(r.email__c.toLowercase()).id;
            }        
            r.Approval_Type__c  = trigger.isInsert
                ?'New'
                :((r.Initiate_Approval_Process__c==true && trigger.oldmap.get(r.id).Initiate_Approval_Process__c==false)
                    ?'Existing'
                    :r.Approval_Type__c);
             if(trigger.isInsert || (r.Initiate_Approval_Process__c==true && trigger.oldmap.get(r.id).Initiate_Approval_Process__c==false))
             {
                 r.Assigned_Approver_Group__c = 
                 r.Country__c=='United States'
                     ?(r.Has_Accept_Match__c?'US_Match_Approver':'US_Non_Match_Approver') 
                     :(r.Has_Accept_Match__c?'Non_US_Match_Approver':'Non_US_Non_Match_Approver') ;                 
             }      
        }
    }
    else
    {
        List<Torc_User__c> lsttu=new List<Torc_User__c>();
        for(Freelancer_Questionnaire__c record:trigger.new)
        {
            if(trigger.isInsert || (record.Initiate_Approval_Process__c ==true && trigger.oldMap.get(record.id).Initiate_Approval_Process__c==false))
            {
                string Assigned_Approver = 
                 record.Country__c=='United States'
                     ?(record.Has_Accept_Match__c?Questionnaire__c.getinstance().US_Match_Approver__c:Questionnaire__c.getinstance().US_Non_Match_Approver__c) 
                     :(record.Has_Accept_Match__c?Questionnaire__c.getinstance().Non_US_Match_Approver__c:Questionnaire__c.getinstance().Non_US_Non_Match_Approver__c) ;                 
            
            
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(record.Id);
                req.setSubmitterId(Questionnaire__c.getinstance().Default_Submitter__c);
                req.setProcessDefinitionNameOrId('Questionnair_Initial_Approval_Process');
                req.setComments('Automatically submitted.');
                req.setSkipEntryCriteria(true);
                List<id> lstIds=new List<id>();
                for(string s:Assigned_Approver.split(','))
                {
                    lstids.add(s.trim());
                }
                system.debug(lstids);
                req.setNextApproverIds(lstids);
                //req.setNextApproverIds(new Id[]{Assigned_Approver});
                system.debug(req);
                Approval.ProcessResult result = Approval.process(req);  
                          
                Approval.ProcessWorkitemRequest workItemReq = new Approval.ProcessWorkitemRequest();
                if(record.Torc_User__c!=null)
                    lsttu.add(new Torc_User__c(id=record.Torc_User__c, Latest_Freelancer_Questionnaire__c=record.id));
            }
        }
        if(lsttu.size()>0)
            update lsttu;
    }    
    }
}