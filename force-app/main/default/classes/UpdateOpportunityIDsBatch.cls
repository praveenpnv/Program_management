public class UpdateOpportunityIDsBatch implements Database.Batchable<SObject> {
    private List<Id> opportunityIds;

    public UpdateOpportunityIDsBatch(List<Id> oppIds) {
        opportunityIds = oppIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Owner.Opco__c, Counter_ID__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Opportunity opp : scope) {
            try {
                String opcoInitials = (opp.Owner.Opco__c != null && opp.Owner.Opco__c.length() >= 2)
                    ? opp.Owner.Opco__c.substring(0, 2).toUpperCase()
                    : 'XX';
                
                String formattedDate = DateTime.now().format('yyyy');
                String counterId = opp.Counter_ID__c; // Use the auto-number field
                
                
                String newRID = opcoInitials + '_' + formattedDate + '_' + counterId;
                opp.Randstad_ID__c = newRID;
                oppsToUpdate.add(opp);
            } catch (Exception e) {
                System.debug('An error occurred while updating the RID in the batch: ' + e.getMessage());
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            try {
                update oppsToUpdate;
            } catch (Exception e) {
                System.debug('An error occurred while updating Opportunities in the batch: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Randstad ID Updated in batch');
    }
}