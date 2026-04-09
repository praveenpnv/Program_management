/**
* This Class has been deprecated  tag: salesforce.application.closed is deprecated and won’t be used anymore in the new RDOne setup,
   the functionality will be replaced by the new tag: salesforce.closing_report.submitted
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* TetrisApplicationClosed
* @description    This class is being used When an application stage is updated to "Closing Report" send a message to the ESB.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @version        1.0
* @created        
* @modified       26-06-2024
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
**/
public with sharing class TetrisApplicationClosed {
     
    //private static final String esbURL = 'https://acc-esb.ausy.solutions/';
    
   /* private static String esbUrl{get{
        if(Test.isRunningTest()){
            return 'https://esb.ausy.solutions/';
        }else{
            return ESBSelector.getESBUrl();
        }
    }} 
     
    @InvocableMethod(label='Ausy ESB: Tetris Submit Application')
    public static List<ID> ESBSFSubmitApplication(List<AusyApplicationESBCallable> apps) {
        List<ID> jobIDs = new List<ID>();
        for (AusyApplicationESBCallable a : apps) {
            // Fetch it
            TR1__Application_V2__c app = [SELECT Name, TR1__Job__r.id, TR1__Job_Contact__c from TR1__Application_V2__c WHERE ID = :a.AppId];
            
            // Prepare JSON
            Map<String,Object> msg = new Map<String,Object>();
            msg.put('tag', 'salesforce.application.closed');
            
            Map<String,Object> payload = new Map<String,Object>();
            Map<String,Object> identifier = new Map<String,Object>();
            identifier.put('id',a.AppId);

            
            payload.put('identifier', a.AppId);   
            msg.put('payload', payload);
            system.debug('Payload: ' +payload);
            String body = JSON.serialize(msg);  
            
           
            // Queue the call
            jobIDs.add(System.enqueueJob(new QueueableESBCall(esbURL + 'api/message/add', 'POST', body)));
        }
        return jobIDs;
        
    }*/
    
}