public with sharing class ManagerTeamController {

    public class UserDTO {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Email;
        @AuraEnabled public String dashboardRole;
    }

    // Helper: Get logged-in user's Opco
    private static String getCurrentUserOpco() {
        return [SELECT Opco__c FROM User WHERE Id = :UserInfo.getUserId()].Opco__c;
    }

    // 1. Get all available users (restricted by Opco)
    @AuraEnabled(cacheable=true)
    public static List<UserDTO> getAvailableUsers(String type) {
        List<UserDTO> results = new List<UserDTO>();

        String currentOpco = getCurrentUserOpco();
        if (String.isBlank(currentOpco)) {
            System.debug(' Logged-in user does not have Opco__c set');
            return results;
        }
        
        // Decide allowed profiles based on type
        Set<String> allowedProfiles = new Set<String>();
        if (type == 'Account Manager') {
            allowedProfiles.add('Sales (Account Manager)');
        } else if (type == 'Recruiter') {
            allowedProfiles.add('Recruiter');
        } else if (type == 'All') {
            allowedProfiles.add('Sales (Account Manager)');
            allowedProfiles.add('Recruiting Manager');
            allowedProfiles.add('Sales Manager');
            allowedProfiles.add('Recruiting Leader');
            allowedProfiles.add('Sales Leader');
        }else{
            allowedProfiles.add(type);      
        }

        if (allowedProfiles.isEmpty()) {
            System.debug(' Invalid type passed: ' + type);
            return results;
        }

        // Base user query (restricted to same Opco)
        List<User> users = [
            SELECT Id, Name, Email
            FROM User
            WHERE IsActive = true
            AND Dashboard_Role__c IN :allowedProfiles
            AND Opco__c = :currentOpco
            ORDER BY Name
            LIMIT 2000
        ];

        // Map users to DTOs
        for (User u : users) {
            UserDTO dto = new UserDTO();
            dto.Id = u.Id;
            dto.Name = u.Name;
            dto.Email = u.Email;
            results.add(dto);
        }

        return results;
    }

    // 2. Get current team members for logged-in RM
    @AuraEnabled(cacheable=true)
    public static List<UserDTO> getTeamMembers(String type, Id currentUserId) { 
        if (currentUserId == null) currentUserId = UserInfo.getUserId();
        
        // We will get the direct team members first
        List<UserDTO> results = new List<UserDTO>();
        for (Manager_Team_Member__c mtm : [
            SELECT Id, Manager__r.Id, Manager__r.Name, Manager__r.Email
            FROM Manager_Team_Member__c
            WHERE Recruiter_Manager__c = :currentUserId
            AND Role__c = :type
            AND Active__c = true
        ]) 
        {
            UserDTO dto = new UserDTO();
            dto.Id = mtm.Manager__r.Id;
            dto.Name = mtm.Manager__r.Name;
            dto.Email = mtm.Manager__r.Email;
            results.add(dto);
        }

        return results;
    }

    // New method to get all team members recursively
    @AuraEnabled(cacheable=true)
    public static List<UserDTO> getRecursiveTeamMembers(Id managerId) {
        if (managerId == null) {
            managerId = UserInfo.getUserId();
        }
        Set<Id> visitedIds = new Set<Id>();
        return getRecursiveTeamMembersHelper(new Set<Id>{managerId}, visitedIds);
    }

    private static List<UserDTO> getRecursiveTeamMembersHelper(Set<Id> managerIds, Set<Id> visitedIds) {
        List<UserDTO> members = new List<UserDTO>();
        Set<Id> nextLevelManagerIds = new Set<Id>();

        for (Manager_Team_Member__c mtm : [
            SELECT Manager__r.Id, Manager__r.Name, Manager__r.Email, Manager__r.Dashboard_Role__c
            FROM Manager_Team_Member__c 
            WHERE Recruiter_Manager__c IN :managerIds AND Active__c = true
        ]) {
            if (!visitedIds.contains(mtm.Manager__r.Id)) {
                visitedIds.add(mtm.Manager__r.Id);
                UserDTO dto = new UserDTO();
                dto.Id = mtm.Manager__r.Id;
                dto.Name = mtm.Manager__r.Name;
                dto.Email = mtm.Manager__r.Email;
                dto.dashboardRole = mtm.Manager__r.Dashboard_Role__c;
                members.add(dto);
                nextLevelManagerIds.add(mtm.Manager__r.Id);
            }
        }

        if (!nextLevelManagerIds.isEmpty()) {
            members.addAll(getRecursiveTeamMembersHelper(nextLevelManagerIds, visitedIds));
        }

        return members;
    }

    // 3. Add new member to team
    @AuraEnabled
    public static void addToTeam(Id userId, String type, Id currentUserId) {
        if (currentUserId == null) currentUserId = UserInfo.getUserId();

        // Check if user is already in team      
        List<Manager_Team_Member__c> existingAssignments = [
            SELECT Id FROM Manager_Team_Member__c
            WHERE Recruiter_Manager__c = :currentUserId
            AND Manager__c = :userId
            AND Role__c = :type
            AND Active__c = true
            LIMIT 1
        ];

        Boolean exists = !existingAssignments.isEmpty();
        
        if (exists) {
            throw new AuraHandledException('This user is already in your team.');
        }

        Manager_Team_Member__c newAssignment = new Manager_Team_Member__c(
            Recruiter_Manager__c = currentUserId,
            Manager__c = userId,
            Role__c = type,
            Active__c = true,
            Assignment_Key__c = currentUserId + '_' + userId
        );
        insert newAssignment;
    }
    
    @AuraEnabled
    public static void removeFromTeam(Id userId, String type, Id currentUserId) {
        if (currentUserId == null) currentUserId = UserInfo.getUserId();
        
        List<Manager_Team_Member__c> assignments = [
            SELECT Id 
            FROM Manager_Team_Member__c
            WHERE Recruiter_Manager__c = :currentUserId
            AND Manager__c = :userId
            AND Role__c = :type
            AND Active__c = true
        ];
    
        if (assignments.isEmpty()) {
            throw new AuraHandledException('This user is not in your team.');
        }
    
        // Delete the assignment records
        delete assignments;
    }

}