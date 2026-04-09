/**
* @File Name : JobPrefillHandler.cls
* @Description :
* @Author :Milan Prasad
* @Last Modified By :
* @Last Modified On : May 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 23, 2025 |   | Initial Version
**/

public with sharing class JobPrefillHandler {
    @AuraEnabled
    public static List<Map<String, String>> createJobsFromLineItems(List<Id> lineItemIds) {
        try {
            List<TR1__job__c> jobsToInsert = new List<TR1__job__c>();
            List<Map<String, String>> jobResults = new List<Map<String, String>>();

            List<Opportunity_LineItem_Mapping__mdt> mappings = [
                SELECT NamespacePrefix, Opportunity_Field__c, Job_Field__c, LineItem_Field__c, Default_Value__c
                FROM Opportunity_LineItem_Mapping__mdt
            ];

            Set<String> oppFields = new Set<String>{'Id'};
            Set<String> lineItemFields = new Set<String>{'Id', 'OpportunityId', 'Job_Type__c', 'Number_of_Positions__c'};

            for (Opportunity_LineItem_Mapping__mdt mapItem : mappings) {
                String prefix = String.isNotBlank(mapItem.NamespacePrefix) ? mapItem.NamespacePrefix + '__' : '';
                if (String.isNotBlank(mapItem.Opportunity_Field__c)) oppFields.add(prefix + mapItem.Opportunity_Field__c);
                if (String.isNotBlank(mapItem.LineItem_Field__c)) lineItemFields.add(prefix + mapItem.LineItem_Field__c);
            }

            String lineItemQuery = 'SELECT ' + String.join(new List<String>(lineItemFields), ',') + ' FROM OpportunityLineItem WHERE Id IN :lineItemIds';
            List<SObject> lineItems = Database.query(lineItemQuery);

            system.debug('lineItems'+lineItems);

            Set<Id> opportunityIds = new Set<Id>();
            Map<Id, SObject> lineItemMap = new Map<Id, SObject>();
            for (SObject li : lineItems) {
                lineItemMap.put((Id)li.get('Id'), li);
                opportunityIds.add((Id)li.get('OpportunityId'));
            }

            String oppQuery = 'SELECT ' + String.join(new List<String>(oppFields), ',') + ' FROM Opportunity WHERE Id IN :opportunityIds';
            Map<Id, SObject> oppMap = new Map<Id, SObject>(Database.query(oppQuery));

            system.debug('oppMap'+oppMap);

            Map<String, Id> recordTypeMap = new Map<String, Id>();
            for (RecordType rt : [
                 SELECT Id, Name FROM RecordType WHERE SObjectType = 'TR1__job__c' AND Name IN ('Permanent', 'Consulting','Solutions')
            ]) {
                recordTypeMap.put(rt.Name, rt.Id);
            }

           system.debug('recordTypeMap'+recordTypeMap);

            for (Id liId : lineItemIds) {
                SObject lineItem = lineItemMap.get(liId);
                SObject opp = oppMap.get((Id)lineItem.get('OpportunityId'));

                Decimal numPosDecimal = (Decimal)lineItem.get('Number_of_Positions__c');
                Integer numberOfJobs = (numPosDecimal != null) ? numPosDecimal.intValue() : 1;

                Map<String, Object> lineItemData = lineItem.getPopulatedFieldsAsMap();
                Map<String, Object> oppData = opp.getPopulatedFieldsAsMap();

                system.debug('lineItemData'+lineItemData);
                system.debug('oppData'+oppData);

                for (Integer i = 0; i < numberOfJobs; i++) {
                    TR1__job__c newJob = new TR1__job__c();
                    newJob.Opportunity__c = opp.Id;
                    newJob.OpportunityLineItem__c = liId;

                    for (Opportunity_LineItem_Mapping__mdt mapItem : mappings) {
                        String prefix = String.isNotBlank(mapItem.NamespacePrefix) ? mapItem.NamespacePrefix + '__' : '';
                        String jobField = prefix + mapItem.Job_Field__c;
                        Object value;

                        if (String.isNotBlank(mapItem.LineItem_Field__c)) {
                            value = lineItemData.get(prefix + mapItem.LineItem_Field__c);
                        }
                        if ((value == null || String.valueOf(value).trim() == '') && String.isNotBlank(mapItem.Opportunity_Field__c)) {
                            value = oppData.get(prefix + mapItem.Opportunity_Field__c);
                        }
                        if ((value == null || String.valueOf(value).trim() == '') && String.isNotBlank(mapItem.Default_Value__c)) {
                            value = mapItem.Default_Value__c;
                        }

                        if (String.isNotBlank(mapItem.Job_Field__c) && value != null) {
                            newJob.put(jobField, value);
                        }
                    }

                    system.debug('newJob'+newJob);

                    String jobType = (String)lineItem.get('Job_Type__c');
                    if (jobType == 'Permanent') {
                        newJob.RecordTypeId = recordTypeMap.get('Permanent');
                    } else if (jobType == 'Contract') {
                        newJob.RecordTypeId = recordTypeMap.get('Consulting');
                    }
                    else if (jobType == 'Solutions') {
                        newJob.RecordTypeId = recordTypeMap.get('Solutions');
                    }
                    String jobName = newJob.Name; // whatever is coming from source
                    newJob.Name = jobName.trim() + ' ' + (i + 1) + ' of ' + numberOfJobs;
                    jobsToInsert.add(newJob);
                    system.debug('jobsToInsert'+jobsToInsert);
                }
            }

    Savepoint sp = Database.setSavepoint();
try{
Boolean canCreateJob = Schema.SObjectType.TR1__job__c.isCreateable();
if (!canCreateJob) {
        throw new AuraHandledException('You do not have permission to create Job records.');
    }
insert jobsToInsert[0];

     system.debug('jobsToInsert'+jobsToInsert);

    // Add first job to results
    jobResults.add(new Map<String, String>{
        'jobId'     => jobsToInsert[0].Id,
        'lineItemId'=> jobsToInsert[0].OpportunityLineItem__c,
        'jobName'   => jobsToInsert[0].Name
    });
TriggerBypassUtil.bypassedFlows.add('JobPrefillHandler');  
    // Insert remaining jobs if any
    if (jobsToInsert.size() > 1) {
        system.debug('jobsToInsert123'+jobsToInsert);
        List<TR1__job__c> remainingJobs = new List<TR1__job__c>();
        for (Integer i = 1; i < jobsToInsert.size(); i++) {
            remainingJobs.add(jobsToInsert[i]);
        }

        insert remainingJobs;
        system.debug('remainingJobs'+remainingJobs)	;

        // Add remaining jobs to results
        for (TR1__job__c job : remainingJobs) {
            jobResults.add(new Map<String, String>{
                'jobId'     => job.Id,
                'lineItemId'=> job.OpportunityLineItem__c,
                'jobName'   => job.Name
            });
        }
    }
    
      return jobResults;
   
}catch(DmlException e){
    Database.rollback(sp);
    throw new AuraHandledException(e.getMessage());

}
        } catch (Exception e) {
            throw new AuraHandledException('Error creating jobs: ' + e.getMessage());
        }
    }
}