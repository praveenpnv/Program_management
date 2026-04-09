public class DataLoad_NotesToTaskScheduler implements Schedulable {

    // Configurable inputs for the batch
    public Integer maxLimit { get; private set; }
    public String  ownerEmail { get; private set; }

    // Default values used when not provided
    private static final Integer DEFAULT_MAX_LIMIT = 10000;

    // No-arg constructor (handy for Setup → Apex Class scheduler)
    public DataLoad_NotesToTaskScheduler() {
        this(DEFAULT_MAX_LIMIT, null);
    }

    // Convenience constructor (set maxLimit only)
    public DataLoad_NotesToTaskScheduler(Integer maxLimit) {
        this(maxLimit, null);
    }

    // Full constructor
    public DataLoad_NotesToTaskScheduler(Integer maxLimit, String ownerEmail) {
        this.maxLimit   = (maxLimit == null || maxLimit <= 0) ? DEFAULT_MAX_LIMIT : maxLimit;
        this.ownerEmail = ownerEmail;
    }

    public void execute(SchedulableContext sc) {
        // Run the batch with chunk size = 200
        Database.executeBatch(new DataLoad_NotesToTaskBatch(maxLimit, ownerEmail), 200);
    }

    /*
    =============================================================================
    USAGE EXAMPLES (run these from Anonymous Apex / Execute Anonymous)
    -----------------------------------------------------------------------------

    // 1) Schedule daily at 1:00 AM (org timezone)
    //    CRON format: Seconds Minutes Hours Day_of_Month Month Day_of_Week [Year]
    System.schedule(
        'Notes→Task Nightly',
        '0 0 1 * * ?',
        new DataLoad_NotesToTaskScheduler()
    );

    // 2) Schedule hourly with custom inputs (maxLimit & owner email)
    System.schedule(
        'Notes→Task Hourly (owner override)',
        '0 0 * * * ?',
        new DataLoad_NotesToTaskScheduler(5000, 'owner@yourorg.com')
    );

    // 3) Run immediately (no schedule) with batch size 200
    Database.executeBatch(new DataLoad_NotesToTaskBatch(2000, 'owner@yourorg.com'), 200);

    =============================================================================
    */
}