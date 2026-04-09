public with sharing class JobDatatableController {

    /**
     * @description Helper to get the logged-in user's Opco for data segregation.
     * @return The Opco__c value of the current user.
     */
    private static String getCurrentUserOpco() {
        User u = [SELECT Opco__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        // It's crucial that the user has an Opco. If not, queries should not return data.
        return u.Opco__c;
    }
    
    /**
     * @description Centralized helper to get all user IDs in a manager's hierarchy.
     * @param managerId The ID of the top-level manager or leader.
     * @return A set of all User IDs in the hierarchy.
     */
    private static Set<Id> getRecursiveHierarchyIds(Id managerId) {
        List<ManagerTeamController.UserDTO> subordinateMembers = ManagerTeamController.getRecursiveTeamMembers(managerId);
        Set<Id> hierarchyIds = new Set<Id>();
        hierarchyIds.add(managerId); // Include the manager/leader themselves
        for (ManagerTeamController.UserDTO member : subordinateMembers) {
            hierarchyIds.add(member.Id);
        }
        System.debug('Hierarchy IDs: ' + hierarchyIds);
        return hierarchyIds;
    }

    /**
     * @description Gets all users in a hierarchy and separates their IDs into sets based on their role,
     *              which determines how they receive placement credit.
     * @param managerId The ID of the top-level manager or leader.
     * @return A Map<String, Set<Id>> containing 'candidateCreditIds' and 'jobCreditIds'.
     */
    private static Map<String, Set<Id>> getHierarchyIdsByCreditType(Id managerId) {
        Set<String> recruiterRoles = new Set<String>{'Recruiter', 'Recruiting Manager', 'Recruiting Leader'};
        Set<String> salesRoles = new Set<String>{'Sales (Account Manager)', 'Sales Manager', 'Sales Leader'};

        // Get the current user's info to include them in the logic
        User manager = [SELECT Id, Dashboard_Role__c FROM User WHERE Id = :managerId];
        List<ManagerTeamController.UserDTO> subordinateMembers = ManagerTeamController.getRecursiveTeamMembers(managerId);

        Set<Id> candidateCreditIds = new Set<Id>();
        Set<Id> jobCreditIds = new Set<Id>();

        // Process the manager/leader first
        if (recruiterRoles.contains(manager.Dashboard_Role__c)) candidateCreditIds.add(manager.Id);
        if (salesRoles.contains(manager.Dashboard_Role__c)) jobCreditIds.add(manager.Id);

        // Process all subordinates
        for (ManagerTeamController.UserDTO member : subordinateMembers) {
            if (recruiterRoles.contains(member.dashboardRole)) candidateCreditIds.add(member.Id);
            if (salesRoles.contains(member.dashboardRole)) jobCreditIds.add(member.Id);
        }

        return new Map<String, Set<Id>>{
            'candidateCreditIds' => candidateCreditIds,
            'jobCreditIds' => jobCreditIds
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<TR1__Job__c> getJobs(Integer pageSize, Integer pageNumber,Id currentUserId) {
        if (currentUserId == null) currentUserId = UserInfo.getUserId();
        Integer offsetRecords = (pageNumber - 1) * pageSize;
        Set<Id> hierarchyIds = getRecursiveHierarchyIds(currentUserId);
        String userOpco = getCurrentUserOpco();

        // If user has no Opco, they should not see any jobs.
        if (String.isBlank(userOpco)) {
            return new List<TR1__Job__c>();
        }

        return [
            SELECT Id,
                   Name,
                   TR1__Open_Date__c,
                   Randstad_ID__c,
                   Responsible_Recruiter__c,
                   Responsible_Recruiter__r.Name,
                   Collaborator__c,
                   TR1__Status__c,
                   RecordType.Name,
                   TR1__Job_Stage_Banner__c,
                   TR1__Job_Number__c,
                   Owner.Name,
                   Job_priority__c
            FROM TR1__Job__c 
            WHERE (OwnerId IN :hierarchyIds OR Responsible_Recruiter__c IN :hierarchyIds)
            AND User_Opco__c = :userOpco           
            AND TR1__Status__c NOT IN ('Closed', 'Placed')
            ORDER BY Job_Expiry_Date__c ASC NULLS LAST
            LIMIT :pageSize OFFSET :offsetRecords
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalJobCount(Id currentUserId) {
        if (currentUserId == null) currentUserId = UserInfo.getUserId();
        Set<Id> hierarchyIds = getRecursiveHierarchyIds(currentUserId);
        String userOpco = getCurrentUserOpco();

        if (String.isBlank(userOpco)) {
            return 0;
        }

        return [
            SELECT COUNT()
            FROM TR1__Job__c
            WHERE (OwnerId IN :hierarchyIds OR Responsible_Recruiter__c IN :hierarchyIds)
            AND User_Opco__c = :userOpco
           AND TR1__Status__c NOT IN ('Closed', 'Placed')
        ];
    }

    @AuraEnabled
    public static void updateJobs(List<TR1__Job__c> jobsToUpdate) {
        try {
            update jobsToUpdate;
        } catch(DmlException e) {
            throw new AuraHandledException('Error updating jobs: ' + e.getMessage());
        }
    }

    // Optional: fetch users for Responsible Recruiter picklist
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers() {
        String userOpco = getCurrentUserOpco();
        if (String.isBlank(userOpco)) {
            return new List<User>();
        }
        return [SELECT Id, Name FROM User WHERE IsActive = true AND Opco__c = :userOpco ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getTeamRecruiters(Id currentUserId) {
        if (currentUserId == null) currentUserId = UserInfo.getUserId();   
        Set<Id> hierarchyIds = getRecursiveHierarchyIds(currentUserId);
        String userOpco = getCurrentUserOpco();
        if (String.isBlank(userOpco)) {
            return new List<User>();
        }
        return [
            SELECT Id, Name 
            FROM User 
            WHERE Id IN :hierarchyIds AND Opco__c = :userOpco
            AND IsActive = true
            AND (Dashboard_Role__c = 'Recruiter' OR Id = :currentUserId)
            ORDER BY Name
        ];
    }


//Recruiter Dashboard Code to fetch Job / Placements   - RecruiterJobsDatatable.js
// ------------------ JOB METHODS ------------------
    @AuraEnabled(cacheable=true)
    public static List<TR1__Job__c> getRecruiterJobs(Integer pageSize, Integer pageNumber, Id currentUserId) {
        if (currentUserId == null) {
            currentUserId = UserInfo.getUserId();
        }
        Integer offsetRecords = (pageNumber - 1) * pageSize;

        String userOpco = getCurrentUserOpco();
        if (String.isBlank(userOpco)) {
            return new List<TR1__Job__c>();
        }

        User currentUser = [SELECT Id, Dashboard_Role__c FROM User WHERE Id = :currentUserId LIMIT 1];
        
        String whereClause;
        if (currentUser.Dashboard_Role__c == 'Sales (Account Manager)') {
            whereClause = 'OwnerId = :currentUserId';
        } else {
            Set<Id> hierarchyIds = getRecursiveHierarchyIds(currentUserId);
            System.debug('hierarchyIds for getRecruiterJobs: ' + hierarchyIds);
            whereClause = 'Responsible_Recruiter__c IN :hierarchyIds';
        }

        String query = 'SELECT Id, Name, TR1__Open_Date__c, Randstad_ID__c, ' +
                       'Responsible_Recruiter__c, Responsible_Recruiter__r.Name, ' +
                       'Collaborator__c, TR1__Status__c, RecordType.Name, Owner.Name, ' +
                       'TR1__Job_Number__c, Job_priority__c, TR1__Job_Stage_Banner__c ' +
                       'FROM TR1__Job__c ' +
                       'WHERE ' + whereClause + ' ' +
                       'AND User_Opco__c = :userOpco ' +
                       'AND TR1__Status__c NOT IN (\'Closed\', \'Placed\') ' +
                       'ORDER BY Job_Expiry_Date__c ASC NULLS LAST ' +
                       'LIMIT :pageSize OFFSET :offsetRecords';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Integer getRecruiterJobCount(Id currentUserId) {
        if (currentUserId == null) {
            currentUserId = UserInfo.getUserId();
        }
        String userOpco = getCurrentUserOpco();
        if (String.isBlank(userOpco)) {
            return 0;
        }
        
        User currentUser = [SELECT Id, Dashboard_Role__c FROM User WHERE Id = :currentUserId LIMIT 1];

        String whereClause;
        if (currentUser.Dashboard_Role__c == 'Sales (Account Manager)') {
            whereClause = 'OwnerId = :currentUserId';
        } else {
            Set<Id> hierarchyIds = getRecursiveHierarchyIds(currentUserId);
            whereClause = 'Responsible_Recruiter__c IN :hierarchyIds';
        }

        String query = 'SELECT COUNT() FROM TR1__Job__c WHERE ' + whereClause + ' ' +
                       'AND User_Opco__c = :userOpco AND TR1__Status__c NOT IN (\'Closed\', \'Placed\')';

        return Database.countQuery(query);
    }

    // ------------------ PLACEMENT METHODS ------------------
    @AuraEnabled(cacheable=true)
    public static List<TR1__Closing_Report__c> getRecruiterPlacements(Integer pageSize, Integer pageNumber, Id currentUserId) {
        if (currentUserId == null) {
            currentUserId = UserInfo.getUserId();
        }
        Integer offsetRecords = (pageNumber - 1) * pageSize;
        String userOpco = getCurrentUserOpco();

        if (String.isBlank(userOpco)) {
            return new List<TR1__Closing_Report__c>();
        }
        
        Map<String, Set<Id>> creditIds = getHierarchyIdsByCreditType(currentUserId);
        Set<Id> candidateCreditIds = creditIds.get('candidateCreditIds');
        Set<Id> jobCreditIds = creditIds.get('jobCreditIds');

        System.debug('Candidate Credit IDs for Placements: ' + candidateCreditIds);
        System.debug('Job Credit IDs for Placements: ' + jobCreditIds);

        return 
         [
            SELECT Id, Name, Status_US__c, Scheduled_End__c, End_Date_In_Days__c,
                   TR1__Job__r.Owner.Name, TR1__Job_Credit__c, TR1__Candidate_Credit__c,
                   TR1__Candidate_Credit__r.Name, TR1__Job__r.Responsible_Recruiter__r.Name,
                   TR1__Start_Date__c, TR1__Person_Placed__r.Name,
                   TR1__Account__r.Name,
                   RecordType.Name
            FROM TR1__Closing_Report__c
            WHERE (TR1__Candidate_Credit__c IN :candidateCreditIds OR TR1__Job_Credit__c IN :jobCreditIds)
            AND User_Opco__c = :userOpco
            AND RecordType.DeveloperName IN ('Consulting', 'Permanent', 'Solutions')
            AND Status_US__c != 'Closed'
            ORDER BY End_Date_In_Days__c ASC NULLS LAST
            LIMIT :pageSize OFFSET :offsetRecords
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer getRecruiterPlacementCount(Id currentUserId) {
        if (currentUserId == null) {
            currentUserId = UserInfo.getUserId();
        }
        String userOpco = getCurrentUserOpco();
        if (String.isBlank(userOpco)) {
            return 0;
        }

        Map<String, Set<Id>> creditIds = getHierarchyIdsByCreditType(currentUserId);
        Set<Id> candidateCreditIds = creditIds.get('candidateCreditIds');
        Set<Id> jobCreditIds = creditIds.get('jobCreditIds');

        return [
            SELECT COUNT()
            FROM TR1__Closing_Report__c
            WHERE (TR1__Candidate_Credit__c IN :candidateCreditIds OR TR1__Job_Credit__c IN :jobCreditIds)
            AND User_Opco__c = :userOpco
            AND RecordType.DeveloperName IN ('Consulting', 'Permanent', 'Solutions')
            AND Status_US__c != 'Closed'
        ];
    }

    // ------------------ END ------------------


}