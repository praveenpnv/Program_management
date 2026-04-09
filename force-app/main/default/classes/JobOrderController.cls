public with sharing class JobOrderController {
   @AuraEnabled
   public static void extendJob(Id jobId, String selectedTime) {
       
       TR1__Job__c job = [SELECT Id, Job_Expiry_Date__c, TR1__Status__c, TR1__Closed_Reason__c FROM TR1__Job__c WHERE Id = :jobId LIMIT 1];
	   
       Integer days = Integer.valueOf(selectedTime);
	   
       DateTime newExpiryDate = DateTime.now().addDays(days);

       job.Job_Expiry_Date__c = newExpiryDate;
       job.Has_Been_Extended__c = true;

       if (job.TR1__Status__c == 'Closed') {
           job.TR1__Status__c = 'Accepting Candidates';
           //job.TR1__Closed_Reason__c = null;
       }

       update job;
   }
    
    @AuraEnabled(cacheable=true)
    public static List<Integer> getExtensionOptions(Id jobId) {
        // Get the job's Opco
        TR1__Job__c job = [
            SELECT Id, User_Opco__c
            FROM TR1__Job__c WHERE Id = :jobId LIMIT 1
        ];

        String opco = job.User_Opco__c;
        List<Integer> days = new List<Integer>();

        if (String.isNotBlank(opco)) {
            List<JobExtensionConfig__mdt> configs = [
                SELECT Allowed_Extension_Days__c FROM JobExtensionConfig__mdt
                WHERE Opco__c = :opco AND Is_Active__c = true LIMIT 1
            ];

            if (!configs.isEmpty()) {
                for (String s : configs[0].Allowed_Extension_Days__c.split(',')) {
                    days.add(Integer.valueOf(s.trim()));
                }
            }
        }
        system.debug('days->'+days);
        return days;
    }
}