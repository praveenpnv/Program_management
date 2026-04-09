public with sharing class ProjectPlatformController {

    private static final String STORY_LIST_SOQL_FIELDS =
        'SELECT Id, Name, Status__c, Priority__c, Story_Points__c, Due_Date__c, Completed_Date__c, ' +
        'Story_Type__c, Is_Global__c, Sprint__c, Description__c, Business_Description__c, Acceptance_Criteria__c, ' +
        'Feature__c, Feature__r.Name, Release__c, Release__r.Name, Requestor__c, ' +
        'Assigned_To__c, Assigned_To__r.Name, QA_Assignee__c, QA_Assignee__r.Name, ' +
        'Blocked__c, Requirement__c, Requirement__r.Name, ' +
        '(SELECT Project__c, Project__r.Name FROM Story_Projects__r) ' +
        'FROM Story__c ';

    // ─── PROGRAMS ───────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<ProgramWrapper> getPrograms() {
        List<ProgramWrapper> result = new List<ProgramWrapper>();
        for (Program__c prog : [
            SELECT Id, Name, Type__c, Status__c, RAG_Status__c, Priority__c,
                   Description__c, Start_Date__c, End_Date__c,
                   Program_Owner__c, Program_Owner__r.Name, Program_Owner__r.SmallPhotoUrl, 
                   (SELECT Id, Name, Status__c, RAG_Status__c, Priority__c,
                           Project_Type__c, Target_Completion_Date__c, Stage__c, Methodology__c, Description__c,OwnerId, Owner.Name,
                           Technical_Owner__c, Technical_Owner__r.Name, Start_Date__c, Program__c, Program__r.Name, 
                           Functional_Owner__c, Functional_Owner__r.Name, Business_Owner__c, Business_Owner__r.Name,
                           Owner__c, Owner__r.Name, Parent_Project__c, Parent_Project__r.Name, Program__r.Type__c
                    FROM Projects__r ORDER BY Priority__c ASC NULLS LAST)
            FROM Program__c
            ORDER BY Type__c ASC, Name ASC
        ]) {
            result.add(new ProgramWrapper(prog));
        }
        return result;
    }
    @AuraEnabled(cacheable=true)
    public static List<Story__c> searchStoriesToLink(String searchTerm, Id currentStoryId) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) return new List<Story__c>();
        
        String likeTerm = '%' + searchTerm + '%';
        return [
            SELECT Id, Name, Story_Type__c, Status__c 
            FROM Story__c 
            WHERE (Name LIKE :likeTerm )
              AND Id != :currentStoryId
            LIMIT 10
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<User> searchMentionUsers(String searchTerm) {
        String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        return [
            SELECT Id, Name, SmallPhotoUrl 
            FROM User 
            WHERE IsActive = true 
            AND Name LIKE :likeTerm 
            ORDER BY Name ASC 
            LIMIT 5
        ];
    }
    @AuraEnabled
    public static Id saveProgram(String programJson) {
        Map<String, Object> d = parseJsonMap(programJson, 'Invalid program data: ');
        Program__c prog = new Program__c();
        if (notBlank(d, 'id'))          prog.Id                = (Id)    d.get('id');
        if (notBlank(d, 'name'))        prog.Name              = (String) d.get('name');
        if (notBlank(d, 'type'))        prog.Type__c           = (String) d.get('type');
        if (notBlank(d, 'status'))      prog.Status__c         = (String) d.get('status');
        if (notBlank(d, 'ragStatus'))   prog.RAG_Status__c     = (String) d.get('ragStatus');
        if (notBlank(d, 'priority'))    prog.Priority__c       = (String) d.get('priority');
        if (d.containsKey('description')) prog.Description__c  = (String) d.get('description');
        if (notBlank(d, 'ownerId'))     prog.Program_Owner__c  = (Id)    d.get('ownerId');
        if (notBlank(d, 'startDate'))   prog.Start_Date__c     = Date.valueOf((String) d.get('startDate'));
        if (notBlank(d, 'endDate'))     prog.End_Date__c       = Date.valueOf((String) d.get('endDate'));
        upsert prog;
        return prog.Id;
    }

    // ─── PROJECTS ────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<ProjectWrapper> getProjects() {
        List<ProjectWrapper> result = new List<ProjectWrapper>();
        for (Project__c p : [
            SELECT Id, Name, Status__c, Stage__c, RAG_Status__c, Methodology__c,
                   Description__c, Start_Date__c, Target_Completion_Date__c, 
                   Owner__c, Owner__r.Name, Owner__r.SmallPhotoUrl,
                   Project_Type__c, Priority__c,OwnerId, Owner.Name,
                   Program__c, Program__r.Name, Program__r.Type__c,
                   Technical_Owner__c, Technical_Owner__r.Name,
                   Functional_Owner__c, Functional_Owner__r.Name,
                   Business_Owner__c, Business_Owner__r.Name,
                   Parent_Project__c, Parent_Project__r.Name,
                   // NEW: Querying the Junction Object instead of the direct story lookup
                   (SELECT Story__r.Id, Story__r.Status__c, Story__r.Due_Date__c, Story__r.Blocked__c FROM Story_Projects__r)
            FROM Project__c
            ORDER BY Priority__c ASC NULLS LAST, LastModifiedDate DESC
        ]) {
            result.add(new ProjectWrapper(p));
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static ProjectWrapper getProject(Id projectId) {
        return new ProjectWrapper([
            SELECT Id, Name, Status__c, Stage__c, RAG_Status__c, Methodology__c,
                   Description__c, Start_Date__c, Target_Completion_Date__c,
                   Owner__c, Owner__r.Name, Owner__r.SmallPhotoUrl,
                   Project_Type__c, Priority__c,OwnerId, Owner.Name,
                   Program__c, Program__r.Name, Program__r.Type__c,
                   Technical_Owner__c, Technical_Owner__r.Name,
                   Functional_Owner__c, Functional_Owner__r.Name,
                   Business_Owner__c, Business_Owner__r.Name,
                   Parent_Project__c, Parent_Project__r.Name,
                   // NEW: Subquery for the single project view as well
                   (SELECT Story__r.Id, Story__r.Status__c, Story__r.Due_Date__c, Story__r.Blocked__c FROM Story_Projects__r)
            FROM Project__c WHERE Id = :projectId LIMIT 1
        ]);
    }

    @AuraEnabled(cacheable=true)
    public static List<Story_Link__c> getLinkedStories(Id storyId) {
        try {
            return [
                SELECT Id, Link_Type__c, Target_Story__c, 
                       Target_Story__r.Name, Target_Story__r.Status__c
                FROM Story_Link__c
                WHERE Source_Story__c = :storyId
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching links: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Story_Link__c linkStories(Id sourceId, Id targetId, String linkType) {
        try {
            Story_Link__c newLink = new Story_Link__c(
                Source_Story__c = sourceId,
                Target_Story__c = targetId,
                Link_Type__c = linkType
            );
            insert newLink;
            
            return [
                SELECT Id, Link_Type__c, Target_Story__c, 
                       Target_Story__r.Name, Target_Story__r.Status__c
                FROM Story_Link__c
                WHERE Id = :newLink.Id
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error creating link: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteStoryLink(Id linkId) {
        try {
            delete new Story_Link__c(Id = linkId);
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting link: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id saveProject(String projectJson) {
        Map<String, Object> d = parseJsonMap(projectJson, 'Invalid project data: ');

        String status      = notBlank(d, 'status')      ? (String) d.get('status')      : null;
        String stage       = notBlank(d, 'stage')        ? (String) d.get('stage')       : null;
        String projectType = notBlank(d, 'projectType')  ? (String) d.get('projectType') : null;

        assertProjectStatusAndStageAlign(status, stage);
        assertTechnicalSupportHasParent(d, projectType);

        Project__c p = new Project__c();
        if (notBlank(d, 'id'))               p.Id                        = (Id)    d.get('id');
        if (notBlank(d, 'name'))             p.Name                      = (String) d.get('name');
        if (d.containsKey('description'))    p.Description__c            = (String) d.get('description');
        if (status      != null)             p.Status__c                 = status;
        if (notBlank(d, 'stage'))            p.Stage__c                  = stage;
        if (notBlank(d, 'ragStatus'))        p.RAG_Status__c             = (String) d.get('ragStatus');
        if (notBlank(d, 'methodology'))      p.Methodology__c            = (String) d.get('methodology');
        if (notBlank(d, 'priority'))         p.Priority__c               = (String) d.get('priority');
        if (notBlank(d, 'startDate'))        p.Start_Date__c             = Date.valueOf((String) d.get('startDate'));
        if (notBlank(d, 'targetDate'))       p.Target_Completion_Date__c = Date.valueOf((String) d.get('targetDate'));
        if (notBlank(d, 'ownerId'))          p.Owner__c                  = (Id)    d.get('ownerId');
        if (projectType != null)             p.Project_Type__c           = projectType;
        if (notBlank(d, 'programId'))        p.Program__c                = (Id)    d.get('programId');
        if (notBlank(d, 'technicalOwnerId')) p.Technical_Owner__c        = (Id)    d.get('technicalOwnerId');
        if (notBlank(d, 'functionalOwnerId')) p.Functional_Owner__c       = (Id)    d.get('functionalOwnerId');
        if (notBlank(d, 'businessOwnerId'))  p.Business_Owner__c         = (Id)    d.get('businessOwnerId');
        if (notBlank(d, 'parentProjectId'))  p.Parent_Project__c         = (Id)    d.get('parentProjectId');
        upsert p;
        return p.Id;
    }

    @AuraEnabled
    public static void updateProjectStage(Id projectId, String newStage) {
        update new Project__c(Id = projectId, Stage__c = newStage);
    }

    // ─── FEATURES ────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<Feature__c> getFeaturesByProject(List<Id> projectIds) {
        if (projectIds == null || projectIds.isEmpty()) return new List<Feature__c>();
        return [
            SELECT Id, Name, Status__c, Priority__c, Description__c,
                   Feature_Owner__c, Feature_Owner__r.Name, Owner_Name__c,
                   Project__c, Project__r.Name
            FROM Feature__c
            WHERE Project__c IN :projectIds
            ORDER BY Project__r.Name, Name
        ];
    }
    @AuraEnabled
    public static List<Feature__c> getFeatureByProject(String projectId) {
        if (projectId == null) return new List<Feature__c>();
        return [
            SELECT Id, Name, Status__c, Priority__c, Description__c,
                   Feature_Owner__c, Feature_Owner__r.Name, Owner_Name__c,
                   Project__c, Project__r.Name
            FROM Feature__c
            WHERE Project__c = :projectId
            ORDER BY Project__r.Name, Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static FeatureDetailWrapper getFeatureWithDetails(Id featureId) {
        Feature__c feat = [
            SELECT Id, Name, Status__c, Priority__c, Description__c,
                   Feature_Owner__c, Feature_Owner__r.Name,
                   Project__c, Project__r.Name
            FROM Feature__c WHERE Id = :featureId LIMIT 1
        ];
        List<Requirement__c> reqs = [
            SELECT Id, Name, Status__c, Priority__c, Category__c,
                   Description__c, Assigned_To__c, Assigned_To__r.Name,
                   Auto_Story_Created__c, Requestor__c, Impact__c, Approval_Status__c,
                   Linked_Story__c, Linked_Story__r.Name, Linked_Story__r.Status__c
            FROM Requirement__c
            WHERE Feature__c = :featureId ORDER BY Name ASC
        ];
        List<Story__c> stories = [
            SELECT Id, Name, Status__c, Priority__c, Story_Type__c,
                   Story_Points__c, Assigned_To__c, Assigned_To__r.Name,
                   Due_Date__c, Is_Global__c, Sprint__c,
                   Requirement__c, Requirement__r.Name,
                   Origin_Project__c, Origin_Project__r.Name
            FROM Story__c
            WHERE Feature__c = :featureId ORDER BY Name ASC
        ];
        return new FeatureDetailWrapper(feat, reqs, stories);
    }

    @AuraEnabled
    public static Id saveFeature(String featureJson) {
        Map<String, Object> d = parseJsonMap(featureJson, 'Invalid feature data: ');
        Feature__c f = new Feature__c();
        if (notBlank(d, 'id')) {
            f.Id = (Id) d.get('id');
        } else {
            if (notBlank(d, 'projectId')) f.Project__c = (Id) d.get('projectId');
        }
        if (notBlank(d, 'name'))          f.Name             = (String) d.get('name');
        if (d.containsKey('description')) f.Description__c   = (String) d.get('description');
        if (notBlank(d, 'status'))        f.Status__c        = (String) d.get('status');
        if (notBlank(d, 'priority'))      f.Priority__c      = (String) d.get('priority');
        if (notBlank(d, 'ownerId'))       f.Feature_Owner__c = (Id)    d.get('ownerId');
        upsert f;
        return f.Id;
    }

    // ─── REQUIREMENTS / CHANGE REQUESTS (unified) ────────────────────────────

    @AuraEnabled
    public static List<Requirement__c> getRequirementsByProject(Id projectId) {
        if (projectId == null) {
            return [
                SELECT Id, Name, Status__c, Priority__c, Category__c,
                       Description__c, Requestor__c, Auto_Story_Created__c,
                       Assigned_To__c, Assigned_To__r.Name, Impact__c, Approval_Status__c,
                       Feature__c, Feature__r.Name, Project__c, Project__r.Name,
                       Linked_Story__c, Linked_Story__r.Name, Linked_Story__r.Status__c
                FROM Requirement__c ORDER BY Name ASC LIMIT 200
            ];
        }
        Set<Id> featureIds = new Map<Id,Feature__c>(
            [SELECT Id FROM Feature__c WHERE Project__c = :projectId]
        ).keySet();
        return [
            SELECT Id, Name, Status__c, Priority__c, Category__c,
                   Description__c, Requestor__c, Auto_Story_Created__c,
                   Assigned_To__c, Assigned_To__r.Name, Impact__c, Approval_Status__c,
                   Feature__c, Feature__r.Name, Project__c, Project__r.Name,
                   Linked_Story__c, Linked_Story__r.Name, Linked_Story__r.Status__c
            FROM Requirement__c
            WHERE Feature__c IN :featureIds OR Project__c = :projectId
            ORDER BY Name ASC
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<Requirement__c> getRequirementsByProjects(List<Id> projectIds) {
        if (projectIds == null || projectIds.isEmpty()) return new List<Requirement__c>();
        
        return [
            SELECT Id, Name, Project__c, Project__r.Name
            FROM Requirement__c
            WHERE Project__c IN :projectIds
            ORDER BY Project__r.Name, Name
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<Requirement__c> getRequirementsByFeature(Id featureId) {
        return [
            SELECT Id, Name, Status__c, Priority__c, Category__c,
                   Description__c, Requestor__c, Auto_Story_Created__c,
                   Assigned_To__c, Assigned_To__r.Name, Feature__c,
                   Impact__c, Approval_Status__c,
                   Linked_Story__c, Linked_Story__r.Name, Linked_Story__r.Status__c
            FROM Requirement__c WHERE Feature__c = :featureId ORDER BY Name ASC
        ];
    }

    @AuraEnabled
    public static Id approveRequirement(Id requirementId) {
        update new Requirement__c(Id = requirementId, Status__c = 'Approved');
        return syncLinkedStoryAfterApproval(requirementId);
    }

    @AuraEnabled
    public static void updateRequirementStatus(Id reqId, String newStatus) {
        update new Requirement__c(Id = reqId, Status__c = newStatus);
        if (newStatus == 'Approved') {
            syncLinkedStoryAfterApproval(reqId);
        }
    }

    @AuraEnabled
    public static Id saveRequirement(String requirementJson) {
        Map<String, Object> d = parseJsonMap(requirementJson, 'Invalid requirement data: ');
        String category = notBlank(d, 'category') ? (String) d.get('category') : null;
        if ('Change Request'.equals(category) &&
            (!d.containsKey('impact') || String.valueOf(d.get('impact')).trim() == '')) {
            throw new AuraHandledException('Change Requests must include an Impact description.');
        }
        Requirement__c r = new Requirement__c();
        if (notBlank(d, 'id'))             r.Id                 = (Id)    d.get('id');
        if (notBlank(d, 'name'))           r.Name               = (String) d.get('name');
        if (d.containsKey('description'))  r.Description__c     = (String) d.get('description');
        if (notBlank(d, 'status'))         r.Status__c          = (String) d.get('status');
        if (notBlank(d, 'priority'))       r.Priority__c        = (String) d.get('priority');
        if (category != null)              r.Category__c        = category;
        if (notBlank(d, 'requestor'))      r.Requestor__c       = (String) d.get('requestor');
        if (notBlank(d, 'featureId'))      r.Feature__c         = (Id)    d.get('featureId');
        if (notBlank(d, 'projectId'))      r.Project__c         = (Id)    d.get('projectId');
        if (notBlank(d, 'assignedToId'))   r.Assigned_To__c     = (Id)    d.get('assignedToId');
        if (d.containsKey('impact'))       r.Impact__c          = (String) d.get('impact');
        if (notBlank(d, 'approvalStatus')) r.Approval_Status__c = (String) d.get('approvalStatus');
        upsert r;
        if (r.Status__c == 'Approved') {
            syncLinkedStoryAfterApproval(r.Id);
        }
        return r.Id;
    }

    // ─── REQUESTS (Stories) ───────────────────────────────────────────────────

    @AuraEnabled
    public static List<Story__c> getStoriesByProject(String projectId) {
        String query = STORY_LIST_SOQL_FIELDS;
        if (String.isNotBlank(projectId)) {
            query += 'WHERE Id IN (SELECT Story__c FROM Story_Project__c WHERE Project__c = :projectId) ';
        }
        query += 'ORDER BY Priority__c ASC NULLS LAST, Name ASC';
        if (String.isBlank(projectId)) {
            query += ' LIMIT 500 ';
        }
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Story__c> getSupportStories() {
        return [
            SELECT Id, Name, Status__c, Priority__c, Story_Type__c,
                   Story_Points__c, Description__c, Business_Description__c, Acceptance_Criteria__c,
                   Assigned_To__c, Assigned_To__r.Name,
                   QA_Assignee__c, QA_Assignee__r.Name,
                   Feature__c, Feature__r.Name,
                   Requirement__c, Requirement__r.Name,
                   Due_Date__c, Is_Global__c, Sprint__c, Completed_Date__c,
                   Origin_Project__c, Origin_Project__r.Name, Blocked__c,
                   (SELECT Project__c, Project__r.Name FROM Story_Projects__r) // <--- NEW SUBQUERY
            FROM Story__c
            // Check the junction object for Technical Support projects
            WHERE Id IN (SELECT Story__c FROM Story_Project__c WHERE Project__r.Project_Type__c = 'Technical Support')
            ORDER BY Priority__c ASC NULLS LAST, Name ASC
            LIMIT 500
        ];
    }

    @AuraEnabled
    public static void updateStoryStatus(Id storyId, String newStatus) {
        update new Story__c(Id = storyId, Status__c = newStatus);
    }

    @AuraEnabled
    public static List<Story_Audit__c> getAuditsByStory(Id storyId, String cacheBuster) {
        return [
            SELECT Id, From_Status__c, To_Status__c,
                   Changed_By__c, Changed_By__r.Name,
                   Changed_At__c, Comment__c
            FROM Story_Audit__c
            WHERE Story__c = :storyId
            ORDER BY Changed_At__c DESC
        ];
    }
    // method for change the Qa assigned from QA board
    @AuraEnabled
    public static void assignQAAndNotify(Id storyId, Id qaUserId) {
        try {
            Story__c s = new Story__c(
                Id = storyId, 
                QA_Assignee__c = qaUserId, 
                Status__c = 'QA Assigned'
            );
            update s;
            Story__c updatedStory = [SELECT Name FROM Story__c WHERE Id = :storyId LIMIT 1];
            
            CustomNotificationType notifType = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = 'Project_Platform_Alert'
                LIMIT 1
            ];
            
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setTitle('New QA Assignment');
            n.setBody('You have been assigned to perform QA on: "' + updatedStory.Name + '"');
            n.setNotificationTypeId(notifType.Id);
            n.setTargetId(storyId); // Clicking notification takes them to the story
            n.send(new Set<String>{ qaUserId });
            
        } catch (Exception e) {
            throw new AuraHandledException('Error assigning QA: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static Id saveStory(String storyJson) {
        Map<String, Object> d = parseJsonMap(storyJson, 'Invalid request data: ');
        Story__c s = new Story__c();
        if (notBlank(d, 'id'))               s.Id                     = (Id)    d.get('id');
        if (notBlank(d, 'name'))             s.Name                   = (String) d.get('name');
        if (d.containsKey('description'))    s.Description__c         = (String) d.get('description');
        if (d.containsKey('businessDescription')) s.Business_Description__c = (String) d.get('businessDescription');
        if (d.containsKey('acceptanceCriteria')) s.Acceptance_Criteria__c = (String) d.get('acceptanceCriteria');
        if (notBlank(d, 'status'))           s.Status__c              = (String) d.get('status');
        if (notBlank(d, 'priority'))         s.Priority__c            = (String) d.get('priority');
        if (notBlank(d, 'storyType'))        s.Story_Type__c          = (String) d.get('storyType');
        if (d.containsKey('storyPoints') && d.get('storyPoints') != null)
            s.Story_Points__c = Decimal.valueOf(String.valueOf(d.get('storyPoints')));
        s.Is_Global__c = d.containsKey('isGlobal') ? (Boolean) d.get('isGlobal') : false;
        if (d.containsKey('sprint'))         s.Sprint__c              = (String) d.get('sprint');
        if (notBlank(d, 'assignedToId'))     s.Assigned_To__c         = (Id)    d.get('assignedToId');
        if (notBlank(d, 'qaAssigneeId'))     s.QA_Assignee__c         = (Id)    d.get('qaAssigneeId');
        if (notBlank(d, 'featureId'))        s.Feature__c             = (Id)    d.get('featureId');
        if (notBlank(d, 'requirement'))    s.Requirement__c         = (Id)    d.get('requirement');
        // REMOVED s.Project__c mapping here!
        if (notBlank(d, 'releaseId'))        s.Release__c             = (Id)    d.get('releaseId');
        if (notBlank(d, 'originProjectId'))  s.Origin_Project__c      = (Id)    d.get('originProjectId');
        if (notBlank(d, 'dueDate'))          s.Due_Date__c            = Date.valueOf((String) d.get('dueDate'));
        if (notBlank(d, 'blocked'))          s.Blocked__c             = (Boolean) d.get('blocked');
        upsert s;

        // NEW: MANY-TO-MANY JUNCTION OBJECT MAPPING
        if (d.containsKey('projectIds')) {
            List<Object> rawIds = (List<Object>) d.get('projectIds');
            List<String> projectIds = new List<String>();
            if (rawIds != null) {
                for (Object obj : rawIds) {
                    projectIds.add((String) obj);
                }
            }

            // 1. Wipe old tag links
            delete [SELECT Id FROM Story_Project__c WHERE Story__c = :s.Id];

            // 2. Insert new tag links
            if (!projectIds.isEmpty()) {
                List<Story_Project__c> newLinks = new List<Story_Project__c>();
                for (String pId : projectIds) {
                    newLinks.add(new Story_Project__c(Story__c = s.Id, Project__c = pId));
                }
                insert newLinks;
            }
        }

        return s.Id;
    }

    // ─── RELEASES ────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<Release__c> getReleasesByProject(Id projectId) {
        return [
            SELECT Id, Name, Version__c, Status__c, Stage__c,
                   Release_Date__c, Go_Live_Date__c, Code_Freeze_Date__c,
                   Release_Notes__c, Release_Manager__c, Project__c
            FROM Release__c
            WHERE Project__c = :projectId
            ORDER BY Release_Date__c DESC NULLS LAST
        ];
    }

    @AuraEnabled
    public static Id saveRelease(String releaseJson) {
        Map<String, Object> d = parseJsonMap(releaseJson, 'Invalid release data: ');
        Release__c rel = new Release__c();
        if (notBlank(d, 'id'))              rel.Id                  = (Id)    d.get('id');
        if (notBlank(d, 'name'))            rel.Name                = (String) d.get('name');
        if (notBlank(d, 'version'))         rel.Version__c          = (String) d.get('version');
        if (notBlank(d, 'status'))          rel.Status__c           = (String) d.get('status');
        if (notBlank(d, 'stage'))           rel.Stage__c            = (String) d.get('stage');
        if (d.containsKey('releaseNotes'))  rel.Release_Notes__c    = (String) d.get('releaseNotes');
        if (d.containsKey('releaseManager'))rel.Release_Manager__c  = (String) d.get('releaseManager');
        if (notBlank(d, 'projectId'))       rel.Project__c          = (Id)    d.get('projectId');
        if (notBlank(d, 'releaseDate'))     rel.Release_Date__c     = Date.valueOf((String) d.get('releaseDate'));
        if (notBlank(d, 'goLiveDate'))      rel.Go_Live_Date__c     = Date.valueOf((String) d.get('goLiveDate'));
        if (notBlank(d, 'codeFreeze'))      rel.Code_Freeze_Date__c = Date.valueOf((String) d.get('codeFreeze'));
        upsert rel;
        return rel.Id;
    }

    // ─── DASHBOARD METRICS ───────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static DashboardMetrics getDashboardMetrics() {
        DashboardMetrics m = new DashboardMetrics();

        for (AggregateResult ar : [SELECT Status__c s, COUNT(Id) cnt FROM Project__c GROUP BY Status__c]) {
            Integer cnt = (Integer) ar.get('cnt');
            m.totalProjects += cnt;
            String s = (String) ar.get('s');
            if ('On going'.equals(s))   m.activeProjects    = cnt;
            if ('On Hold'.equals(s))    m.onHoldProjects    = cnt;
            if ('Delivered'.equals(s))  m.completedProjects = cnt;
            if ('Active'.equals(s))     m.activeProjects   += cnt;
            if ('Completed'.equals(s))  m.completedProjects+= cnt;
        }
        for (AggregateResult ar : [SELECT RAG_Status__c r, COUNT(Id) cnt FROM Project__c WHERE Status__c IN ('On going','Active') GROUP BY RAG_Status__c]) {
            Integer cnt = (Integer) ar.get('cnt');
            String r = (String) ar.get('r');
            if ('Red'.equals(r))   m.redProjects   = cnt;
            if ('Amber'.equals(r)) m.amberProjects = cnt;
            if ('Green'.equals(r)) m.greenProjects = cnt;
        }

        for (AggregateResult ar : [SELECT Status__c s, COUNT(Id) cnt FROM Story__c GROUP BY Status__c]) {
            Integer cnt = (Integer) ar.get('cnt');
            m.totalRequests += cnt;
            String s = (String) ar.get('s');
            if ('Done'.equals(s))        m.requestsDone       = cnt;
            if ('In Progress'.equals(s)) m.requestsInProgress = cnt;
        }
        m.requestsOverdue  = [SELECT COUNT() FROM Story__c WHERE Due_Date__c < TODAY AND Status__c != 'Done'];
        m.totalFeatures    = [SELECT COUNT() FROM Feature__c];
        m.pendingApprovals = [SELECT COUNT() FROM Requirement__c WHERE Status__c IN ('Submitted','Under Review','Draft')];
        m.upcomingReleases = [SELECT COUNT() FROM Release__c WHERE Go_Live_Date__c >= TODAY AND Stage__c != 'Released'];
        m.totalPrograms    = [SELECT COUNT() FROM Program__c];
        m.supportProjects  = [SELECT COUNT() FROM Project__c WHERE Project_Type__c = 'Technical Support'];

        List<ProjectWrapper> recents = new List<ProjectWrapper>();
        for (Project__c p : [
            SELECT Id, Name, Status__c, Stage__c, RAG_Status__c, Methodology__c,
                   Description__c, Owner__c, Owner__r.Name, Owner__r.SmallPhotoUrl,
                   Start_Date__c, Target_Completion_Date__c,
                   Project_Type__c, Priority__c,OwnerId, Owner.Name,
                   Program__c, Program__r.Name, Program__r.Type__c,
                   Technical_Owner__c, Technical_Owner__r.Name,
                   Functional_Owner__c, Functional_Owner__r.Name,
                   Business_Owner__c, Business_Owner__r.Name,
                   Parent_Project__c, Parent_Project__r.Name
            FROM Project__c WHERE Status__c IN ('On going','Active') ORDER BY Priority__c ASC NULLS LAST, LastModifiedDate DESC LIMIT 8
        ]) {
            recents.add(new ProjectWrapper(p));
        }
        m.recentProjects = recents;

        List<ReleaseItem> nextRels = new List<ReleaseItem>();
        for (Release__c rel : [
            SELECT Id, Name, Go_Live_Date__c, Stage__c,
                   Project__r.Name,
                   (SELECT Id, Status__c FROM Release_Stories__r)
            FROM Release__c
            WHERE Go_Live_Date__c >= TODAY AND Stage__c != 'Released'
            ORDER BY Go_Live_Date__c ASC LIMIT 5
        ]) {
            ReleaseItem ri = new ReleaseItem();
            ri.id          = rel.Id;
            ri.name        = rel.Name;
            ri.projectId   = rel.Project__c;
            ri.projectName = rel.Project__r != null ? rel.Project__r.Name : '';
            ri.stage       = rel.Stage__c;
            ri.goLiveDate  = rel.Go_Live_Date__c != null ? String.valueOf(rel.Go_Live_Date__c) : null;
            ri.storyCount  = rel.Release_Stories__r != null ? rel.Release_Stories__r.size() : 0;
            Integer done   = 0;
            if (rel.Release_Stories__r != null) for (Story__c s : rel.Release_Stories__r) if ('Done'.equals(s.Status__c)) done++;
            ri.doneCount   = done;
            nextRels.add(ri);
        }
        m.nextReleases = nextRels;

        return m;
    }

    // ─── USERS ───────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<UserResult> searchUsers(String searchTerm) {
        String term = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        List<UserResult> results = new List<UserResult>();
        for (User u : [
            SELECT Id, Name, Email, SmallPhotoUrl, Title
            FROM User WHERE IsActive = true AND (Name LIKE :term OR Email LIKE :term)
            ORDER BY Name ASC LIMIT 10
        ]) {
            results.add(new UserResult(u));
        }
        return results;
    }

    // ─── ACTIVITIES ──────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=false)
    public static List<Task> getActivitiesForRecord(Id recordId) {
        return [
            SELECT Id, Subject, Description, WhoId, Who.Name,
                   OwnerId, Owner.Name, CreatedDate, ActivityDate
            FROM Task
            WHERE WhatId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static Id addActivity(Id recordId, String body) {
        Task t = new Task(
            WhatId       = recordId,
            Subject      = 'Comment',
            Description  = body,
            Status       = 'Completed',
            Priority     = 'Normal',
            ActivityDate = Date.today()
        );
        insert t;
        return t.Id;
    }

    // ─── HELPERS ─────────────────────────────────────────────────────────────

    private static Map<String, Object> parseJsonMap(String json, String errorPrefix) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(json);
        } catch (Exception ex) {
            throw new AuraHandledException(errorPrefix + ex.getMessage());
        }
    }

    private static Id syncLinkedStoryAfterApproval(Id requirementId) {
        Map<Id, Id> result = RequirementApprovalService.process(new Set<Id>{ requirementId });
        Id storyId = result.get(requirementId);
        if (storyId != null) {
            update new Requirement__c(Id = requirementId, Linked_Story__c = storyId);
        }
        return storyId;
    }

    private static void assertProjectStatusAndStageAlign(String status, String stage) {
        if (status == null || stage == null) {
            return;
        }
        Boolean misaligned =
            ('Delivered'.equals(status) && stage != 'Closure') ||
            ('Completed'.equals(status) && stage != 'Closure') ||
            ('Not Started'.equals(status) && stage == 'Closure') ||
            ('On going'.equals(status) && stage == 'Closure');
        if (misaligned) {
            throw new AuraHandledException(
                'Status and Stage are misaligned. Delivered/Completed projects must be in Closure stage.'
            );
        }
    }

    private static void assertTechnicalSupportHasParent(Map<String, Object> d, String projectType) {
        if ('Technical Support'.equals(projectType) && !notBlank(d, 'parentProjectId')) {
            throw new AuraHandledException(
                'Technical Support projects must reference a Parent Project.'
            );
        }
    }

    private static Boolean notBlank(Map<String, Object> d, String key) {
        return d.containsKey(key) && d.get(key) != null && String.valueOf(d.get(key)).trim() != '';
    }

    // ─── WRAPPERS ────────────────────────────────────────────────────────────

    public class ProgramWrapper {
        @AuraEnabled public String  id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  type;
        @AuraEnabled public String  status;
        @AuraEnabled public String  ragStatus;
        @AuraEnabled public String  priority;
        @AuraEnabled public String  description;
        @AuraEnabled public String  startDate;
        @AuraEnabled public String  endDate;
        @AuraEnabled public String  ownerId;
        @AuraEnabled public String  ownerName;
        @AuraEnabled public String  ownerPhoto;
        @AuraEnabled public List<ProjectWrapper> projects;

        public ProgramWrapper(Program__c prog) {
            this.id          = prog.Id;
            this.name        = prog.Name;
            this.type        = prog.Type__c;
            this.status      = prog.Status__c;
            this.ragStatus   = prog.RAG_Status__c;
            this.priority    = prog.Priority__c;
            this.description = prog.Description__c;
            this.startDate   = prog.Start_Date__c != null ? String.valueOf(prog.Start_Date__c) : null;
            this.endDate     = prog.End_Date__c   != null ? String.valueOf(prog.End_Date__c)   : null;
            this.ownerId     = prog.Program_Owner__c;
            this.ownerName   = prog.Program_Owner__r != null ? prog.Program_Owner__r.Name : null;
            //this.ownerPhoto  = prog.Program_Owner__r != null ? prog.Program_Owner__r.SmallPhotoUrl : null;
            this.projects    = new List<ProjectWrapper>();
            if (prog.Projects__r != null) {
                for (Project__c p : prog.Projects__r) {
                    this.projects.add(new ProjectWrapper(p));
                }
            }
        }
    }

    public class ProjectWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String stage;
        @AuraEnabled public String ragStatus;
        @AuraEnabled public String methodology;
        @AuraEnabled public String description;
        @AuraEnabled public String startDate;
        @AuraEnabled public String targetDate;
        @AuraEnabled public String priority;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String ownerPhoto;
        @AuraEnabled public String projectType;
        @AuraEnabled public String programId;
        @AuraEnabled public String programName;
        @AuraEnabled public String programType;
        @AuraEnabled public String technicalOwnerId;
        @AuraEnabled public String technicalOwnerName;
        @AuraEnabled public String functionalOwnerId;
        @AuraEnabled public String functionalOwnerName;
        @AuraEnabled public String businessOwnerId;
        @AuraEnabled public String businessOwnerName;
        @AuraEnabled public String parentProjectId;
        @AuraEnabled public String parentProjectName;
        @AuraEnabled public Integer storiesTotal = 0;
        @AuraEnabled public Integer storiesDone = 0;
        @AuraEnabled public Integer storiesInProgress = 0;
        @AuraEnabled public Integer storiesOverdue = 0;

        public ProjectWrapper(Project__c p) {
            this.id                  = p.Id;
            this.name                = p.Name;
            this.status              = p.Status__c;
            this.stage               = p.Stage__c;
            this.ragStatus           = p.RAG_Status__c;
            this.methodology         = p.Methodology__c;
            this.description         = p.Description__c;
            this.priority            = p.Priority__c;
            this.startDate           = p.Start_Date__c != null ? String.valueOf(p.Start_Date__c) : null;
            this.targetDate          = p.Target_Completion_Date__c != null ? String.valueOf(p.Target_Completion_Date__c) : null;
            this.ownerId             = p.OwnerId;
            this.ownerName           = p.OwnerId != null ? p.Owner.Name : null;
            //this.ownerPhoto          = p.Owner__r != null ? p.Owner__r.SmallPhotoUrl : null;
            this.projectType         = p.Project_Type__c;
            this.programId           = p.Program__c;
            this.programName         = p.Program__r != null ? p.Program__r.Name : null;
            this.programType         = p.Program__r != null ? p.Program__r.Type__c : null;
            this.technicalOwnerId    = p.Technical_Owner__c;
            this.technicalOwnerName  = p.Technical_Owner__r != null ? p.Technical_Owner__r.Name : null;
            this.functionalOwnerId   = p.Functional_Owner__c;
            this.functionalOwnerName = p.Functional_Owner__r != null ? p.Functional_Owner__r.Name : null;
            this.businessOwnerId     = p.Business_Owner__c;
            this.businessOwnerName   = p.Business_Owner__r != null ? p.Business_Owner__r.Name : null;
            this.parentProjectId     = p.Parent_Project__c;
            this.parentProjectName   = p.Parent_Project__r != null ? p.Parent_Project__r.Name : null;           
             // Calculate Analytics
            if (p.Story_Projects__r != null) {
                this.storiesTotal = p.Story_Projects__r.size();
                for (Story_Project__c sp : p.Story_Projects__r) {
                    if (sp.Story__r.Status__c == 'Done') {
                        this.storiesDone++;
                    }
                    if (sp.Story__r.Status__c == 'In Progress') {
                        this.storiesInProgress++;
                    }
                    if (sp.Story__r.Due_Date__c != null && sp.Story__r.Due_Date__c < Date.today() && sp.Story__r.Status__c != 'Done') {
                        this.storiesOverdue++;
                    }
                }
            }
        }
    }

    public class FeatureDetailWrapper {
        @AuraEnabled public Feature__c           feature;
        @AuraEnabled public List<Requirement__c> requirements;
        @AuraEnabled public List<Story__c>       stories;
        public FeatureDetailWrapper(Feature__c f, List<Requirement__c> r, List<Story__c> s) {
            this.feature      = f;
            this.requirements = r;
            this.stories      = s;
        }
    }

    public class DashboardMetrics {
        @AuraEnabled public Integer              totalProjects     = 0;
        @AuraEnabled public Integer              activeProjects    = 0;
        @AuraEnabled public Integer              onHoldProjects    = 0;
        @AuraEnabled public Integer              completedProjects = 0;
        @AuraEnabled public Integer              redProjects       = 0;
        @AuraEnabled public Integer              amberProjects     = 0;
        @AuraEnabled public Integer              greenProjects     = 0;
        @AuraEnabled public Integer              totalRequests     = 0;
        @AuraEnabled public Integer              requestsDone      = 0;
        @AuraEnabled public Integer              requestsInProgress= 0;
        @AuraEnabled public Integer              requestsOverdue   = 0;
        @AuraEnabled public Integer              pendingApprovals  = 0;
        @AuraEnabled public Integer              upcomingReleases  = 0;
        @AuraEnabled public Integer              totalFeatures     = 0;
        @AuraEnabled public Integer              totalPrograms     = 0;
        @AuraEnabled public Integer              supportProjects   = 0;
        @AuraEnabled public List<ProjectWrapper> recentProjects;
        @AuraEnabled public List<ReleaseItem>    nextReleases;
    }

    public class ReleaseItem {
        @AuraEnabled public String  id;
        @AuraEnabled public String  name;
        @AuraEnabled public String  projectId;
        @AuraEnabled public String  projectName;
        @AuraEnabled public String  stage;
        @AuraEnabled public String  goLiveDate;
        @AuraEnabled public Integer storyCount;
        @AuraEnabled public Integer doneCount;
    }

    public class UserResult {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String photo;
        @AuraEnabled public String title;
        public UserResult(User u) {
            this.id    = u.Id;
            this.name  = u.Name;
            this.email = u.Email;
            this.photo = u.SmallPhotoUrl;
            this.title = u.Title;
        }
    }
}