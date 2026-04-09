trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) {
    if (Trigger.isBefore) {
        if(Trigger.isInsert){	
            OpportunityTriggerHandler.generatePlaceholderIDs(trigger.new);
        }
        else if(trigger.isUpdate){
            OpportunityTriggerHandler.updateResponsibleMarket(trigger.new);
            //           OpportunityTriggerHandler.handleOpportunityStageUpdate(Trigger.new);
            
            
        }
    } 
    else if (Trigger.isAfter) {
        if(trigger.isInsert){
            UpdateOpportunityIDsBatch batch = new UpdateOpportunityIDsBatch(new List<Id>(Trigger.newMap.keySet()));
            Database.executeBatch(batch);
        }
        else if(trigger.isUpdate){
            OpportunityTriggerHandler.updateResponsibleMarket(trigger.new);
            //OpportunityTriggerHandler.createTasks(Trigger.new, Trigger.oldMap);
            
            
            /*List<Id> opportunityIds = new List<Id>();

for (Opportunity opp : Trigger.new) {
if (opp.StageName == 'Proposal Submitted') {
opportunityIds.add(opp.Id);
}
}

if (!opportunityIds.isEmpty()) {
OpportunityTriggerHandler.handleOpportunityStageUpdate(opportunityIds);
}

List<Id> opportunityIds = new List<Id>();
for (Opportunity opp : Trigger.new) {
if (opp.StageName == 'Proposal Submitted') {
opportunityIds.add(opp.Id);
}
}
if (!opportunityIds.isEmpty()) {
OpportunityTriggerHandler.handleOpportunityStageUpdate(opportunityIds);
}

*/
        }
    }
}