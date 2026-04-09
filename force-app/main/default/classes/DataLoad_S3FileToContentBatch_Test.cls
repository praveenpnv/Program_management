@IsTest
private class DataLoad_S3FileToContentBatch_Test {

    // ---- HTTP Mocks ----
    private class S3SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/pdf');
            // tiny fake PDF content
            res.setBodyAsBlob(Blob.valueOf('%PDF-1.4\n%ok\n'));
            return res;
        }
    }
    private class S3ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            res.setBody('Forbidden');
            return res;
        }
    }

    // ---- Helpers ----
    private static Data_Load_Resume__c makeDLR(String srcId, String dest, String fileId, String statusVal) {
        Data_Load_Resume__c dlr = new Data_Load_Resume__c();
        dlr.Source_BH_ID__c = srcId;
        dlr.Destination__c  = dest;
        dlr.File_ID__c      = fileId;
        dlr.S3_File_Url__c  = 'folder/sub/file-' + fileId + '.pdf';
        dlr.Type__c         = 'Resume';
        dlr.Title__c        = 'Resume ' + fileId;
        dlr.Candidate_ID__c = 'LEG-' + fileId; // no Contact created; link step will be skipped
        dlr.RowNum__c       = Integer.valueOf(fileId);
        // Use space (not 'T') so current ParseDate -> DateTime.valueOf works
        dlr.Date_Added__c   = '2024-01-01 10:11:12.123';
        if (statusVal != null) dlr.Status__c = statusVal; // batch now selects only NULL
        return dlr;
    }

    // Minimal destination record so ContentVersion.FirstPublishLocationId is valid.
    private static Account ensureDestinationAccount(String legacyId) {
        Account a = new Account(
            Name = 'Publish Target',
            Legacy_BH_ID__c = legacyId
        );
        insert a;
        return a;
    }

    @IsTest
    static void testBatch_S3Success_PublishesFile_ASC() {
        // Destination object & matching source id
        String legacyKey = 'SRC-SUCCESS-ASC';
        Account a = ensureDestinationAccount(legacyKey);

        // Insert two eligible rows (Status == null)
        insert new List<Data_Load_Resume__c>{
            makeDLR(legacyKey, 'Account', '1001', null),
            makeDLR('UNMATCHED', 'Account', '1002', null) // will fail at "no destination"
        };

        // Drive helper coverage
        String enc = DataLoad_S3FileToContentBatch.encodeS3Path('folder a/b+c/my file.pdf');
        System.debug(enc);

        // Constructor now has (destination, limit, orderAscending)
        DataLoad_S3FileToContentBatch svc = new DataLoad_S3FileToContentBatch('Account', 200, true);
        System.debug(svc.ParseDate('2024-01-01 10:11:12.999'));

        // Mock a successful S3 GET
        Test.setMock(HttpCalloutMock.class, new S3SuccessMock());

        Test.startTest();
        Database.executeBatch(svc, 50);
        Test.stopTest();
        // (No asserts per instruction)
    }

    @IsTest
    static void testBatch_S3Success_PublishesFile_DESC() {
        // Same setup, exercise the DESC order switch using CreatedDate.
        String legacyKey = 'SRC-SUCCESS-DESC';
        Account a = ensureDestinationAccount(legacyKey);

        // Create two records then set their CreatedDate to ensure deterministic order.
        Data_Load_Resume__c r1 = makeDLR(legacyKey, 'Account', '3001', null);
        Data_Load_Resume__c r2 = makeDLR(legacyKey, 'Account', '3002', null);
        insert new List<Data_Load_Resume__c>{ r1, r2 };

        // Make r1 older than r2
        Test.setCreatedDate(r1.Id, DateTime.now().addDays(-2));
        Test.setCreatedDate(r2.Id, DateTime.now().addDays(-1));

        DataLoad_S3FileToContentBatch svc = new DataLoad_S3FileToContentBatch('Account', 200, false);

        Test.setMock(HttpCalloutMock.class, new S3SuccessMock());

        Test.startTest();
        Database.executeBatch(svc, 50);
        Test.stopTest();
        // (No asserts per instruction)
    }

    @IsTest
    static void testBatch_S3Failure_UpdatesDLRStatus() {
        // Destination for one record so we hit the callout; the mock returns 403
        String legacyKey = 'SRC-ERROR';
        Account a = ensureDestinationAccount(legacyKey);

        Data_Load_Resume__c ok = makeDLR(legacyKey, 'Account', '2001', null);  // eligible; will 403
        Data_Load_Resume__c noTarget = makeDLR('NO-TARGET', 'Account', '2002', null); // eligible; no destination branch
        insert new List<Data_Load_Resume__c>{ ok, noTarget };

        // Make their CreatedDates distinct
        Test.setCreatedDate(ok.Id, DateTime.now().addHours(-3));
        Test.setCreatedDate(noTarget.Id, DateTime.now().addHours(-2));

        DataLoad_S3FileToContentBatch svc = new DataLoad_S3FileToContentBatch('Account', 50, true);

        // Mock a failing S3 GET (403)
        Test.setMock(HttpCalloutMock.class, new S3ErrorMock());

        Test.startTest();
        Database.executeBatch(svc, 50);
        Test.stopTest();
        // (No asserts per instruction)
    }
    
    @IsTest
    static void testConstructorDefaults_Schedule() {
        Test.startTest();
        // This assumes you have a scheduler wrapper that internally
        // creates the batch with sensible defaults.
        String jobId = System.schedule(
            'TEST: Defaults',
            '0 0 1 * * ?',
            new DataLoad_S3FileToContent_Schedule(null, -1, 99999)
        );
        Test.stopTest();
    }

    @IsTest
    static void testProcessCalledDirectly_withMock() {
        // Also cover direct process() call with success mock
        String legacyKey = 'SRC-DIRECT';
        Account a = ensureDestinationAccount(legacyKey);

        Data_Load_Resume__c rec = makeDLR(legacyKey, 'Account', '4001', null);
        insert rec;
        Test.setCreatedDate(rec.Id, DateTime.now().addMinutes(-10));

        DataLoad_S3FileToContentBatch svc = new DataLoad_S3FileToContentBatch('Account', 10, true);

        Test.setMock(HttpCalloutMock.class, new S3SuccessMock());

        Test.startTest();
        // Explicitly pull in CreatedDate order to mirror batch behavior
        svc.process([
            SELECT Id, Date_Added__c, Destination__c, File_ID__c, S3_File_Url__c, Source_BH_ID__c,
                   Status__c, Title__c, Type__c, SFDC_ID__c, Candidate_ID__c, CreatedDate
            FROM Data_Load_Resume__c
            WHERE Destination__c = 'Account' AND Status__c = null
            ORDER BY CreatedDate ASC
            LIMIT 10
        ]);
        Test.stopTest();
        // (No asserts per instruction)
    }
}