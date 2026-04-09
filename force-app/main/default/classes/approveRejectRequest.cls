public class approveRejectRequest
{
    Freelancer_Questionnaire__c r{get;set;}
    public id pisId{get;set;}
    public string errorMessage{get;set;}
    public approveRejectRequest(ApexPages.StandardController controller)
    {
        pisId=null;
        errorMessage = 'Record is already processed.';
        r = (Freelancer_Questionnaire__c) controller.getRecord();
        for(Processinstance pi:[SELECT Id, ProcessDefinitionId, TargetObjectId, Status, CompletedDate, LastActorId 
                                        from Processinstance
                                        where TargetObjectId = :r.id and Status='Pending' Order by CompletedDate DESC LIMIT 1])
        {
            for(ProcessInstanceWorkItem pis:[SELECT Id, ProcessInstanceId  
                                            from ProcessInstanceWorkItem
                                            WHERE ProcessInstanceId=:pi.id Order by Createddate DESC LIMIT 1])
            {
                errorMessage='';
                system.debug('Step3');
                pisId = pis.id;
            }    
        }                                                
    }
    public pagereference launch()
    {
        if(pisId==NULL)
            return null;
        return new pagereference('/p/process/ProcessInstanceWorkitemWizardStageManager?id='+pisId);    
    }
    public void test1()
    {
        integer i=0;
        integer j=0;
        integer k=0;
        i++;
        j++;
        k++;
        i++;
        j++;
        k++;
        i++;
        j++;
        k++;
        
        
    }
    
}