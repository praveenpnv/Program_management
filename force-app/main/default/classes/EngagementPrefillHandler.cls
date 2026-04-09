/**
* @File Name       : EngagementPrefillHandler.cls
* @Description     : Fetches mapped field values from Application and Job to prefill the Closing Report
* @Author          : Rizwan
* @Last Modified By: Rizwan
* @Last Modified On: April 25, 2025
*/
public class EngagementPrefillHandler {

    @AuraEnabled()
    public static List<Map<String, String>> getClosingReportPrefillMaps(Id applicationRecordId) {
        List<Map<String, String>> result = new List<Map<String, String>>();
        try {
            // Step 1: Fetch Application record with Job and its RecordType
            TR1__Application_V2__c app = [
                SELECT Id, TR1__Job__c, TR1__Job__r.RecordType.DeveloperName 
                FROM TR1__Application_V2__c 
                WHERE Id = :applicationRecordId 
                LIMIT 1
            ];

            if (app.TR1__Job__c == null || app.TR1__Job__r.RecordType.DeveloperName == null) {
                throw new AuraHandledException('Job or Job RecordType is missing.');
            }

            Id jobId = app.TR1__Job__c;
            String jobRTDevName = app.TR1__Job__r.RecordType.DeveloperName;

            // Step 2: Fetch matching RecordType for Closing Report
            Id closingRTId = [
                SELECT Id FROM RecordType 
                WHERE SObjectType = 'TR1__Closing_Report__c' 
                AND DeveloperName = :jobRTDevName 
                LIMIT 1
            ].Id;

            // Step 3: Load metadata mappings
            List<TR1__Closing_Report_Mapping__mdt> mappings = [
                SELECT NamespacePrefix,TR1__Closing_Report_Field__c,
                       TR1__Job_Field__c,
                       TR1__Application_V2_Field__c,
                       TR1__Default_Value__c
                FROM TR1__Closing_Report_Mapping__mdt
            ];

            Set<String> jobFields = new Set<String>(), appFields = new Set<String>();
            for (TR1__Closing_Report_Mapping__mdt mapItem : mappings) {
                String prefix = String.isNotBlank(mapItem.NamespacePrefix) ? mapItem.NamespacePrefix + '__' : '';
                if (String.isNotBlank(mapItem.TR1__Job_Field__c)) jobFields.add(prefix + mapItem.TR1__Job_Field__c);
                if (String.isNotBlank(mapItem.TR1__Application_V2_Field__c)) appFields.add(prefix + mapItem.TR1__Application_V2_Field__c);
            }

            // Include fields for logic outside metadata
            jobFields.add('Line_of_Business__c');
            appFields.add('CreatedById');

            // Step 4: Query Job and Application records dynamically
            Map<String, Object> jobData = new Map<String, Object>();
            Map<String, Object> appData = new Map<String, Object>();
            Boolean isCR = false;
            Id sourcerId, createdById;

            if (!jobFields.isEmpty()) {
                String jobQuery = 'SELECT ' + String.join(new List<String>(jobFields), ',') + ' FROM TR1__Job__c WHERE Id = :jobId';
       
                SObject jobRecord = Database.query(jobQuery);
                jobData = jobRecord.getPopulatedFieldsAsMap();
					
                
                isCR = 'CR'.equalsIgnoreCase(String.valueOf(jobData.get('Line_of_Business__c')));
            }

            if (!appFields.isEmpty()) {
                String appQuery = 'SELECT ' + String.join(new List<String>(appFields), ',') +
                                  ', TR1__Applicant__r.Sourcer_Secondary_Recruiter__r.Id ' +
                                  'FROM TR1__Application_V2__c WHERE Id = :applicationRecordId';
                TR1__Application_V2__c appRecord = (TR1__Application_V2__c) Database.query(appQuery);
                appData = appRecord.getPopulatedFieldsAsMap();

                if (appRecord.TR1__Applicant__r?.Sourcer_Secondary_Recruiter__r != null) {
                    sourcerId = appRecord.TR1__Applicant__r.Sourcer_Secondary_Recruiter__r.Id;
                }
                createdById = appRecord.CreatedById;
            }

            // Step 5: Prepare final field-value map
            for (TR1__Closing_Report_Mapping__mdt mapItem : mappings) {
                String prefix = String.isNotBlank(mapItem.NamespacePrefix) ? mapItem.NamespacePrefix + '__' : '';
                String value;
                if (String.isNotBlank(mapItem.TR1__Application_V2_Field__c)) {
                    value = String.valueOf(appData.get(prefix + mapItem.TR1__Application_V2_Field__c));
                } else if (String.isNotBlank(mapItem.TR1__Job_Field__c)) {
                    value = String.valueOf(jobData.get(prefix +mapItem.TR1__Job_Field__c));
                }

                if (String.isBlank(value) && String.isNotBlank(mapItem.TR1__Default_Value__c)) {
                    value = mapItem.TR1__Default_Value__c;
                }

                if (String.isNotBlank(mapItem.TR1__Closing_Report_Field__c)) {
                    result.add(new Map<String, String>{
                        'closingField' => mapItem.TR1__Closing_Report_Field__c,
                        'value' => value
                    });
                }
            }

            // Step 6: Append additional required fields
            result.add(new Map<String, String>{ 'closingField' => 'RecordTypeId', 'value' => closingRTId });

            if (isCR) {
                if (sourcerId != null) {
                    result.add(new Map<String, String>{ 'closingField' => 'TR1__Marketing_Credit__c', 'value' => sourcerId });              
                    result.add(new Map<String, String>{ 'closingField' => 'TR1__Marketing_Percentage__c', 'value' => '25' });
                }
                if (createdById != null) {
                    result.add(new Map<String, String>{ 'closingField' => 'TR1__Candidate_Credit__c', 'value' => createdById });
                    result.add(new Map<String, String>{ 'closingField' => 'TR1__Candidate_Percentage__c', 'value' => '25' });
                }
            }

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching prefill values: ' + e.getMessage());
        }
    }
}