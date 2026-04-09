public with sharing class StoryCompletionService {

    public class StoryInput {
        @InvocableVariable(required=true)
        public Id storyId;
    }

    @InvocableMethod(label='Handle Story Completion')
    public static void handleCompletion(List<StoryInput> inputs) {
        Set<Id> ids = new Set<Id>();
        for (StoryInput si : inputs) ids.add(si.storyId);
        process(ids);
    }

    public static void process(Set<Id> storyIds) {
        if (storyIds == null || storyIds.isEmpty()) return;

        List<Story__c> stories = [
            SELECT Id, Name, Status__c, Story_Type__c, Story_Points__c,
                   Description__c, Sprint__c, Is_Global__c,
                   Assigned_To__c, Assigned_To__r.Name, Assigned_To__r.Email,
                   Feature__c, Feature__r.Name,
                   Release__c, Release__r.Name, Release__r.Version__c,
                   Requirement__c, Requirement__r.Requestor__c,
                   Project__c, Project__r.Name,
                   Completed_Date__c
            FROM Story__c
            WHERE Id IN :storyIds AND Status__c = 'Done'
        ];

        if (stories.isEmpty()) return;

        List<Story__c> toUpdate = new List<Story__c>();
        for (Story__c s : stories) {
            if (s.Completed_Date__c == null)
                toUpdate.add(new Story__c(Id = s.Id, Completed_Date__c = System.now()));
        }
        if (!toUpdate.isEmpty()) update toUpdate;

        CustomNotificationType notifType = null;
        try {
            notifType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Project_Platform_Alert' LIMIT 1];
        } catch (Exception e) {
            System.debug('StoryCompletionService: CustomNotificationType not found');
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Story__c storyDesc : stories) {
            String requestorEmail = storyDesc.Requirement__c != null ? storyDesc.Requirement__r.Requestor__c : null;

            if (String.isNotBlank(requestorEmail)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ requestorEmail });
                email.setSubject('[Project Platform] Story Done: ' + storyDesc.Name);
                email.setHtmlBody(buildEmailHtml(storyDesc));
                email.setSaveAsActivity(false);
                emails.add(email);
            }

            if (notifType != null) {
                try {
                    Set<String> recipients = new Set<String>();
                    if (storyDesc.Assigned_To__c != null) recipients.add(storyDesc.Assigned_To__c);
                    if (String.isNotBlank(requestorEmail)) {
                        List<User> u = [SELECT Id FROM User WHERE Email = :requestorEmail AND IsActive = true LIMIT 1];
                        if (!u.isEmpty()) recipients.add(u[0].Id);
                    }
                    if (!recipients.isEmpty()) {
                        Messaging.CustomNotification notif = new Messaging.CustomNotification();
                        notif.setTitle('Story Completed');
                        notif.setBody(storyDesc.Name);
                        notif.setNotificationTypeId(notifType.Id);
                        notif.setTargetId(storyDesc.Id);
                        notif.send(recipients);
                    }
                } catch (Exception e) {
                    System.debug('StoryCompletionService notif error: ' + e.getMessage());
                }
            }
        }

        if (!emails.isEmpty()) {
            try { Messaging.sendEmail(emails, false); }
            catch (Exception e) { System.debug('email error: ' + e.getMessage()); }
        }
    }

    private static String buildEmailHtml(Story__c s) {
        return '<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;background:#F8FAFC;padding:32px">'
            + '<div style="max-width:600px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden">'
            + '<div style="background:#0F172A;padding:28px 32px">'
            + '<h1 style="margin:0;color:#fff;font-size:20px">Story Completed</h1>'
            + '<p style="margin:6px 0 0;color:#94A3B8;font-size:13px">Project Platform</p></div>'
            + '<div style="padding:32px"><h2 style="color:#0F172A">' + escHtml(s.Name) + '</h2>'
            + '<table style="width:100%;font-size:14px">'
            + row('Type',        s.Story_Type__c)
            + row('Points',      s.Story_Points__c != null ? String.valueOf(s.Story_Points__c) : '-')
            + row('Feature',     s.Feature__c != null ? s.Feature__r.Name : '-')
            + row('Project',     s.Project__c != null ? s.Project__r.Name : '-')
            + row('Release',     s.Release__c != null ? s.Release__r.Name : '-')
            + row('Assigned To', s.Assigned_To__c != null ? s.Assigned_To__r.Name : '-')
            + '</table></div></div></body></html>';
    }

    private static String row(String label, String value) {
        return '<tr><td style="padding:8px 0;color:#64748B;width:130px">' + escHtml(label) + '</td>'
             + '<td style="padding:8px 0;color:#0F172A;font-weight:500">' + escHtml(value != null ? value : '-') + '</td></tr>';
    }
    private static String escHtml(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;');
    }
}