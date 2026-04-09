public class JobStatusChangeHandler {
    
    // Initialize Days Open for New Jobs
    public static void updateHoldFields(List<TR1__Job__c> newJobs, Map<Id, TR1__Job__c> oldJobMap) {
        for (TR1__Job__c job : newJobs) {
            TR1__Job__c oldJob = oldJobMap.get(job.Id);
            
            // Check if Status is changed to 'On Hold'
            if (job.TR1__Status__c == 'On Hold' && oldJob.TR1__Status__c != 'On Hold') {
                job.Hold_From_Date__c = Date.today();
            }
            
            // Check if Status changed from 'On Hold' to something else
            if (oldJob.TR1__Status__c == 'On Hold' && job.TR1__Status__c != 'On Hold') {
                if (job.Hold_From_Date__c != null) {
                    Decimal daysOnHold = job.Hold_From_Date__c.daysBetween(Date.today()) + 
                        (oldJob.Days_On_Hold__c != null ? oldJob.Days_On_Hold__c : 0);
                    job.Days_On_Hold__c = daysOnHold;
                    job.Hold_From_Date__c = Null;
                    
                } else {
                    // If Hold_From_Date__c is null, set Days_On_Hold__c to 0
                    job.Days_On_Hold__c = 0;
                }
            }
        }
    }
    
    // Set default values when a job is inserted
    public static void setOpenStatus(List<TR1__Job__c> jobs) {
        for (TR1__Job__c job : jobs) {
            job.Open_Closed__c = true; // Mark job as open
            job.Days_Open_closeddate_US__c = 0;   // Start Days Open from 0
        }
    }
    
    public static void updateOpenClosedFlag(List<TR1__Job__c> newList, Map<Id, TR1__Job__c> oldMap) {
        List<String> closedStatuses = new List<String>{'Closed', 'Declined', 'Archive', 'Placed'};
            
            for (TR1__Job__c job : newList) {
                TR1__Job__c oldJob = oldMap.get(job.Id);
                Boolean statusChanged = job.TR1__Status__c != oldJob.TR1__Status__c;
                Boolean isNowClosed = closedStatuses.contains(job.TR1__Status__c);
                
                if (statusChanged && isNowClosed) {
                    job.Open_Closed__c = false; // Mark job as closed
                    
                    if (oldJob.Open_Closed__c && oldJob.CreatedDate != null) {
        				Integer finalDaysOpen = oldJob.CreatedDate.date().daysBetween(Date.today());
                        job.Days_Open_closeddate_US__c = finalDaysOpen; // Freeze the final days
                    }
                } else if (job.Open_Closed__c == true) {
                    // Optional: reset snapshot if job is reopened (not likely needed unless re-open is supported)
                    job.Days_Open_closeddate_US__c = null;
                }
            }
    }

    

}