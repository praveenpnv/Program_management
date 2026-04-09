public with sharing class CPTimeFlowPresales {
     
    private static final String esbURL =  'https://esb.ausy.be/';
     
    @InvocableMethod(label='Ausy ESB: CPTimeFlow Submit Opportunity')
    public static List<ID> ESBSFSubmitOpportunity(List<AusyESBCallable> oppties) {
        List<ID> jobIDs = new List<ID>();
        for (AusyESBCallable o : oppties) {
       
            Opportunity opp = [SELECT Name, StageName, Account.name, OwnerId ,Owner.name, amount from Opportunity WHERE ID = :o.opptyID];

            System.debug(opp);
            // Prepare JSON
            Map<String,Object> msg = new Map<String,Object>();
            msg.put('tag', 'salesforce.presales_opportunity.submitted');
            
            Map<String,Object> payload = new Map<String,Object>();
            Map<String,Object> identifier = new Map<String,Object>();
            identifier.put('id', o.opptyID);

            
            payload.put('identifier', o.opptyID);      
            msg.put('payload', payload);
            String body = JSON.serialize(msg);

            string esbURL = ESBSelector.getEsbUrlOpp(opp.OwnerId);
            // Queue the call
            jobIDs.add(System.enqueueJob(new QueueableESBCall(esbURL + 'api/message/add', 'POST', body)));
        }
        return jobIDs;
    }
    
    
}