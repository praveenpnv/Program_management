trigger candidateStatusChange_Application on TR1__Application_V2__c (after insert, after update) 
{
    candidateStatusChangeHandle.handleApplicationChange(trigger.newmap,trigger.isInsert?null:trigger.oldMap,trigger.isinsert);
}