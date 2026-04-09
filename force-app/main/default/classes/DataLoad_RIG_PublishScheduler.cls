// Scheduled job that runs the DataLoad_RIG_PublishBatch for a single entity type.
// CRON format for System.schedule is:
//
//   Seconds Minutes Hours Day_of_month Month Day_of_week [optional Year]
//
// Examples:
//   "0 0/15 * * * ?"   → every 15 minutes
//   "0 5 * * * ?"      → at 5 minutes past every hour
//   "0 30 2 * * ?"     → daily at 02:30 AM
// System.schedule(
//    'RIG Batch – Account (q15m)',
//    '0 0/15 * * * ?',
//    new DataLoad_RIG_PublishScheduler('Account', 50, 1000));
//
public class DataLoad_RIG_PublishScheduler implements Schedulable {

    private final String entityType;
    private final Integer scopeSize;
    private final Integer maxLimit;

    // Constructors
    public DataLoad_RIG_PublishScheduler(String entityType) {
        this(entityType, 200, null);
    }
    public DataLoad_RIG_PublishScheduler(String entityType, Integer scopeSize, Integer maxLimit) {
        this.entityType = entityType;
        this.scopeSize  = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        this.maxLimit   = maxLimit;
    }

    // Entry point when scheduled by the platform
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DataLoad_RIG_PublishBatch(entityType, maxLimit), scopeSize);
    }

    // Convenience method to schedule programmatically
    public static String scheduleJob(String jobName, String cron, String entityType,
                                     Integer scopeSize, Integer maxLimit) {
        return System.schedule(jobName, cron,
            new DataLoad_RIG_PublishScheduler(entityType, scopeSize, maxLimit));
    }
}