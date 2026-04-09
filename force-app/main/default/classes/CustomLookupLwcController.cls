public with sharing class CustomLookupLwcController {
    
    // Method to fetch lookup search result
    @AuraEnabled(cacheable=true)
    public static List<sObject> fetchLookupData(String searchKey, String sObjectApiName, String type) {
        List<sObject> returnList = new List<sObject>();
        
        // Use ManagerTeamController for user-specific data
        if (sObjectApiName == 'User') {
            List<ManagerTeamController.UserDTO> users = ManagerTeamController.getAvailableUsers(type);
            for (ManagerTeamController.UserDTO u : users) {
                if (String.isBlank(searchKey) || u.Name.toLowerCase().contains(searchKey.toLowerCase())) {
                    Map<String, Object> userMap = new Map<String, Object>();
                    userMap.put('attributes', new Map<String, Object>{ 'type' => 'User' });
                    userMap.put('Id', u.Id);
                    userMap.put('Name', u.Name);
                    returnList.add((sObject)JSON.deserialize(JSON.serialize(userMap), sObject.class));
                }
            }
            return returnList;
        }

        // Generic lookup for other sObjects (unmodified)
        String sWildCardText = '%' + searchKey + '%';
        String sQuery = 'SELECT Id, Name FROM ' + sObjectApiName + ' WHERE Name LIKE :sWildCardText AND IsActive = true ORDER BY CreatedDate DESC LIMIT 5';
        for (sObject obj : Database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    // Method to fetch lookup default value
    @AuraEnabled
    public static sObject fetchDefaultRecord(String recordId, String sObjectApiName, String type) {
        
        // Use ManagerTeamController for user-specific data
        if (sObjectApiName == 'User') {
            List<ManagerTeamController.UserDTO> users = ManagerTeamController.getAvailableUsers(type);
            for (ManagerTeamController.UserDTO u : users) {
                if (u.Id == recordId) {
                    Map<String, Object> userMap = new Map<String, Object>();
                    userMap.put('attributes', new Map<String, Object>{ 'type' => 'User' });
                    userMap.put('Id', u.Id);
                    userMap.put('Name', u.Name);
                    return (sObject)JSON.deserialize(JSON.serialize(userMap), sObject.class);
                }
            }
            return null;
        }

        // Generic lookup for other sObjects (unmodified)
        String sRecId = recordId;
        String sQuery = 'SELECT Id, Name FROM ' + sObjectApiName + ' WHERE Id = :sRecId AND IsActive = true LIMIT 1';
        for (sObject obj : Database.query(sQuery)) {
            return obj;
        }
        return null;
    }
}