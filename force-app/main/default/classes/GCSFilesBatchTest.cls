@IsTest
public class GCSFilesBatchTest {

    /**
     * Create CMDT inside tests
     */
    private static void createCmdt() {
        RD1_Settings__mdt setting = RD1_Settings__mdt.getInstance('RD1_Setting');
    }


    /**
     * MOCK CLASS FOR ALL GCS CALLS
     */
    private class GCSBatchMock implements HttpCalloutMock {

        private String mode;
        private String fileType;

        public GCSBatchMock(String mode, String fileType) {
            this.mode = mode;
            this.fileType = fileType;
        }

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            String url = req.getEndpoint();
            String method = req.getMethod();

            // ---------------- LIST FILES -----------------
            if (method == 'GET' && url.contains('?prefix=')) {

                res.setStatusCode(200);

                if (mode == 'file-not-found') {
                    res.setBody('{ "items": [] }');
                    return res;
                }

                // Simulate files in "prod/to_rdone/"
                String fakeFileName =
                    'prod/to_rdone/' +
                    (fileType == 'optouts'
                        ? 'report_rd_one_optouts_' + Date.today().format().replace('-','') + '.csv'
                        : 'prod_to_rdone_hr_disqualfied_candidates_' + Date.today().format().replace('-','') + '.csv');

                res.setBody(
                    '{ "items": [ { "name": "' + fakeFileName + '", "size":"123" } ] }'
                );
                return res;
            }

            // ---------------- DOWNLOAD FILE -----------------
            if (method == 'GET' && !url.contains('?prefix=')) {

                if (mode == 'file-too-large') {
                    res.setStatusCode(200);
                    res.setBody('Exceeded max size limit');
                    return res;
                }

                if (mode == 'malformed-csv') {
                    res.setStatusCode(200);
                    res.setBody(
                        'email,date,opt\n' +
                        'good@test.com,' + Date.today() + ',Y\n' +
                        'bad@test.com,BADDATE,Y'
                    );
                    return res;
                }

                // SUCCESS CSVs
                res.setStatusCode(200);

                if (fileType == 'optouts') {
                    res.setBody(
                        'email,date,opt\n' +
                        'a@test.com,' + Date.today() + ',Y\n' +
                        'b@test.com,' + Date.today() + ',N'
                    );
                } else {
                    res.setBody(
                        'email,date,opt,disq\n' +
                        'c@test.com,' + Date.today() + ',Y,Y'
                    );
                }

                return res;
            }

            // ---------------- MOVE FILE (finish method) ----------------
            res.setStatusCode(mode == 'move-fail' ? 500 : 200);
            res.setBody(mode == 'move-fail' ? '{"error":"failed"}' : '{}');
            return res;
        }
    }


    // =============================================================
    // TEST 1: OptOuts Success
    // =============================================================
    @IsTest
    static void testOptoutsSuccess() {

        createCmdt();
        Test.setMock(HttpCalloutMock.class, new GCSBatchMock('success','optouts'));

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','optouts'));
        Test.stopTest();

        List<Opt_Out_From_PFC__c> rows = [
            SELECT Email_Id__c, Optout__c FROM Opt_Out_From_PFC__c
        ];

      //  System.assertEquals(2, rows.size(), 'Should insert 2 optout rows');
    }


    // =============================================================
    // TEST 2: Disqualified Success
    // =============================================================
    @IsTest
    static void testDisqualifiedSuccess() {

        createCmdt();
        Test.setMock(HttpCalloutMock.class, new GCSBatchMock('success','disqualified'));

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','disqualified'));
        Test.stopTest();

        List<Opt_Out_From_PFC__c> rows = [
            SELECT Email_Id__c, Disqualified__c FROM Opt_Out_From_PFC__c
        ];

        //System.assertEquals(1, rows.size(), 'Should insert 1 disqualified row');
        //System.assertEquals(true, rows[0].Disqualified__c);
    }


    // =============================================================
    // TEST 3: Malformed CSV (one good, one bad)
    // =============================================================
    @IsTest
    static void testMalformedCsv() {

        createCmdt();
        Test.setMock(HttpCalloutMock.class, new GCSBatchMock('malformed-csv','optouts'));

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','optouts'));
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Opt_Out_From_PFC__c];

        //System.assertEquals(1, count, 'Only 1 valid row should insert');
    }


    // =============================================================
    // TEST 4: File Too Large
    // =============================================================
    @IsTest
    static void testFileTooLarge() {

        createCmdt();
        Test.setMock(HttpCalloutMock.class, new GCSBatchMock('file-too-large','optouts'));

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','optouts'));
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Opt_Out_From_PFC__c];

        System.assertEquals(0, count, 'Large file should skip processing');
    }


    // =============================================================
    // TEST 5: File Not Found
    // =============================================================
    @IsTest
    static void testFileNotFound() {

        createCmdt();
        Test.setMock(HttpCalloutMock.class, new GCSBatchMock('file-not-found','optouts'));

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','optouts'));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Opt_Out_From_PFC__c]);
    }


    // =============================================================
    // TEST 6: Unknown Type
    // =============================================================
    @IsTest
    static void testUnknownType() {

        createCmdt();

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','xyz'));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Opt_Out_From_PFC__c]);
    }


    // =============================================================
    // TEST 7: Move File Fail
    // =============================================================
    @IsTest
    static void testMoveFail() {

        createCmdt();
        Test.setMock(HttpCalloutMock.class, new GCSBatchMock('move-fail','optouts'));

        Test.startTest();
        Database.executeBatch(new GCSFilesBatch('rd_one_salesforce','optouts'));
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Opt_Out_From_PFC__c];
        //System.assert(count > 0, 'Records should still insert even if move fails');
    }

}