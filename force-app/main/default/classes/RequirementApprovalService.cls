public with sharing class RequirementApprovalService {

    @InvocableMethod(label='Auto-Create Story from Approved Requirement'
                     description='Creates a Story linked to the approved Requirement if one has not already been created.')
    public static void handleApproval(List<Id> requirementIds) {
        process(new Set<Id>(requirementIds));
    }

    public static Map<Id, Id> process(Set<Id> requirementIds) {
        if (requirementIds == null || requirementIds.isEmpty()) return new Map<Id, Id>();

        List<Requirement__c> reqs = [
            SELECT Id, Name, Status__c, Description__c, Priority__c,
                   Feature__c, Feature__r.Project__c,
                   Project__c, Project__r.Project_Type__c, Project__r.Parent_Project__c,
                   Requestor__c, Auto_Story_Created__c,
                   Assigned_To__c
            FROM Requirement__c
            WHERE Id IN :requirementIds
              AND Status__c = 'Approved'
              AND Auto_Story_Created__c = false
        ];

        if (reqs.isEmpty()) return new Map<Id, Id>();

        List<Story__c> storiesToInsert = new List<Story__c>();
        Map<Id, Requirement__c> reqByReqId = new Map<Id, Requirement__c>();

        for (Requirement__c req : reqs) {
            Id projectId = req.Feature__c != null ? req.Feature__r.Project__c : req.Project__c;

            Id originProjectId = null;
            if ('Technical Support'.equals(req.Project__r?.Project_Type__c)) {
                originProjectId = req.Project__r.Parent_Project__c;
            }

            Story__c story = new Story__c(
                Name              = 'Story: ' + req.Name,
                Description__c    = req.Description__c,
                Priority__c       = req.Priority__c,
                Status__c         = 'Backlog',
                Story_Type__c     = 'Story',
                Requirement__c    = req.Id,
                Feature__c        = req.Feature__c,
                Project__c        = projectId,
                Assigned_To__c    = req.Assigned_To__c,
                Origin_Project__c = originProjectId
            );
            storiesToInsert.add(story);
            reqByReqId.put(req.Id, req);
        }

        Map<Id, Id> reqToStoryMap = new Map<Id, Id>();

        if (!storiesToInsert.isEmpty()) {
            insert storiesToInsert;

            List<Requirement__c> toUpdate = new List<Requirement__c>();
            for (Story__c s : storiesToInsert) {
                Requirement__c req = reqByReqId.get(s.Requirement__c);
                toUpdate.add(new Requirement__c(
                    Id                    = req.Id,
                    Auto_Story_Created__c = true,
                    Status__c             = 'In Progress',
                    Linked_Story__c       = s.Id
                ));
                reqToStoryMap.put(req.Id, s.Id);
            }
            update toUpdate;

            sendNotifications(storiesToInsert, reqByReqId);
        }

        return reqToStoryMap;
    }

    private static void sendNotifications(List<Story__c> stories, Map<Id, Requirement__c> reqMap) {
        try {
            CustomNotificationType notifType = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = 'Project_Platform_Alert'
                LIMIT 1
            ];
            for (Story__c story : stories) {
                Requirement__c req = reqMap.get(story.Requirement__c);
                Set<String> recipientIds = new Set<String>();
                if (story.Assigned_To__c != null) recipientIds.add(story.Assigned_To__c);
                if (req != null && req.Requestor__c != null) {
                    List<User> u = [SELECT Id FROM User WHERE Email = :req.Requestor__c AND IsActive = true LIMIT 1];
                    if (!u.isEmpty()) recipientIds.add(u[0].Id);
                }
                if (recipientIds.isEmpty()) continue;
                Messaging.CustomNotification n = new Messaging.CustomNotification();
                n.setTitle('Story Created from Requirement');
                n.setBody('Story "' + story.Name + '" auto-created from approved requirement.');
                n.setNotificationTypeId(notifType.Id);
                n.setTargetId(story.Id);
                n.send(recipientIds);
            }
        } catch (Exception e) {
            System.debug('sendNotifications error: ' + e.getMessage());
        }
    }
}