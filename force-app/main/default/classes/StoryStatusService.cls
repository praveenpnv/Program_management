public with sharing class StoryStatusService {

    public class StatusInput {
        @InvocableVariable(required=true) public Id     storyId;
        @InvocableVariable(required=true) public String fromStatus;
        @InvocableVariable(required=true) public String toStatus;
    }

    @InvocableMethod(label='Handle Story Status Change')
    public static void handleStatusChange(List<StatusInput> inputs) {
        for (StatusInput si : inputs) {
            process(si.storyId, si.fromStatus, si.toStatus);
        }
    }

    public static void process(Id storyId, String fromStatus, String toStatus) {
        if (storyId == null || String.isBlank(toStatus)) return;
        Story__c story = queryStory(storyId);
        if (story == null) return;
        writeAudit(story, fromStatus, toStatus);
        if (toStatus == 'Done') {
            stampCompleted(story);
            advanceReleaseIfComplete(story);
            return;
        }
        CustomNotificationType nt = getNotifType();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        if      (toStatus == 'Developed')    handleDeveloped(story, nt, emails);
        else if (toStatus == 'QA Approved')   handleQaChecked(story, nt, emails);
        else if (toStatus == 'UAT')          handleUat(story, nt, emails);
        else if (toStatus == 'UAT Approved') handleUatApproved(story, nt, emails);
        else if (toStatus == 'Production')   handleProduction(story, nt, emails);
        sendEmails(emails);
    }

    
    private static void writeAudit(Story__c s, String fromStatus, String toStatus) {
        try {
            insert new Story_Audit__c(
                Story__c       = s.Id,
                From_Status__c = String.isBlank(fromStatus) ? 'New' : fromStatus,
                To_Status__c   = toStatus,
                Changed_By__c  = UserInfo.getUserId(),
                Changed_At__c  = System.now()
            );
        } catch (Exception e) {
            System.debug('StoryStatusService.writeAudit: ' + e.getMessage());
        }
    }

    
    private static void stampCompleted(Story__c s) {
        if (s.Completed_Date__c == null)
            update new Story__c(Id = s.Id, Completed_Date__c = System.now());
    }

    private static void advanceReleaseIfComplete(Story__c s) {
        if (s.Release__c == null) return;
        try {
            Integer total = [SELECT COUNT() FROM Story__c WHERE Release__c = :s.Release__c];
            Integer done  = [SELECT COUNT() FROM Story__c WHERE Release__c = :s.Release__c AND Status__c = 'Done'];
            if (total > 0 && total == done)
                update new Release__c(Id = s.Release__c, Stage__c = 'UAT');
        } catch (Exception e) {
            System.debug('StoryStatusService.advanceRelease: ' + e.getMessage());
        }
    }

    
    private static void handleDeveloped(Story__c s, CustomNotificationType nt, List<Messaging.SingleEmailMessage> emails) {
        if (s.QA_Assignee__c == null) return;
        sendBell(nt, new Set<String>{ s.QA_Assignee__c }, 'Story Ready for QA', s.Name, s.Id);
        if (String.isNotBlank(s.QA_Assignee__r.Email)) {
            emails.add(buildEmail(
                new List<String>{ s.QA_Assignee__r.Email },
                '[ProTrack] Story Ready for QA: ' + s.Name,
                buildSimpleHtml(s, 'Developed — Ready for QA',
                    'This story is ready for your QA review.',
                    new List<String[]>{
                        new String[]{ 'Story',   s.Name },
                        new String[]{ 'Project', s.Project__r.Name },
                        new String[]{ 'Feature', s.Feature__r != null ? s.Feature__r.Name : null },
                        new String[]{ 'Dev',     s.Assigned_To__r != null ? s.Assigned_To__r.Name : null },
                        new String[]{ 'Points',  s.Story_Points__c != null ? String.valueOf(s.Story_Points__c) : null }
                    }, '#0EA5E9', 'QA Assigned')
            ));
        }
    }

    private static void handleQaChecked(Story__c s, CustomNotificationType nt, List<Messaging.SingleEmailMessage> emails) {
        Set<String> bellIds = new Set<String>();
        List<String> toEmails = new List<String>();
        if (s.Assigned_To__c != null) { bellIds.add(s.Assigned_To__c); if (String.isNotBlank(s.Assigned_To__r.Email)) toEmails.add(s.Assigned_To__r.Email); }
        addProjectOwner(s.Project__c, bellIds, toEmails);
        if (!bellIds.isEmpty()) sendBell(nt, bellIds, 'QA Approved — Moving to UAT', s.Name, s.Id);
        if (!toEmails.isEmpty()) emails.add(buildEmail(toEmails, '[ProTrack] QA Passed: ' + s.Name,
            buildSimpleHtml(s, 'QA Approved', 'This story has passed QA and is entering UAT.',
                new List<String[]>{
                    new String[]{ 'Story',   s.Name },
                    new String[]{ 'Project', s.Project__r.Name },
                    new String[]{ 'Release', s.Release__r != null ? s.Release__r.Name : null },
                    new String[]{ 'QA By',   s.QA_Assignee__r != null ? s.QA_Assignee__r.Name : null }
                }, '#10B981', 'QA Passed ✓')));
    }

    private static void handleUat(Story__c s, CustomNotificationType nt, List<Messaging.SingleEmailMessage> emails) {
        Set<String> bellIds = new Set<String>();
        List<String> toEmails = new List<String>();
        String reqEmail = s.Requirement__r != null ? s.Requirement__r.Requestor__c : null;
        if (String.isNotBlank(reqEmail)) {
            toEmails.add(reqEmail);
            List<User> u = [SELECT Id FROM User WHERE Email = :reqEmail AND IsActive = true LIMIT 1];
            if (!u.isEmpty()) bellIds.add(u[0].Id);
        }
        addProjectOwner(s.Project__c, bellIds, toEmails);
        if (!bellIds.isEmpty()) sendBell(nt, bellIds, 'Story in UAT', s.Name, s.Id);
        if (!toEmails.isEmpty()) emails.add(buildEmail(toEmails, '[ProTrack] Your Requirement is in UAT: ' + s.Name,
            buildSimpleHtml(s, 'UAT — User Acceptance Testing',
                'The story linked to your requirement is now in UAT. Please review and validate.',
                new List<String[]>{
                    new String[]{ 'Story',   s.Name },
                    new String[]{ 'Project', s.Project__r.Name },
                    new String[]{ 'Release', s.Release__r != null ? s.Release__r.Name : null }
                }, '#8B5CF6', 'In UAT')));
    }

    private static void handleUatApproved(Story__c s, CustomNotificationType nt, List<Messaging.SingleEmailMessage> emails) {
        Set<String> bellIds = new Set<String>();
        List<String> toEmails = new List<String>();
        if (s.Assigned_To__c != null) { bellIds.add(s.Assigned_To__c); if (String.isNotBlank(s.Assigned_To__r.Email)) toEmails.add(s.Assigned_To__r.Email); }
        addProjectOwner(s.Project__c, bellIds, toEmails);
        if (!bellIds.isEmpty()) sendBell(nt, bellIds, 'UAT Approved — Ready for Production', s.Name, s.Id);
        if (!toEmails.isEmpty()) emails.add(buildEmail(toEmails, '[ProTrack] UAT Approved: ' + s.Name,
            buildSimpleHtml(s, 'UAT Approved', 'UAT approved. This story is ready for Production deployment.',
                new List<String[]>{
                    new String[]{ 'Story',   s.Name },
                    new String[]{ 'Project', s.Project__r.Name },
                    new String[]{ 'Release', s.Release__r != null ? s.Release__r.Name : null },
                    new String[]{ 'Version', s.Release__r != null ? s.Release__r.Version__c : null }
                }, '#F59E0B', 'UAT Approved ✓')));
    }

    private static void handleProduction(Story__c s, CustomNotificationType nt, List<Messaging.SingleEmailMessage> emails) {
        List<Story_Audit__c> audits = [
            SELECT From_Status__c, To_Status__c, Changed_By__r.Name, Changed_At__c
            FROM Story_Audit__c WHERE Story__c = :s.Id ORDER BY Changed_At__c ASC
        ];
        Set<String> bellIds = new Set<String>();
        Set<String> toEmails = new Set<String>();
        if (s.Assigned_To__c != null) { bellIds.add(s.Assigned_To__c); if (String.isNotBlank(s.Assigned_To__r.Email)) toEmails.add(s.Assigned_To__r.Email); }
        if (s.QA_Assignee__c != null) { bellIds.add(s.QA_Assignee__c); if (String.isNotBlank(s.QA_Assignee__r.Email)) toEmails.add(s.QA_Assignee__r.Email); }
        String reqEmail = s.Requirement__r != null ? s.Requirement__r.Requestor__c : null;
        if (String.isNotBlank(reqEmail)) {
            toEmails.add(reqEmail);
            List<User> u = [SELECT Id FROM User WHERE Email = :reqEmail AND IsActive = true LIMIT 1];
            if (!u.isEmpty()) bellIds.add(u[0].Id);
        }
        List<String> ownerEmails = new List<String>();
        addProjectOwner(s.Project__c, bellIds, ownerEmails);
        toEmails.addAll(ownerEmails);
        if (!bellIds.isEmpty()) sendBell(nt, bellIds, 'Story Live in Production!', s.Name, s.Id);
        if (!toEmails.isEmpty()) emails.add(buildEmail(new List<String>(toEmails),
            '[ProTrack] Production: ' + s.Name, buildProductionHtml(s, audits)));
    }

    
    private static String buildSimpleHtml(Story__c s, String statusLabel, String intro, List<String[]> rows, String accent, String badge) {
        String h = '<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;background:#F8FAFC;padding:32px">'
            + '<div style="max-width:600px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden">'
            + '<div style="background:#0F172A;padding:24px 32px;border-bottom:3px solid ' + accent + '">'
            + '<span style="background:' + accent + ';color:#fff;font-size:10px;font-weight:700;padding:3px 10px;border-radius:20px">' + escHtml(badge) + '</span>'
            + '<h1 style="margin:10px 0 4px;color:#fff;font-size:17px">' + escHtml(statusLabel) + '</h1>'
            + '<p style="margin:0;color:#94A3B8;font-size:11px">ProTrack · Delivery Governance</p></div>'
            + '<div style="padding:24px 32px">'
            + '<p style="color:#475569;font-size:13px;margin-bottom:18px">' + escHtml(intro) + '</p>'
            + '<table style="width:100%;font-size:13px;border-collapse:collapse">';
        for (String[] r : rows) {
            if (r == null || r.size() < 2 || String.isBlank(r[1])) continue;
            h += '<tr><td style="padding:8px 0;color:#94A3B8;width:100px">' + escHtml(r[0]) + '</td>'
               + '<td style="padding:8px 0;color:#0F172A;font-weight:600">' + escHtml(r[1]) + '</td></tr>';
        }
        h += '</table></div>'
           + '<div style="background:#F8FAFC;padding:12px 32px;border-top:1px solid #E2E8F0">'
           + '<p style="margin:0;color:#94A3B8;font-size:10px">Automated notification from ProTrack</p>'
           + '</div></div></body></html>';
        return h;
    }

    private static String buildProductionHtml(Story__c s, List<Story_Audit__c> audits) {
        String h = '<!DOCTYPE html><html><body style="font-family:Arial,sans-serif;background:#F8FAFC;padding:32px">'
            + '<div style="max-width:620px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden">'
            + '<div style="background:#0F172A;padding:24px 32px;border-bottom:3px solid #10B981">'
            + '<span style="background:#10B981;color:#fff;font-size:10px;font-weight:700;padding:3px 10px;border-radius:20px">PRODUCTION</span>'
            + '<h1 style="margin:10px 0 4px;color:#fff;font-size:18px">Story Live in Production</h1>'
            + '<p style="margin:0;color:#94A3B8;font-size:11px">ProTrack · Delivery Governance</p></div>'
            + '<div style="padding:24px 32px">'
            + '<h2 style="margin:0 0 14px;color:#0F172A;font-size:15px">' + escHtml(s.Name) + '</h2>'
            + '<table style="width:100%;font-size:13px;border-collapse:collapse;margin-bottom:20px">'
            + row('Project', s.Project__r != null ? s.Project__r.Name : null)
            + row('Feature', s.Feature__r != null ? s.Feature__r.Name : null)
            + row('Release', s.Release__r != null ? s.Release__r.Name : null)
            + row('Version', s.Release__r != null ? s.Release__r.Version__c : null)
            + row('Dev',     s.Assigned_To__r != null ? s.Assigned_To__r.Name : null)
            + row('QA',      s.QA_Assignee__r != null ? s.QA_Assignee__r.Name : null)
            + '</table>'
            + '<div style="background:#F8FAFC;border-radius:8px;padding:16px">'
            + '<p style="margin:0 0 12px;font-size:11px;font-weight:700;color:#475569;letter-spacing:0.05em;text-transform:uppercase">Delivery Audit Trail</p>';

        for (Integer i = 0; i < audits.size(); i++) {
            Story_Audit__c a = audits[i];
            Boolean last = (i == audits.size() - 1);
            h += '<div style="display:flex;gap:10px;margin-bottom:' + (last?'0':'10') + 'px">'
               + '<div style="width:9px;height:9px;border-radius:50%;background:' + (last?'#10B981':'#CBD5E1') + ';flex-shrink:0;margin-top:3px"></div>'
               + '<div><span style="font-size:12px;font-weight:600;color:#0F172A">'
               + escHtml(a.From_Status__c) + ' → ' + escHtml(a.To_Status__c) + '</span><br/>'
               + '<span style="font-size:11px;color:#94A3B8">'
               + escHtml(a.Changed_By__r != null ? a.Changed_By__r.Name : 'System')
               + ' · ' + (a.Changed_At__c != null ? a.Changed_At__c.format('dd MMM yyyy HH:mm') : '') + '</span></div></div>';
        }

        h += '</div></div>'
           + '<div style="background:#F8FAFC;padding:12px 32px;border-top:1px solid #E2E8F0">'
           + '<p style="margin:0;color:#94A3B8;font-size:10px">Automated notification from ProTrack</p>'
           + '</div></div></body></html>';
        return h;
    }

    
    private static void addProjectOwner(Id projectId, Set<String> bellIds, List<String> toEmails) {
        if (projectId == null) return;
        try {
            List<Project__c> proj = [SELECT Owner__c, Owner__r.Email FROM Project__c WHERE Id = :projectId LIMIT 1];
            if (!proj.isEmpty() && proj[0].Owner__c != null) {
                bellIds.add(proj[0].Owner__c);
                if (String.isNotBlank(proj[0].Owner__r.Email)) toEmails.add(proj[0].Owner__r.Email);
            }
        } catch (Exception e) { System.debug('addProjectOwner: ' + e.getMessage()); }
    }

    private static CustomNotificationType getNotifType() {
        try { return [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Project_Platform_Alert' LIMIT 1]; }
        catch (Exception e) { return null; }
    }

    private static void sendBell(CustomNotificationType nt, Set<String> ids, String title, String body, Id targetId) {
        if (nt == null || ids.isEmpty()) return;
        try {
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setTitle(title); n.setBody(body);
            n.setNotificationTypeId(nt.Id); n.setTargetId(targetId);
            n.send(ids);
        } catch (Exception e) { System.debug('sendBell: ' + e.getMessage()); }
    }

    private static Messaging.SingleEmailMessage buildEmail(List<String> to, String subject, String html) {
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(to); m.setSubject(subject);
        m.setHtmlBody(html); m.setSaveAsActivity(false);
        return m;
    }

    private static void sendEmails(List<Messaging.SingleEmailMessage> emails) {
        if (emails.isEmpty()) return;
        try { Messaging.sendEmail(emails, false); }
        catch (Exception e) { System.debug('sendEmails: ' + e.getMessage()); }
    }

    private static Story__c queryStory(Id storyId) {
        try {
            return [SELECT Id, Name, Status__c, Story_Type__c, Story_Points__c,
                           Assigned_To__c, Assigned_To__r.Name, Assigned_To__r.Email,
                           QA_Assignee__c, QA_Assignee__r.Name, QA_Assignee__r.Email,
                           Feature__c, Feature__r.Name,
                           Release__c, Release__r.Name, Release__r.Version__c,
                           Requirement__c, Requirement__r.Requestor__c,
                           Project__c, Project__r.Name, Completed_Date__c
                    FROM Story__c WHERE Id = :storyId LIMIT 1];
        } catch (Exception e) { return null; }
    }

    private static String row(String label, String value) {
        if (String.isBlank(value)) return '';
        return '<tr><td style="padding:8px 0;color:#94A3B8;width:100px">' + escHtml(label) + '</td>'
             + '<td style="padding:8px 0;color:#0F172A;font-weight:600">' + escHtml(value) + '</td></tr>';
    }

    private static String escHtml(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;');
    }
}