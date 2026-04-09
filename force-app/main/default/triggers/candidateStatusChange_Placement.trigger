trigger candidateStatusChange_Placement on TR1__Closing_Report__c (after insert, after update) 
{
    candidateStatusChangeHandle.handlePlacementChange(trigger.newmap,trigger.isInsert?null:trigger.oldMap,trigger.isinsert);
}