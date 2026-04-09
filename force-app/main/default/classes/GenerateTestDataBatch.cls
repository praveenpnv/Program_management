public class GenerateTestDataBatch implements Database.Batchable<sObject> {
    
    // 1. START: Query the projects we want to process
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Grab up to 50 projects
        return Database.getQueryLocator([SELECT Id, Name FROM Project__c LIMIT 50]);
    }

    // 2. EXECUTE: This runs in isolated chunks to protect your SOQL limits
    public void execute(Database.BatchableContext bc, List<Project__c> scope) {
        String[] statuses = new String[]{'Backlog', 'In Progress', 'Developed', 'QA Approved', 'UAT', 'Done'};
        String[] priorities = new String[]{'P1', 'P2', 'P3', 'P4'};
        String[] types = new String[]{'Request', 'Bug Fix', 'Enhancement', 'Task'};

        List<Story__c> storiesToInsert = new List<Story__c>();

        // Generate 40 stories for the projects in this specific batch chunk
        for (Project__c proj : scope) {
            for (Integer i = 1; i <= 40; i++) {
                Integer statIdx = Math.mod(Math.abs(Crypto.getRandomInteger()), statuses.size());
                Integer priIdx  = Math.mod(Math.abs(Crypto.getRandomInteger()), priorities.size());
                Integer typeIdx = Math.mod(Math.abs(Crypto.getRandomInteger()), types.size());
                Integer points  = Math.mod(Math.abs(Crypto.getRandomInteger()), 8) + 1; 
                Integer daysOut = Math.mod(Math.abs(Crypto.getRandomInteger()), 30);    
                
                Story__c s = new Story__c();
                s.Name = 'Auto: ' + proj.Name.left(40) + ' - Req ' + i; 
                s.Status__c = statuses[statIdx];
                s.Priority__c = priorities[priIdx];
                s.Story_Type__c = types[typeIdx];
                s.Description__c = 'This is an automatically generated story for testing UI and load performance.';
                s.Story_Points__c = points;
                s.Due_Date__c = Date.today().addDays(daysOut);
                
                // The 1-to-1 funding source
                s.Origin_Project__c = proj.Id; 
                
                storiesToInsert.add(s);
            }
        }

        // Insert Stories
        if (!storiesToInsert.isEmpty()) {
            insert storiesToInsert;
            
            // Generate and Insert Junction Records
            List<Story_Project__c> junctionsToInsert = new List<Story_Project__c>();
            for (Story__c insertedStory : storiesToInsert) {
                junctionsToInsert.add(new Story_Project__c(
                    Story__c = insertedStory.Id,
                    // FIX: Just read the Project ID right back off the story we just inserted!
                    Project__c = insertedStory.Origin_Project__c 
                ));
            }
            insert junctionsToInsert;
        }
    }

    // 3. FINISH: Runs when all chunks are completely done
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ Auto-generation of Stories and Junction records is complete!');
    }
}