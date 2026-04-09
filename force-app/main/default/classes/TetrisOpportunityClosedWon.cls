public with sharing class TetrisOpportunityClosedWon {

    @InvocableMethod(label='Ausy ESB: Tetris Submit Opportunity')
    public static List<ID> ESBSFSubmitOpportunity(List<AusyESBCallable> oppties) {
        List<ID> jobIDs = new List<ID>();

        //Gather all opptyIDs
        Set<Id> opptyIdsSet = new Set<Id>();
        for (AusyESBCallable o : oppties) {
            opptyIdsSet.add(o.opptyID);
        }

        //Fetch Opportunities in single query
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name, StageName, Account.Name, OwnerId, Owner.Name, Amount FROM Opportunity WHERE Id IN :opptyIdsSet]);

        for (AusyESBCallable o : oppties) {
            Opportunity opp = oppMap.get(o.opptyID);

            if (opp != null) {
                // Prepare JSON
                Map<String, Object> msg = new Map<String, Object>();
                msg.put('tag', 'salesforce.opportunity.submitted');

                Map<String, Object> payload = new Map<String, Object>();
                Map<String, Object> identifier = new Map<String, Object>();
                identifier.put('id', opp.Id);

                payload.put('identifier', opp.Id);      
                msg.put('payload', payload);
                 System.debug('opp.OwnerId: ' +opp.OwnerId);
                String body = JSON.serialize(msg);  

                String esbURL = ESBSelector.getEsbUrlOpp(opp.OwnerId);
                System.debug('esbURL: ' + esbURL);

                jobIDs.add(System.enqueueJob(new QueueableESBCall(esbURL + 'api/message/add', 'POST', body)));
            } else {
                System.debug('No Opportunity found with ID: ' + o.opptyID);
            }
        }

        return jobIDs;
    }
}