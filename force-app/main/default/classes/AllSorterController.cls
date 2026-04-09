public with sharing class AllSorterController {
    @AuraEnabled(cacheable=true)
    public static String getCorporationId() {
        AllSorterSettings__c setting = AllSorterSettings__c.getOrgDefaults();
        return setting != null ? setting.Corporation_ID__c : null;
    }
}