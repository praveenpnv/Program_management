/**
* @File Name         : VMSJobOpportunityHandler.cls
* @Description       : Handles creation of Opportunities for VMS Jobs when certain criteria are met.
* @Author            : Rizwan Ahmed
* @Last Modified By  : Rizwan Ahmed
* @Last Modified On  : Jul 14, 2025
* @Modification Log  :
*===============================================================================
* Ver   | Date        | Author         | Modification
*===============================================================================
* 1.0   | May 14, 2025| Rizwan Ahmed   | Initial version to create Opportunities for VMS Jobs and associate them back to the Job record.
*/

public class VMSJobOpportunityHandler {
    public static void handle(List<TR1__Job__c> jobList) {
        // Check if logic is enabled via custom setting
        VMS_Opportunity_Creation_Setting__c settings = VMS_Opportunity_Creation_Setting__c.getInstance(UserInfo.getUserId());
        if (settings == null || settings.Is_Enabled__c == false) {
            return;
        }

        List<Opportunity> oppToInsert = new List<Opportunity>();
        Map<TR1__Job__c, Opportunity> jobToOppMap = new Map<TR1__Job__c, Opportunity>();

        Id oppRecordTypeId;

            // Use dynamic describe for production context
            Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
            oppRecordTypeId = rtMap.containsKey('Consultancy') 
                ? rtMap.get('Consultancy').getRecordTypeId() 
                : null;

        for (TR1__Job__c job : jobList) {
            if (
                String.isNotBlank(job.TR1__Unique_VMS_Req_ID__c) &&
                String.isNotBlank(job.TR1__VMS_Status__c) &&
                job.Opportunity__c == null
            ) {
                Opportunity opp = new Opportunity();
                opp.Name = 'VMS Opportunity - ' + job.Name;
                opp.StageName = 'New';
                opp.Type = 'New Business';
                opp.CloseDate = job.TR1__Estimated_End_Date__c != null ? job.TR1__Estimated_End_Date__c : Date.today().addDays(30);
                opp.RecordTypeId = oppRecordTypeId;
                opp.AccountId = job.TR1__Account__c;
                opp.Billing_Entity__c = 'RSD US';
                opp.SR_Job_Prevention__c = true;

                oppToInsert.add(opp);
                jobToOppMap.put(job, opp);              
            }
        }

        if (!oppToInsert.isEmpty()) {
            insert oppToInsert;

            Integer index = 0;
            for (TR1__Job__c job : jobList) {
                if (jobToOppMap.containsKey(job)) {
                    job.Opportunity__c = oppToInsert[index].Id;
                    index++;
                }
            }
        }
    }
}