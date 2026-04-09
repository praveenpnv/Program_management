public with sharing class ESBSelector {
    public static string getEsbUrl(){
        User u = [Select Opco__c From User Where Id = :UserInfo.getUserId()][0];
        system.debug(u.Opco__c);
        switch on u.Opco__c {
            when 'France' {
                return Api_Url__c.getValues('ESB_FR').Url__c;
            }
            when else {
                return Api_Url__c.getValues('ESB_BE').Url__c;
            }
        }
    }
    
    public static string getApiKey(){
        User u = [Select Opco__c From User Where Id = :UserInfo.getUserId()][0];
        system.debug(u.Opco__c);
        switch on u.Opco__c {
            when 'France' {
                return Api_Url__c.getValues('ESB_FR').Key__c;
            }
            when else {
                return Api_Url__c.getValues('ESB_BE').Key__c;
            }
        }
    }
    
    public static string getEsbUrlOpp(string ownerId){
        User u = [Select Opco__c From User Where Id = :ownerId][0];
        system.debug(u.Opco__c);
        switch on u.Opco__c {
            when 'France' {
                return Api_Url__c.getValues('ESB_FR').Url__c;
            }
            when else {
                return Api_Url__c.getValues('ESB_BE').Url__c;
            }
        }
    }
    public static string getApiKeyOpp(string ownerId){
        User u = [Select Opco__c From User Where Id = :ownerId][0];
        system.debug(u.Opco__c);
        switch on u.Opco__c {
            when 'France' {
                return Api_Url__c.getValues('ESB_FR').Key__c;
            }
            when else {
                return Api_Url__c.getValues('ESB_BE').Key__c;
            }
        }
    }
    public static String getEsbUrlForOpco(String opco) {
        if (opco != null) {
            if (opco.equalsIgnoreCase('France')) {
                return Api_Url__c.getValues('ESB_FR').Url__c;
                
            } 
            else{
                return Api_Url__c.getValues('ESB_BE').Url__c;
            }
        }
        
        return null;
    }
    
}