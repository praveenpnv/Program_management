@IsTest
private class DataLoad_RIG_PublishBatch_Test {

    private static Data_Load_RIG__c stage(String entityType, String recId){
        return new Data_Load_RIG__c(Entity__c = entityType, Record_Id__c = recId);
    }

    @IsTest
    static void cover_split_helpers_only() {
        // In-memory Account (do NOT set Randstad_ID__c)
        Account a = new Account();
        a.Name = 'Acme';
        DataLoad_RIG_PublishBatch.NameRef a1 =
            DataLoad_RIG_PublishBatch.deriveAccountNameRef(a);

        // In-memory Contact (do NOT set Randstad_ID__c)
        Contact c = new Contact();
        c.FirstName = 'Ana';
        c.LastName  = 'Silva';
        DataLoad_RIG_PublishBatch.NameRef a2 =
            DataLoad_RIG_PublishBatch.deriveContactNameRef(c);

        // In-memory Closing Report (do NOT set Name — it can be auto-number and non-editable)
        TR1__Closing_Report__c cr = new TR1__Closing_Report__c();
        DataLoad_RIG_PublishBatch.NameRef a3 =
            DataLoad_RIG_PublishBatch.deriveClosingReportNameRef(cr);
    }

    @IsTest
    static void run_batch_account_with_limit() {
        insert new List<Data_Load_RIG__c>{
            stage('Account', '001000000000010AAA'),
            stage('Account', 'NOT_AN_ID')
        };
        Test.startTest();
        Database.executeBatch(new DataLoad_RIG_PublishBatch('Account', 50), 200);
        Test.stopTest();
    }

    @IsTest
    static void run_batch_account_no_limit() {
        insert stage('Account', '001000000000011AAA');
        Test.startTest();
        Database.executeBatch(new DataLoad_RIG_PublishBatch('Account'), 200);
        Test.stopTest();
    }

    @IsTest
    static void run_batch_contact_paths() {
        insert new List<Data_Load_RIG__c>{
            stage('Contact', '003000000000003AAA'),
            stage('Contact', 'random-text')
        };
        Test.startTest();
        Database.executeBatch(new DataLoad_RIG_PublishBatch('Contact'), 200);
        Test.stopTest();
    }

    @IsTest
    static void run_batch_closing_report_paths() {
        insert new List<Data_Load_RIG__c>{
            stage('TR1__Closing_Report__c', 'a1B000000000002AAA'),
            stage('TR1__Closing_Report__c', 'not-an-id')
        };
        Test.startTest();
        Database.executeBatch(new DataLoad_RIG_PublishBatch('TR1__Closing_Report__c'), 200);
        Test.stopTest();
    }

    @IsTest
    static void run_empty_execute() {
        Test.startTest();
        Database.executeBatch(new DataLoad_RIG_PublishBatch('Account'), 200);
        Test.stopTest();
    }
}