public class TetrisApplicationAccount {
    
    private static String esbUrl{get{
        if(Test.isRunningTest()){
            return 'https://acc-esb.ausy.solutions/';
        }else{
            return ESBSelector.getESBUrl();
        }
    }} 

  


     
    @InvocableMethod(label='Ausy ESB: Tetris Submit Account')
    public static List<ID> ESBSFSubmitApplication(List<AusyApplicationESBCallable> apps) {
        List<ID> jobIDs = new List<ID>();
        for (AusyApplicationESBCallable a : apps) {
            // Fetch it
            Account app = [SELECT Name from Account WHERE ID = :a.AppId];
            
            // Prepare JSON
            Map<String,Object> msg = new Map<String,Object>();
            msg.put('tag', 'salesforce.account.updated');
            
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
        
    }
}