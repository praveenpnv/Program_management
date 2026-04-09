/**
 * This batch job deletes all existing Opt_Out_From_PFC__c records.
 * In its finish method, it chains the GCSFilesBatch to process the new file.
 *
 * This is now the main class you execute to start the full process.
 */
public class DeleteOptOutsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private String bucketName;
    private String fileType;
   // private Date processingDate;
    private Integer deletedCount = 0;

    /**
     * Constructor accepts the parameters needed for the *next* batch (GCSFilesBatch)
     */
    public DeleteOptOutsBatch(String bucketName, String fileType) {
        this.bucketName = bucketName;
        this.fileType = fileType;
       // this.processingDate = processingDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query for all records to be deleted.
        // This handles 100,000+ records.
        return Database.getQueryLocator([SELECT Id FROM Opt_Out_From_PFC__c]);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Delete records in chunks (e.g., 200 at a time)
        if (!scope.isEmpty()) {
            try {
                Database.delete(scope, false);
                deletedCount += scope.size();
            } catch (Exception e) {
                System.debug('⚠️ Error deleting Opt_Out_From_PFC__c chunk: ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ Deletion complete. Deleted ' + deletedCount + ' old Opt_Out_From_PFC__c records.');
        
        // Now that deletion is done, start the file processing batch.
        // Only start if the type is 'optouts'. 
        // If it's another type, we just run GCSFilesBatch directly.
        // This assumes this *chain* is only for optouts.
        if (this.fileType == 'optouts') {
             System.debug('ℹ️ Chaining GCSFilesBatch for file processing...');
             Database.executeBatch(new GCSFilesBatch(bucketName, fileType), 200);
        }
    }
}