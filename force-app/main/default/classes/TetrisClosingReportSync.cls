public with sharing class TetrisClosingReportSync {
    
    @InvocableMethod(label='Sync Closing Report to Tetris')
    public static List<ID> syncClosingReport(List<Id> reportIds) {
        List<ID> jobIDs = new List<ID>();
        
        List<TR1__Closing_Report__c> reports = [
            SELECT Id, Name, TR1__Status__c, TR1__Job_Credit__r.Opco__c
            FROM TR1__Closing_Report__c
            WHERE Id IN :reportIds
            AND TR1__Job_Credit__r.Opco__c != 'US'
        ];
        
        for (TR1__Closing_Report__c report : reports) {
            // JSON message
            Map<String, Object> msg = new Map<String, Object>();
            msg.put('tag', 'salesforce.closing_report.submitted');
            //msg.put('reportId', report.Id);
            
            // payload data Tetris
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('identifier', report.id);
            //payload.put('status', report.TR1__Status__c);
            
            // Add the payload to the message
            msg.put('payload', payload);          
            
            // Serialize message body to JSON
            String body = JSON.serialize(msg);
            
            // Determine ESB URL based on Opco
            String esbURL = ESBSelector.getEsbUrlForOpco(report.TR1__Job_Credit__r.Opco__c);
            
            // Enqueue message to QueueableESB
            //jobIDs.add(System.enqueueJob(new QueueableESBCall(esbURL + 'api/message/add', 'POST', body)));
        }
        
        
        return jobIDs;
    }
    
}