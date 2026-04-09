trigger TorcuserQuestionnaireProcess on Torc_User__c (after update) 
{
    List<Freelancer_Questionnaire__c>lst=new List<Freelancer_Questionnaire__c>();
    for(Torc_User__c tu:trigger.new)
    {
        if(tu.latest_Accepted_Match__c!=NULL 
            && tu.latest_Accepted_Match__c!=trigger.oldmap.get(tu.id).latest_Accepted_Match__c
            && tu.Latest_Freelancer_Questionnaire__c!=NULL)
        {
            lst.add(new Freelancer_Questionnaire__c(id=tu.Latest_Freelancer_Questionnaire__c, Initiate_Approval_Process__c=true));
        }    
    }
    if(lst.size()>0)
        update lst;

}