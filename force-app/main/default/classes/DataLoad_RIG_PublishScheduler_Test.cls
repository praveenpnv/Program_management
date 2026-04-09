@IsTest
private class DataLoad_RIG_PublishScheduler_Test {

    @IsTest
    static void testExecuteDirect() {
        Test.startTest();
        // Directly call execute — ensures batch is queued
        DataLoad_RIG_PublishScheduler sched =
            new DataLoad_RIG_PublishScheduler('Account', 100, 10);
        sched.execute(null);
        Test.stopTest();
    }

    @IsTest
    static void testSystemSchedule() {
        Test.startTest();
        // Schedule the job with a CRON expression
        String jobId = System.schedule(
            'Test RIG Scheduler',
            '0 0 12 * * ?', // every day at noon
            new DataLoad_RIG_PublishScheduler('Contact', 50, null)
        );
        Test.stopTest();

        // Ensure a job Id was returned
        System.debug('Scheduled job Id: ' + jobId);
    }

    @IsTest
    static void testScheduleJobHelper() {
        Test.startTest();
        String jobId = DataLoad_RIG_PublishScheduler.scheduleJob(
            'Helper RIG Scheduler',
            '0 15 10 * * ?', // daily at 10:15 AM
            'TR1__Closing_Report__c',
            200,
            null
        );
        Test.stopTest();

        System.debug('Scheduled via helper: ' + jobId);
    }
}