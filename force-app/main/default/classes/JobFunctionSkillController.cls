public with sharing class JobFunctionSkillController {
    @AuraEnabled(cacheable=false)
    public static List<Map<String,Object>> getSkills(Id jobId) {
        TR1__Job__c job = [
            SELECT Job_Function__r.CodeId__c
            FROM TR1__Job__c
            WHERE Id = :jobId
            LIMIT 1
        ];

       String codeId = job.Job_Function__r?.CodeId__c;
        if (String.isBlank(codeId)) {
            throw new AuraHandledException('Job Function CodeId__c is missing.');
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:TK_PORTAL_API/tx/v10/ontology/v2/suggest-skills-from-professions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        // Use the updated format
        Map<String, Object> payload = new Map<String, Object>{
            'ProfessionCodeIds' => new List<string>{ codeId },
            'Limit' => 50,
            'OutputLanguage' => 'en',
            'Types' => new List<String>{ 'All' }
        };

        req.setBody(JSON.serialize(payload));

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Callout failed: ' + res.getBody());
        }

        // 4. Parse JSON
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> valueMap = (Map<String, Object>) responseMap.get('Value');

        if (valueMap == null || !valueMap.containsKey('SuggestedSkills')) {
            throw new AuraHandledException('No SuggestedSkills found in the response.');
        }

        List<Object> suggestedSkills = (List<Object>) valueMap.get('SuggestedSkills');

        List<Map<String, Object>> skillLabels = new List<Map<String, Object>>();

        for (Object obj : suggestedSkills) {
            Map<String, Object> skill = (Map<String, Object>) obj;
            skillLabels.add(new Map<String, Object>{
                'Id' => skill.get('Id'),
                'Description' => skill.get('Description'),
                'Score' => skill.get('Score')
            });
        }

        return skillLabels;
    }

  @AuraEnabled
public static void upsertJobSkills(String skillsJson, Id jobId) {
    List<JobSkillWrapper> skillWrappers = (List<JobSkillWrapper>) JSON.deserialize(skillsJson, List<JobSkillWrapper>.class);

    List<TR1__Skills__c> toUpsert = new List<TR1__Skills__c>();

    for (JobSkillWrapper sk : skillWrappers) {
        TR1__Skills__c skillRecord;

        if (sk.Id != null && sk.Id.startsWith('row-')) {
            // New record
            skillRecord = new TR1__Skills__c();
            skillRecord.TR1__Job__c = jobId;
        } else {
            // Existing record - only update fields sent
            skillRecord = new TR1__Skills__c(Id = sk.Id);
        }

        // Assign fields if they are provided (not null)
        if (sk.skillCode != null) {
            //skillRecord.TR1__Master_Skill__c = sk.skillCode;
                skillRecord.TR1__Master_Skill__r = new TR1__Master_Skill__c(Skill_Code__c = sk.skillCode);

        }
        if (sk.level != null) {
            skillRecord.TR1__Level__c = sk.level;
        }
        if (sk.duration != null) {
            skillRecord.TR1__Duration_for_Job_Skill__c = sk.duration;
        }

        toUpsert.add(skillRecord);
    }

    if (!toUpsert.isEmpty()) {
        upsert toUpsert;
    }
}
// Bhuvana cHANGE

@AuraEnabled
public static void deleteJobSkills(List<Id> skillIds) {
    if (skillIds == null || skillIds.isEmpty()) {
        return;
    }

    try {
        List<TR1__Skills__c> skillsToDelete = [
            SELECT Id FROM TR1__Skills__c WHERE Id IN :skillIds
        ];
        if (!skillsToDelete.isEmpty()) {
            delete skillsToDelete;
        }
    } catch (Exception e) {
        throw new AuraHandledException('Error deleting skills: ' + e.getMessage());
    }
}
public class JobSkillWrapper {
    @AuraEnabled public String Id;
    @AuraEnabled public String skillCode;
    @AuraEnabled public String level;
    @AuraEnabled public String duration;
}
}