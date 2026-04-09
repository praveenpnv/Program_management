trigger RD_ChangeEvent_Insert on RD_ChangeEvent__e (after insert) {

    List<RD_Change_Event_Log__c> lst = new List<RD_Change_Event_Log__c>();
    for(RD_ChangeEvent__e evt :Trigger.New) {
        RD_Change_Event_Log__c l = new RD_Change_Event_Log__c();
        l.Change_Type__c = evt.Change_Type__c;
        l.Changed_By__c = evt.Changed_By__c;
        l.Entity__c = evt.Entity__c;
        l.Fields__c = evt.Fields__c;
        l.Record_Id__c = evt.Record_Id__c;
        l.Source__c = evt.Source__c;
        l.Timestamp__c = evt.Timestamp__c;
        l.Reference_ID__c = evt.Reference_ID__c;
        
        lst.add(l);
    }    
    
    insert lst;
    
    
}