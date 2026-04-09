public class DataLoad_NotesToTaskBatch implements Database.Batchable<SObject> {

    // --- Config ---
    public static final String DEFAULT_OWNER_EMAIL = 'house.rd@randstaddigital.com';

    // Inputs
    Integer maxLimit;
    String ownerEmailParam; // optional

    // Constructors
    public DataLoad_NotesToTaskBatch(Integer maxLimit) { this(maxLimit, null); }
    public DataLoad_NotesToTaskBatch(Integer maxLimit, String ownerEmail) {
        this.maxLimit = maxLimit;
        this.ownerEmailParam = ownerEmail;
    }

    // Batchable: start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   Action__c,
                   Comments__c,
                   PersonID__c,
                   Author__c,
                   Date_Added__c,
                   Status__c,
                   Legacy_BH_ID__c
            FROM Data_Loader_Notes__c
            WHERE Status__c = null
            LIMIT :this.maxLimit
        ]);
    }

    // Batchable: execute
    public void execute(Database.BatchableContext bc, List<Data_Loader_Notes__c> scope) {
        processScope(scope, this.ownerEmailParam);
    }

    // Batchable: finish
    public void finish(Database.BatchableContext bc) {}

    // ======================================================
    // Main chunk logic (public for test coverage)
    // ======================================================
    public static void processScope(List<Data_Loader_Notes__c> scope, String ownerEmailParam) {
        // Collect Contact legacy ids, Note legacy ids, and ALL emails we care about (authors + default)
        Set<String> contactLegacyIds = new Set<String>();
        Set<String> noteLegacyIds    = new Set<String>();
        Set<String> emailsToQuery    = new Set<String>();

        for (Data_Loader_Notes__c note : scope) {
            if (!String.isBlank(note.PersonID__c))     contactLegacyIds.add(String.valueOf(note.PersonID__c));
            if (!String.isBlank(note.Legacy_BH_ID__c)) noteLegacyIds.add(note.Legacy_BH_ID__c);
            if (!String.isBlank(note.Author__c))       emailsToQuery.add(note.Author__c.trim());
        }

        // Include the default owner email (param or global default)
        String effectiveDefaultEmail = String.isBlank(ownerEmailParam)
            ? DEFAULT_OWNER_EMAIL
            : ownerEmailParam.trim();
        if (!String.isBlank(effectiveDefaultEmail)) emailsToQuery.add(effectiveDefaultEmail);

        // Build case-insensitive user map ONCE; compute defaultOwnerId from it
        Map<String, Id> userByEmailLc = buildUserMapByEmail(emailsToQuery);
        Id defaultOwnerId = userByEmailLc.get(canonEmail(effectiveDefaultEmail));

        // One-time lookup for Candidate Pool Account
        Id candidatePoolAccountId = getCandidatePoolAccountIdOnce();

        // Contacts keyed by Legacy_BH_ID__c
        Map<String, Contact> contactByLegacy = new Map<String, Contact>();
        if (!contactLegacyIds.isEmpty()) {
            for (Contact c : [
                SELECT Id, Legacy_BH_ID__c, AccountId
                FROM Contact
                WHERE Legacy_BH_ID__c IN :contactLegacyIds
            ]) {
                contactByLegacy.put(c.Legacy_BH_ID__c, c);
            }
        }

        // Existing Tasks by Legacy_BH_ID__c (for update vs insert decision)
        Map<String, Task> existingTaskByLegacy = new Map<String, Task>();
        if (!noteLegacyIds.isEmpty()) {
            for (Task t : [
                SELECT Id, Legacy_BH_ID__c
                FROM Task
                WHERE Legacy_BH_ID__c IN :noteLegacyIds
            ]) {
                existingTaskByLegacy.put(t.Legacy_BH_ID__c, t);
            }
        }

        Map<String, String> actionToFullSubAction = buildActionToFullSubActionMap();
        Id powerNoteRecordTypeId = getTaskRecordTypeIdByName('Power Notes');

        // Buckets
        List<Task> tasksToInsert = new List<Task>();
        List<Data_Loader_Notes__c> notesForInsert = new List<Data_Loader_Notes__c>();

        List<Task> tasksToUpdate = new List<Task>();
        List<Data_Loader_Notes__c> notesForUpdate = new List<Data_Loader_Notes__c>();
        List<Id> updateTaskIdsInSameOrder = new List<Id>();

        List<Data_Loader_Notes__c> notesToUpdate = new List<Data_Loader_Notes__c>();

        // Build Tasks
        for (Data_Loader_Notes__c note : scope) {
            try {
                Contact c = contactByLegacy.get(String.valueOf(note.PersonID__c));
                if (c == null) {
                    note.Exists__c = false;
                    note.Status__c = 'Failure';
                    note.Error__c  = 'No Contact found for PersonID: ' + note.PersonID__c;
                    notesToUpdate.add(note);
                    continue;
                }

                note.Exists__c = true;

                String   fullSubAction = actionToFullSubAction.get(note.Action__c);
                Datetime srcTs         = coerceSourceDateTime(note.Date_Added__c); // preserves time
                Date     actDate       = (srcTs == null) ? Date.today() : srcTs.date(); // date-only for ActivityDate

                // Owner selection per note:
                // 1) author email user if found (case-insensitive)
                // 2) else default owner (param/default email)
                // 3) else running user
                String authorLc = canonEmail(note.Author__c);
                Id ownerUserId = (authorLc != null) ? userByEmailLc.get(authorLc) : null;
                if (ownerUserId == null) ownerUserId = defaultOwnerId;
                if (ownerUserId == null) ownerUserId = UserInfo.getUserId();

                // Decide: insert vs update by Legacy_BH_ID__c
                Task existing = (String.isBlank(note.Legacy_BH_ID__c) ? null : existingTaskByLegacy.get(note.Legacy_BH_ID__c));
                Boolean setAudit = (existing == null); // insert => set audit fields; update => skip

                Task t = prepareTask(
                    c,
                    note.Action__c,
                    note.Comments__c,
                    ownerUserId,
                    actDate,                 // ActivityDate (date-only)
                    srcTs,                   // Audit fields timestamp
                    powerNoteRecordTypeId,
                    fullSubAction,
                    candidatePoolAccountId,
                    note.Legacy_BH_ID__c,
                    setAudit
                );

                if (existing == null) {
                    // INSERT
                    tasksToInsert.add(t);
                    notesForInsert.add(note);
                } else {
                    // UPDATE
                    t.Id = existing.Id;
                    tasksToUpdate.add(t);
                    notesForUpdate.add(note);
                    updateTaskIdsInSameOrder.add(existing.Id);
                }

            } catch (Exception ex) {
                note.Status__c  = 'Failure';
                note.Exists__c  = false;
                note.Error__c   = ex.getMessage().substring(0, Math.min(255, ex.getMessage().length()));
                notesToUpdate.add(note);
            }
        }

        // INSERT DML
        if (!tasksToInsert.isEmpty()) {
            Database.SaveResult[] insResults = Database.insert(tasksToInsert, true);
            applyTaskInsertResults(insResults, notesForInsert, notesToUpdate);
        }

        // UPDATE DML
        if (!tasksToUpdate.isEmpty()) {
            Database.SaveResult[] updResults = Database.update(tasksToUpdate, false);
            applyTaskUpdateResults(updResults, notesForUpdate, updateTaskIdsInSameOrder, notesToUpdate);
        }

        // Update back the source notes
        if (!notesToUpdate.isEmpty()) {
            update notesToUpdate;
        }
    }

    // ======================================================
    // Public helpers (explicitly coverable)
    // ======================================================

    // Subject mapping: Interview > Call > Notes
    // "Recruiter Phone Screen"/any "Interview" → Interview
    // "Appointment/Connect/Left Message"/any "Call" → Call
    public static String getTaskSubject(String action) {
        if (String.isBlank(action)) return 'Notes';
        String a = action.toLowerCase();
        if (a.contains('recruiter phone screen') || a.contains('interview')) return 'Interview';
        if (a.contains('appointment') || a.contains('connect') || a.contains('left message') || a.contains('call'))
            return 'Call';
        return 'Notes';
    }

    // Compute category from "Category: Action"
    public static String computeCategory(String fullSubAction) {
        if (String.isBlank(fullSubAction) || !fullSubAction.contains(':')) return null;
        return fullSubAction.split(':', 2)[0].trim();
    }

    // Parse to DateTime while preserving time; accepts ISO-like strings (e.g., 2023-08-30T20:09:14.527Z)
    public static Datetime coerceSourceDateTime(Object val) {
        if (val == null) return System.now();
        try {
            if (val instanceof Datetime) return (Datetime)val;
            if (val instanceof Date)     return Datetime.newInstance((Date)val, Time.newInstance(0,0,0,0));
            String s = String.valueOf(val).trim();
            s = s.replace('T', ' ');
            Integer dot = s.indexOf('.');
            if (dot > 0) s = s.substring(0, dot); // drop fractional seconds
            if (s.endsWith('Z')) s = s.substring(0, s.length()-1);
            Integer plus = s.lastIndexOf('+');
            Integer minus = s.lastIndexOf('-');
            Integer tzIdx = (plus > 10) ? plus : ((minus > 10) ? minus : -1); // ignore date dashes
            if (tzIdx > 10) s = s.substring(0, tzIdx);
            if (s.length() == 10) s += ' 00:00:00';
            return Datetime.valueOf(s);
        } catch (Exception e) {
            return System.now();
        }
    }

    // Date-only for ActivityDate
    public static Date coerceActivityDate(Object val) {
        try {
            if (val instanceof Date)     return (Date)val;
            if (val instanceof Datetime) return ((Datetime)val).date();
            Datetime dt = coerceSourceDateTime(val);
            return dt.date();
        } catch (Exception e) {
            return Date.today();
        }
    }

    // Build a Task instance (no DML)
    // setAuditFields = true for INSERT; false for UPDATE (skip overriding audit fields)
    public static Task prepareTask(
        Contact contact,
        String action,
        String comments,
        Id ownerId,
        Date activityDate,           // date-only for Task.ActivityDate
        Datetime createdTimestamp,   // full timestamp for audit fields
        Id recordTypeId,
        String fullSubAction,
        Id candidatePoolAccountId,
        String legacyBHId,
        Boolean setAuditFields
    ) {
        String  category = computeCategory(fullSubAction);
        Date    actDate  = (activityDate == null) ? Date.today() : activityDate;
        Id      effOwner = (ownerId == null ? UserInfo.getUserId() : ownerId);
        Datetime createdDt = (createdTimestamp == null)
            ? Datetime.newInstance(actDate, Time.newInstance(0,0,0,0))
            : createdTimestamp;

        Task t = new Task(
            OwnerId                     = effOwner,
            WhoId                       = (contact == null ? null : contact.Id),
            Subject                     = getTaskSubject(action),
            Description                 = stripHtmlTags(comments),
            ActivityDate                = actDate, // date-only
            Status                      = 'Completed',
            Priority                    = 'Normal',
            Sub_Action__c               = fullSubAction,
            Action_Power_Notes__c       = category,
            RecordTypeId                = recordTypeId,
            Legacy_BH_ID__c             = legacyBHId,
            TR1__Location__c            = (contact != null && contact.Id != null)
                                          ? '{"recordId":"' + contact.Id + '","source":"Record"}'
                                          : null,
            TR1__Original_Power_Note__c = true
        );

        if (Boolean.valueOf(setAuditFields)) {
            applyAuditFields(t, effOwner, createdDt); // Created*/LastModified* keep timestamp
        }
        // else: update path — do not set audit fields

        // WhatId unless Contact's Account == Candidate Pool Account
        if (contact != null && contact.AccountId != null
            && !(candidatePoolAccountId != null && contact.AccountId == candidatePoolAccountId)) {
            t.Account__c = contact.AccountId;
        }
        return t;
    }

    // Applies audit fields (used only for INSERT path)
    public static void applyAuditFields(Task t, Id ownerId, Datetime createdDt) {
        Id effOwner = (ownerId == null ? UserInfo.getUserId() : ownerId);
        t.CreatedById      = effOwner;
        t.CreatedDate      = createdDt;
        t.LastModifiedById = effOwner;
        t.LastModifiedDate = createdDt;
    }

    // Handle insert results
    public static void applyTaskInsertResults(
        Database.SaveResult[] results,
        List<Data_Loader_Notes__c> notesInSameOrder,
        List<Data_Loader_Notes__c> notesToUpdate
    ) {
        if (results == null) return;
        for (Integer i = 0; i < results.size(); i++) {
            Data_Loader_Notes__c note = (i < notesInSameOrder.size()) ? notesInSameOrder[i] : null;
            if (note == null) continue;

            if (results[i].isSuccess()) {
                note.SFDC_ID__c = results[i].getId();
                note.Status__c  = 'Success';
                note.Error__c   = null;
            } else {
                note.Status__c  = 'Failure';
                note.Error__c   = results[i].getErrors().isEmpty()
                                  ? 'Unknown DML error'
                                  : results[i].getErrors()[0].getMessage();
            }
            notesToUpdate.add(note);
        }
    }

    // Handle update results (SaveResult.getId() may be null on update; we pass known Ids)
    public static void applyTaskUpdateResults(
        Database.SaveResult[] results,
        List<Data_Loader_Notes__c> notesInSameOrder,
        List<Id> taskIdsInSameOrder,
        List<Data_Loader_Notes__c> notesToUpdate
    ) {
        if (results == null) return;
        for (Integer i = 0; i < results.size(); i++) {
            Data_Loader_Notes__c note = (i < notesInSameOrder.size()) ? notesInSameOrder[i] : null;
            if (note == null) continue;

            if (results[i].isSuccess()) {
                if (i < taskIdsInSameOrder.size()) note.SFDC_ID__c = taskIdsInSameOrder[i];
                note.Status__c  = 'Success';
                note.Error__c   = null;
            } else {
                note.Status__c  = 'Failure';
                note.Error__c   = results[i].getErrors().isEmpty()
                                  ? 'Unknown DML error'
                                  : results[i].getErrors()[0].getMessage();
            }
            notesToUpdate.add(note);
        }
    }

    // Single lookup for "Candidate Pool Account"
    public static Id getCandidatePoolAccountIdOnce() {
        List<Account> pool = [SELECT Id FROM Account WHERE Name = 'Candidate Pool Account' LIMIT 1];
        return pool.isEmpty() ? null : pool[0].Id;
    }

    // Strip HTML and normalize entities for Task.Description
    public static String stripHtmlTags(String htmlText) {
        if (String.isBlank(htmlText)) return null;
        String clean = htmlText;
        clean = clean.replaceAll('(?i)<br\\s*/?>', '\n');
        clean = clean.replaceAll('(?i)<li\\s*>', '\n');

        clean = clean.replaceAll('&nbsp;', ' ');
        clean = clean.replaceAll('&amp;', '&');
        clean = clean.replaceAll('&lt;', '<');
        clean = clean.replaceAll('&gt;', '>');
        clean = clean.replaceAll('&quot;', '"');
        clean = clean.replaceAll('&#39;', '\'');

        clean = clean.replaceAll('<[^>]*>', '');
        clean = clean.trim();
        return clean.abbreviate(32000);
    }

    // =========================
    // Private helpers
    // =========================

    // Canonicalize emails (for map keys/lookups)
    private static String canonEmail(String e) {
        return String.isBlank(e) ? null : e.trim().toLowerCase();
    }

    // Prefer ACTIVE, then most recent login, then newest CreatedDate.
    // Keys are LOWERCASE emails for case-insensitive lookups.
    private static Map<String, Id> buildUserMapByEmail(Set<String> emails) {
        Map<String, Id> byEmailLc = new Map<String, Id>();
        if (emails == null || emails.isEmpty()) return byEmailLc;

        for (User u : [
            SELECT Id, Email, IsActive, LastLoginDate, CreatedDate
            FROM User
            WHERE Email IN :emails
            ORDER BY IsActive DESC, LastLoginDate DESC NULLS LAST, CreatedDate DESC
        ]) {
            String key = canonEmail(u.Email);
            if (key != null && !byEmailLc.containsKey(key)) {
                byEmailLc.put(key, u.Id);
            }
        }
        return byEmailLc;
    }

    private static Map<String, String> buildActionToFullSubActionMap() {
        Map<String, String> mapActionToFull = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Task.Sub_Action__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            String fullVal = entry.getValue();
            if (String.isNotBlank(fullVal) && fullVal.contains(':')) {
                List<String> parts = fullVal.split(':', 2);
                String action = parts[1].trim();
                mapActionToFull.put(action, fullVal);
            }
        }
        return mapActionToFull;
    }

    private static Id getTaskRecordTypeIdByName(String recordTypeName) {
        Map<String, Schema.RecordTypeInfo> rtMap = Task.SObjectType.getDescribe().getRecordTypeInfosByName();
        return rtMap.containsKey(recordTypeName) ? rtMap.get(recordTypeName).getRecordTypeId() : null;
    }
}