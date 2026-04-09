/*
*RIG Link Controller called from LWC Component
*/
public with sharing class RIG_LinkController {

    public static final String BASE_URL = 'Base_Url';

    //Get the Base URL to build the links dynamically
    @AuraEnabled(cacheable=true)
    public static String getBaseRIGURL(String recordId) {
       String baseUrl = getBaseUrl();
       
       if (String.isBlank(baseUrl)){
        return null;
       }
       return getFormattedUrl(baseUrl, recordId);
    }

    public static String getAlternateID(String entityName, String recordId) {
        String entity = entityName.toUpperCase();
        if (entity == 'ACCOUNT') {
            List<Account> lstAccount = [SELECT Id,Randstad_ID__c FROM Account WHERE ID = :recordId];
            if (lstAccount.size() > 0) {
                return lstAccount[0].Randstad_ID__c;
            }
        }

        if (entity == 'CONTACT') {
            List<Contact> lstContact = [SELECT Id,Randstad_ID__c FROM Contact WHERE ID = :recordId];
            if (lstContact.size() > 0) {
                return lstContact[0].Randstad_ID__c;
            }
        }

        
        if (entity == 'TR1__JOB__c') {
            List<TR1__Job__c> lstJob = [SELECT Id,TR1__Job_Number__c FROM TR1__Job__c WHERE ID = :recordId];
            if (lstJob.size() > 0) {
                return lstJob[0].TR1__Job_Number__c;
            }
        }

        if (entity == 'TR1__ClOSING_REPORT__c') {
            List<TR1__Closing_Report__c> lstEngagement = [SELECT Id,Name FROM TR1__Closing_Report__c WHERE ID = :recordId];
            if (lstEngagement.size() > 0) {
                return lstEngagement[0].Name;
            }
        }

        return null;
    }

    @TestVisible
    private static String getFormattedUrl(String url, Id recordId) {
        if (String.isEmpty(recordId)) {
            return null;
        }

        String entityName = recordId.getSObjectType().getDescribe().getName();
        String alternateId = getAlternateID(entityName, recordId);
        
        List<String> lstAll = new List<String>();

        lstAll.add(entityName);
        lstAll.add(alternateId); //Auto number field is set as Entity ID
        lstAll.add(recordId); //Record ID is set in Alt ID
        lstAll.add(UserInfo.getUserId());

        return String.format(url, lstAll).trim();
    }

    // Query and find the Base Url based on the environment
    @TestVisible
    private static String getBaseUrl() {
        List<Environment__mdt> environmentList = [SELECT Id, RIG_Base_Url__c
                             FROM Environment__mdt WHERE DeveloperName = :BASE_URL 
                             LIMIT 1];
        if (environmentList.size() > 0 && environmentList[0].RIG_Base_Url__c != null) {
            return (environmentList[0].RIG_Base_Url__c).trim();
        }
        return null;
    }
   
}