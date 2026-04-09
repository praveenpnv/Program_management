public class DataLoad_RIG_PublishBatch
implements Database.Batchable<SObject>, Database.Stateful {

    private final String entityType; // 'Account' | 'Contact' | 'TR1__Closing_Report__c'
    private final Integer maxLimit;

    public DataLoad_RIG_PublishBatch(String entityType) {
        this(entityType, null);
    }
    public DataLoad_RIG_PublishBatch(String entityType, Integer maxLimitOpt) {
        this.entityType = entityType;
        this.maxLimit   = maxLimitOpt;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String base =
        'SELECT Id, Entity__c, Record_Id__c, Processed__c, Status__c, Error__c ' +
        'FROM Data_Load_RIG__c ' +
        'WHERE Entity__c = :entityType ' +
        '  AND (Processed__c = false OR Processed__c = null) ' +
        '  AND Status__c = null ' +
        'ORDER BY CreatedDate ASC';

        if (maxLimit != null && maxLimit > 0) {
            return Database.getQueryLocator(base + ' LIMIT ' + maxLimit);
        }
        return Database.getQueryLocator(base);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope.isEmpty()) return;

        // Collect record Ids (best-effort cast; no validations)
        Set<Id> targetIds = new Set<Id>();
        for (SObject row : scope) {
            String recId = (String)row.get('Record_Id__c');
            try { targetIds.add((Id)recId); } catch (Exception e) { /* ignore cast issues */ }
        }

        // Query minimal fields per entity type
        Map<Id, SObject> fetched = new Map<Id, SObject>();
        if (!targetIds.isEmpty()) {
            if (entityType == 'Account') {
                for (Account a : [
                    SELECT Id, Name, Randstad_ID__c
                    FROM Account WHERE Id IN :targetIds
                ]) fetched.put(a.Id, a);
            } else if (entityType == 'Contact') {
                for (Contact c : [
                    SELECT Id, FirstName, LastName, Randstad_ID__c
                    FROM Contact WHERE Id IN :targetIds
                ]) fetched.put(c.Id, c);
            } else if (entityType == 'TR1__Closing_Report__c') {
                for (TR1__Closing_Report__c cr : [
                    SELECT Id, Name
                    FROM TR1__Closing_Report__c WHERE Id IN :targetIds
                ]) fetched.put(cr.Id, cr);
            }
        }

        // Build platform events
        List<RD_ChangeEvent__e> toPublish = new List<RD_ChangeEvent__e>();
        String user18 = UserInfo.getUserId();

        for (SObject row : scope) {
            String recIdStr = (String)row.get('Record_Id__c');

            NameRef nr = deriveNameAndRef(entityType, fetched, recIdStr);

            RD_ChangeEvent__e evt = new RD_ChangeEvent__e();
            evt.Change_Type__c   = 'Update';
            evt.Changed_By__c    = user18;
            evt.Entity__c        = (entityType == 'TR1__Closing_Report__c') ? 'Placement' : entityType;
            evt.Record_Id__c     = recIdStr;
            evt.Source__c        = 'Manual';
            evt.Timestamp__c     = System.now();
            evt.Fields__c        = '{"Id": "' + json(recIdStr) + '", "Name": "' + json(nr.nameVal) + '"}';
            evt.Reference_ID__c  = nr.refVal;

            toPublish.add(evt);
        }

        // Publish and update staging
        List<Database.SaveResult> results =
            toPublish.isEmpty() ? new List<Database.SaveResult>() : EventBus.publish(toPublish);

        List<SObject> updates = new List<SObject>();
        for (Integer i = 0; i < scope.size(); i++) {
            SObject row = scope[i];
            SObject upd = (SObject)row.clone(false, true, false, false);
            upd.put('Id', row.get('Id'));

            Boolean ok = (i < results.size()) ? results[i].isSuccess() : false;
            upd.put('Processed__c', ok);
            upd.put('Status__c', ok ? 'Success' : 'Failure');

            if (!ok) {
                String errMsg = 'Unknown publish failure';
                if (i < results.size() && results[i].getErrors() != null && !results[i].getErrors().isEmpty()) {
                    List<String> msgs = new List<String>();
                    for (Database.Error e : results[i].getErrors()) {
                        msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                    }
                    errMsg = String.join(msgs, ' | ');
                }
                upd.put('Error__c', errMsg.left(3000));
            } else {
                upd.put('Error__c', null);
            }
            updates.add(upd);
        }
        if (!updates.isEmpty()) Database.update(updates, false);
    }

    public void finish(Database.BatchableContext bc) { /* no-op */ }

    // ---------- Helper types & methods (split for test coverage) ----------

    @TestVisible
    class NameRef {
        String nameVal;
        String refVal;
        NameRef(String n, String r) {
            nameVal = (n == null) ? '' : n;
            refVal  = r;
        }
    }

    // Wrapper used by batch (kept as-is)
    @TestVisible
    static NameRef deriveNameAndRef(String entityType, Map<Id,SObject> fetched, String recIdStr) {
        String nameVal = '';
        String refVal  = null;

        if (recIdStr != null) {
            try {
                Id recId = (Id)recIdStr;
                if (fetched != null && fetched.containsKey(recId)) {
                    SObject rec = fetched.get(recId);
                    if (entityType == 'Account') {
                        return deriveAccountNameRef(rec);
                    } else if (entityType == 'Contact') {
                        return deriveContactNameRef(rec);
                    } else if (entityType == 'TR1__Closing_Report__c') {
                        return deriveClosingReportNameRef(rec);
                    }
                }
            } catch (Exception e) { /* ignore cast issues */ }
        }
        return new NameRef(nameVal, refVal);
    }

    @TestVisible
    static NameRef deriveAccountNameRef(SObject rec) {
        Account a = (Account)rec;
        String nm = (a != null && a.Name != null) ? a.Name : '';
        String rf = (a != null) ? (String)a.get('Randstad_ID__c') : null;
        return new NameRef(nm, rf);
    }

    @TestVisible
    static NameRef deriveContactNameRef(SObject rec) {
        Contact c = (Contact)rec;
        String f = (c != null && c.FirstName != null) ? c.FirstName.trim() : '';
        String l = (c != null && c.LastName  != null) ? c.LastName.trim()  : '';
        String nm;
        if (f == '' && l == '') nm = '';
        else if (f == '')       nm = l;
        else if (l == '')       nm = f;
        else                    nm = f + ' ' + l;
        String rf = (c != null) ? (String)c.get('Randstad_ID__c') : null;
        return new NameRef(nm, rf);
    }

    @TestVisible
    static NameRef deriveClosingReportNameRef(SObject rec) {
        TR1__Closing_Report__c cr = (TR1__Closing_Report__c)rec;
        String nm = (cr != null && cr.get('Name') != null) ? String.valueOf(cr.get('Name')) : '';
        String rf = nm; // Placement rule: Reference_ID__c = Name
        return new NameRef(nm, rf);
    }

    private String json(String s) {
        if (s == null) return '';
        return s.replace('\\', '\\\\').replace('"', '\\"');
    }
}