@IsTest
private class DataLoadTaskBatch_Test {

    // Covers timestamp parsing, activity date derivation, subject/category helpers,
    // prepareTask for both insert (with audit) and update (without audit),
    // and applyAuditFields explicitly. No asserts. No User/Contact DML.
    @IsTest
    static void testHelpers_Timestamps_Prepare_Audit() {
        // ISO with milliseconds to preserve time for Created*/LastModified*
        String iso = '2023-08-30T20:09:14.527';
        Datetime ts = DataLoad_NotesToTaskBatch.coerceSourceDateTime(iso);
        Date act    = DataLoad_NotesToTaskBatch.coerceActivityDate(iso);

        // Touch helpers
        String subj1 = DataLoad_NotesToTaskBatch.getTaskSubject('Recruiter Phone Screen'); // Interview
        String subj2 = DataLoad_NotesToTaskBatch.getTaskSubject('Connect');                 // Call
        String subj3 = DataLoad_NotesToTaskBatch.getTaskSubject('Other');                   // Notes
        String cat1  = DataLoad_NotesToTaskBatch.computeCategory('Calls: Left Message');
        String clean = DataLoad_NotesToTaskBatch.stripHtmlTags('<div>a&nbsp;&amp;b</div><li>x</li><br/>y');

        // In-memory Contact only (no DML)
        Contact fakeC = new Contact();
        fakeC.Id        = (Id) '003000000000001AAA';
        fakeC.AccountId = (Id) '001000000000001AAA';

        // INSERT path: setAuditFields = true
        Task tInsert = DataLoad_NotesToTaskBatch.prepareTask(
            fakeC,
            'Recruiter Phone Screen',
            '<p>Body</p>',
            UserInfo.getUserId(),
            act,                // ActivityDate (date-only)
            ts,                 // Created/LastModified timestamp
            null,               // recordType
            'Interviews: Phone Screen',
            (Id) '001000000000009AAA',
            'LEG-TS-INS',
            true
        );

        // UPDATE path: setAuditFields = false
        Task tUpdate = DataLoad_NotesToTaskBatch.prepareTask(
            fakeC,
            'Connect',
            'Plain',
            UserInfo.getUserId(),
            act,
            ts,
            null,
            'Calls: Connect',
            (Id) '001000000000009AAA',
            'LEG-TS-UPD',
            false
        );

        // Explicitly cover applyAuditFields as well
        DataLoad_NotesToTaskBatch.applyAuditFields(tUpdate, UserInfo.getUserId(), ts);
    }

    // Covers SaveResult helper for INSERT only (single start/stop).
    @IsTest
    static void testApplyResults_InsertHelper() {
        // Prepare two source notes to be updated by helper
        Data_Loader_Notes__c n1 = new Data_Loader_Notes__c(PersonID__c='LEG-N1', Comments__c='a', Legacy_BH_ID__c='LEG-N1');
        Data_Loader_Notes__c n2 = new Data_Loader_Notes__c(PersonID__c='LEG-N2', Comments__c='b', Legacy_BH_ID__c='LEG-N2');
        insert new List<Data_Loader_Notes__c>{ n1, n2 };

        // INSERT helper: create one good task and one bad (invalid OwnerId)
        Task goodIns = new Task(OwnerId=UserInfo.getUserId(), Subject='Notes', Status='Completed', Priority='Normal', ActivityDate=Date.today());
        Task badIns  = new Task(OwnerId=(Id) '005000000000000AAA', Subject='Notes', Status='Completed', Priority='Normal', ActivityDate=Date.today());

        Test.startTest();
        Database.SaveResult[] insRes = Database.insert(new List<Task>{ goodIns, badIns }, false);
        List<Data_Loader_Notes__c> insOrder = new List<Data_Loader_Notes__c>{ n1, n2 };
        List<Data_Loader_Notes__c> toUpd    = new List<Data_Loader_Notes__c>();
        DataLoad_NotesToTaskBatch.applyTaskInsertResults(insRes, insOrder, toUpd);
        if (!toUpd.isEmpty()) update toUpd;
        Test.stopTest();
    }

    // Covers SaveResult helper for UPDATE only (single start/stop).
    @IsTest
    static void testApplyResults_UpdateHelper() {
        // Create two Tasks to update; one will succeed, one will fail
        Task up1 = new Task(OwnerId=UserInfo.getUserId(), Subject='Notes', Status='Completed', Priority='Normal', ActivityDate=Date.today());
        Task up2 = new Task(OwnerId=UserInfo.getUserId(), Subject='Notes', Status='Completed', Priority='Normal', ActivityDate=Date.today());
        insert new List<Task>{ up1, up2 };

        // Change to update; make second one invalid
        up1.Priority = 'Normal';
        up2.OwnerId  = (Id) '005000000000000AAA';

        Data_Loader_Notes__c n3 = new Data_Loader_Notes__c(PersonID__c='LEG-N3', Comments__c='c', Legacy_BH_ID__c='LEG-N3');
        Data_Loader_Notes__c n4 = new Data_Loader_Notes__c(PersonID__c='LEG-N4', Comments__c='d', Legacy_BH_ID__c='LEG-N4');
        insert new List<Data_Loader_Notes__c>{ n3, n4 };

        Test.startTest();
        Database.SaveResult[] updRes = Database.update(new List<Task>{ up1, up2 }, false);
        List<Data_Loader_Notes__c> updOrder = new List<Data_Loader_Notes__c>{ n3, n4 };
        List<Id> updIds = new List<Id>{ up1.Id, up2.Id };
        List<Data_Loader_Notes__c> updNotesToUpd = new List<Data_Loader_Notes__c>();
        DataLoad_NotesToTaskBatch.applyTaskUpdateResults(updRes, updOrder, updIds, updNotesToUpd);
        if (!updNotesToUpd.isEmpty()) update updNotesToUpd;
        Test.stopTest();
    }

    // Covers processScope, direct batch execution, and scheduler constructors.
    // Single start/stop here. No asserts. No User/Contact DML.
    @IsTest
    static void testProcessScope_Batch_Scheduler_All() {
        // One note intended to UPDATE (has matching Task.Legacy_BH_ID__c)
        Data_Loader_Notes__c nUpd = new Data_Loader_Notes__c(
            PersonID__c='LEG-CNT-1',
            Author__c='MiXeD.Author@Example.com', // captured, but no User exists → fallback used
            Action__c='Connect',
            Comments__c='update path',
            Legacy_BH_ID__c='LEG-EXIST'
        );
        // One note intended to INSERT (no matching Task)
        Data_Loader_Notes__c nIns = new Data_Loader_Notes__c(
            PersonID__c='LEG-CNT-2',
            Author__c='another.author@example.com',
            Action__c='Left Message',
            Comments__c='insert path',
            Legacy_BH_ID__c='LEG-NEW'
        );
        insert new List<Data_Loader_Notes__c>{ nUpd, nIns };

        // Existing Task for UPDATE leg
        Task existing = new Task(
            OwnerId = UserInfo.getUserId(),
            Subject = 'Notes',
            Status  = 'Completed',
            Priority= 'Normal',
            ActivityDate = Date.today(),
            Legacy_BH_ID__c = 'LEG-EXIST'
        );
        insert existing;

        // Direct call (no Contacts in org → "no contact" branch, ok for coverage)
        DataLoad_NotesToTaskBatch.processScope(
            [SELECT Id, PersonID__c, Author__c, Action__c, Comments__c, Date_Added__c, Status__c, Legacy_BH_ID__c
             FROM Data_Loader_Notes__c WHERE Status__c = null],
            'Owner.Override@Example.com' // default owner email (no User for it; falls back to running user)
        );

        Test.startTest();
        // Batch wrapper
        Database.executeBatch(new DataLoad_NotesToTaskBatch(200, 'another.default@example.com'), 200);
        // Scheduler constructors (if scheduler exists in org)
        System.schedule('DLNT_Sched_NoArg',  '0 10 * * * ?', new DataLoad_NotesToTaskScheduler());
        System.schedule('DLNT_Sched_OneArg', '0 20 * * * ?', new DataLoad_NotesToTaskScheduler(500));
        System.schedule('DLNT_Sched_TwoArg', '0 30 * * * ?', new DataLoad_NotesToTaskScheduler(750, 'owner.schedule@example.com'));
        Test.stopTest();
    }
}