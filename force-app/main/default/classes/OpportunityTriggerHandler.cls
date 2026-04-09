public class OpportunityTriggerHandler {
    public static void generatePlaceholderIDs(List<Opportunity> newOpportunities) {
        for (Opportunity opp : newOpportunities) {
            String opcoInitials = 'XX';
            
            if (opp.Owner.Opco__c != null && opp.Owner.Opco__c.length() >= 2) {
                opcoInitials = opp.Owner.Opco__c.substring(0, 2).toUpperCase();
            }
            
            String formattedDate = DateTime.now().format('yyyy');
            
            String newRID =opcoInitials +'_'+formattedDate+'_' +opp.Counter_ID__c;
            
            
            opp.Randstad_ID__c = newRID;
        }
    }
    
    public static void updateResponsibleMarket(List<Opportunity> newOpportunities) {
        for (Opportunity opp : newOpportunities) {
            if (opp.Owner.Opco__c != null) {
                opp.Responsible_Market__c = opp.Responsible_Opco__c;
            }
        }
    }
    public static void createTasks(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        List<Task> tasksToInsert = new List<Task>();
        
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
            if (oldOpp.StageName != 'Proposal submitted' && opp.StageName == 'Proposal submitted') {
                Task newTask = new Task();
                newTask.WhatId = opp.Id;
                newTask.Subject = 'Follow-up on Proposal';
                newTask.ActivityDate = Date.today();
                newTask.Status = 'Not Started';
                newTask.Priority = 'Normal';
                newTask.Description = 'Follow up on proposal submission for Opportunity: ' + opp.Name;
                tasksToInsert.add(newTask);
            }
        }
        
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
    
    
    /*@future
public static void handleOpportunityStageUpdate(List<Id> opportunityIds) {
List<Opportunity> oppsToUpdate = new List<Opportunity>();

for (Id oppId : opportunityIds) {
Opportunity opp = new Opportunity(Id = oppId, approved__c = false);
oppsToUpdate.add(opp);
}

if (!oppsToUpdate.isEmpty()) {
update oppsToUpdate;
}
}

public class OpportunityQueueable implements System.Queueable {
private Set<Id> opportunityIds;

public OpportunityQueueable(Set<Id> ids) {
this.opportunityIds = ids;
}

public void execute(QueueableContext context) {
// Update the Opportunity records
List<Opportunity> oppsToUpdate = new List<Opportunity>();
for (Id oppId : opportunityIds) {
Opportunity opp = new Opportunity(Id = oppId, approved__c = false);
oppsToUpdate.add(opp);
}
update oppsToUpdate;

// Reset the static boolean variable to allow trigger execution again
OpportunityTriggerHandlerHelper.isQueueableExecuting = false;
}
}

public static void handleOpportunityStageUpdate(List<Id> opportunityIds) {
// Check if the trigger logic is already executing due to a previous Queueable job
if (!OpportunityTriggerHandlerHelper.isQueueableExecuting) {
// Set the static boolean variable to prevent trigger execution
OpportunityTriggerHandlerHelper.isQueueableExecuting = true;

// Enqueue the Queueable job with the Opportunity IDs
System.enqueueJob(new OpportunityQueueable(new Set<Id>(opportunityIds)));
}
}*/
    
}