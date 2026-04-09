//
// DataLoad_S3FileToContent_Schedule
// ---------------------------------
// Schedulable wrapper for `DataLoad_S3FileToContentBatch`.
//
// HOW TO EXECUTE (Execute Anonymous):
//
// 1) Daily at 01:30 (org TZ), run for Contact, limit 500 rows, scope size 100
//    System.schedule(
//        'S3 → Content Loader (Contact) - Daily 01:30',
//        '0 30 1 * * ?',
//        new DataLoad_S3FileToContent_Schedule('Contact', 500, 100)
//    );
//
//
// 3) Hourly at minute 15, for a custom object `My_Object__c`, limit 200, scope 50
//    System.schedule(
//        'S3 → Content Loader (My_Object__c) - Hourly :15',
//        '0 15 * * * ?',
//        new DataLoad_S3FileToContent_Schedule('Contact', 200, 50)
//    );
//
// NOTES:
// - `destination` must be the API name of the target sObject that has a `Legacy_BH_ID__c` field.
// - `limitPerRun` controls how many `Data_Load_Resume__c` rows are pulled each batch run (SOQL LIMIT).
// - `scopeSize` controls the batch chunk size passed to Database.executeBatch (1–2000).
//
//
// DataLoad_S3FileToContent_Schedule
// ---------------------------------
// Schedulable wrapper for `DataLoad_S3FileToContentBatch`.
//
public with sharing class DataLoad_S3FileToContent_Schedule implements Schedulable {
    public String destination     { get; private set; }
    public Integer limitPerRun    { get; private set; }
    public Integer scopeSize      { get; private set; }
    public Boolean orderAscending { get; private set; }

    // Constructor (backward compatible, defaults to ASC)
    public DataLoad_S3FileToContent_Schedule(String destination, Integer limitPerRun, Integer scopeSize) {
        this(destination, limitPerRun, scopeSize, true);
    }

    // New constructor with orderAscending
    public DataLoad_S3FileToContent_Schedule(String destination, Integer limitPerRun, Integer scopeSize, Boolean orderAscending) {
        this.destination     = String.isBlank(destination) ? 'Account' : destination;
        this.limitPerRun     = (limitPerRun == null || limitPerRun <= 0) ? 200 : limitPerRun;
        Integer sz           = (scopeSize == null) ? 0 : scopeSize;
        this.scopeSize       = (sz < 1 || sz > 2000) ? 50 : sz;
        this.orderAscending  = (orderAscending == null) ? true : orderAscending;
    }

    public void execute(SchedulableContext sc) {
        DataLoad_S3FileToContentBatch batch =
            new DataLoad_S3FileToContentBatch(this.destination, this.limitPerRun, this.orderAscending);
        Database.executeBatch(batch, this.scopeSize);
    }
}