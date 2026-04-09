trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update) {
    
    // Track OpportunityLineItems Ids where SL/SSL changed
    Set<Id> oppIdsToUpdate = new Set<Id>();

    for (OpportunityLineItem oli : Trigger.new) {
        OpportunityLineItem oldOli = Trigger.isUpdate ? Trigger.oldMap.get(oli.Id) : null;

        Boolean isSLChanged = oli.Service_Line__c != null &&
                              (Trigger.isInsert || oldOli == null || oli.Service_Line__c != oldOli.Service_Line__c);

        Boolean isSSLChanged = oli.Sub_Service_Line__c != null &&
                               (Trigger.isInsert || oldOli == null || oli.Sub_Service_Line__c != oldOli.Sub_Service_Line__c);

        if ((isSLChanged || isSSLChanged) && oli.OpportunityId != null) {
            // Check if Opportunity is NOT of RecordType 'SOW' , since this flow is only applicable for talent Services and not solution
            Opportunity oppDetails = OpportunityLIcontroller.getOpportunityFields(oli.OpportunityId);
            if (oppDetails != null && oppDetails.RecordType.Name != Label.SOW) {
                oppIdsToUpdate.add(oli.OpportunityId);
            }
        }
    }

    if (!oppIdsToUpdate.isEmpty()) {
        OpportunityServiceLineUpdater.updateOpportunityLines(oppIdsToUpdate);
    }
}