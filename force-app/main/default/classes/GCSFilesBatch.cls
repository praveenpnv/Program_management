public class GCSFilesBatch implements Database.Batchable<String>, Database.AllowsCallouts,Database.stateful {
    
    // Class properties
    private String bucketName;
    private String fileName; // The exact file name, found in start()
    private String Type;
    private Date fileDate;
    private String fileNamePattern; // The prefix (optouts) or exact name (disqualified)
    private List<String> allRows = new List<String>();
    
    /**
     * Constructor: Initializes the batch job.
     * It now only takes the type and date, and builds the filename pattern.
     */
    public GCSFilesBatch(String bucketName, String fileType) {
        this.bucketName = bucketName;
        this.Type = fileType;
        Date effectiveDate;
        
        RD1_Settings__mdt setting = RD1_Settings__mdt.getInstance('RD1_Setting');
        String orgPrefix = setting.GCS_Files_Org__c.toLowerCase();
        
        System.debug('📌 orgPrefix = ' + orgPrefix);
        
        
        if (setting != null && setting.GCS_Files_Date__c != null){
            effectiveDate = setting.GCS_Files_Date__c;
            System.debug('📌 Using CMDT override date = ' + effectiveDate);
        }else{
            effectiveDate = system.today();
        }
        
        Datetime dt = Datetime.newInstance(effectiveDate, Time.newInstance(0,0,0,0));
    	String dateString = dt.format('yyyyMMdd');
        
        System.debug('📌 dateString = ' + dateString);
        if (this.Type == 'optouts') {
            // This is the prefix we will use to find the file
            // e.g., prod_to_rdone_report_rd_one_optouts_20250926
            this.fileNamePattern = orgPrefix + '/to_rdone/report_rd_one_optouts_' + dateString;
            system.debug('this.fileNamePattern>>'+this.fileNamePattern);
            
        } else if (this.Type == 'disqualified') {
            // This is the exact filename
            // e.g., prod_to_rdone_hr_disqualfied_candidates_20251017.csv
            this.fileNamePattern =  orgPrefix + '_to_rdone_hr_disqualfied_candidates_' + dateString;
            
        } else {
            System.debug('⚠️ Unknown file type: ' + fileType);
            sendErrorEmail('Batch Constructor Error', 'Unknown file type specified: ' + fileType);
        }
        
        System.debug('ℹ️ GCSFilesBatch initialized. Type: ' + this.Type + 
                     ', Pattern: ' + this.fileNamePattern);
    }
    
    /**
     * Helper method to send error notifications
     */
    private static void sendErrorEmail(String subject, String body) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'salesforce@randstad.com' });
        mail.setSubject('[Salesforce GCS Batch] ' + subject);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    /**
     * Start Method: Finds the file, downloads it, and splits it into rows.
     */
    public Iterable<String> start(Database.BatchableContext bc) {
        
        // --- 1. Find the exact file name ---
        if (this.Type == 'optouts') {
            // 🔴 REQUIRES NEW HELPER METHOD IN GoogleCloudDownloader 🔴
            // This method must list files in GCS and return the first match.
            try {
                this.fileName = GoogleCloudDownloader.findFileByPrefix(bucketName, this.fileNamePattern);
            } catch (Exception e) {
                System.debug('Error calling findFileByPrefix: ' + e.getMessage());
                sendErrorEmail('GCS Helper Missing', 'The method GoogleCloudDownloader.findFileByPrefix does not exist or failed.');
                return new List<String>();
            }
            
            if (String.isBlank(this.fileName)) {
                System.debug('No file found for prefix: ' + this.fileNamePattern);
                // Send email but don't stop the whole org; just stop this batch
                sendErrorEmail('File not found', 'No file found in GCS for prefix: ' + this.fileNamePattern);
                return new List<String>();
            }
            
        } else if (this.Type == 'disqualified') {
            // The pattern *is* the exact file name
            this.fileName = GoogleCloudDownloader.findFileByPrefix(bucketName, this.fileNamePattern);
        }

        if (String.isBlank(this.fileName)) {
             System.debug('File name could not be determined.');
             return new List<String>();
        }
        
        System.debug('ℹ️ Processing file: ' + this.fileName);

        // --- 2. Download the file content ---
        String csvContent = GoogleCloudDownloader.downloadFile(bucketName, this.fileName);
        
        if (csvContent != null && csvContent.contains('Exceeded max size limit')){
            sendErrorEmail('File too large', 
             'The file ' + this.fileName + ' exceeded the max size limit and could not be processed.');
            return new List<String>();
        }
        
        if (String.isBlank(csvContent)) {
            return new List<String>(); // return empty
        }
        
        // --- 3. Split content into rows ---
        Integer startIdx = 0;
        Boolean isHeader = true;
        while (true){
            Integer nextIdx = csvContent.indexOf('\n', startIdx);
            if (nextIdx == -1){
                String lastLine = csvContent.substring(startIdx).trim();
                if (!String.isBlank(lastLine) && !isHeader){
                    allRows.add(lastLine);
                }
                break;
            }else{
                String line = csvContent.substring(startIdx, nextIdx).trim();
                if (!String.isBlank(line)){
                    if(isHeader){
                        isHeader = false;
                    }else{
                        allRows.add(line);
                    }
                }
                startIdx = nextIdx + 1;
            }
        }
        System.debug('✅ Total rows: ' + allRows.size());
        return allRows;
    }
    
    /**
     * Execute Method: Routes processing based on the file type.
     */
    public void execute(Database.BatchableContext bc, List<String> scope) {
        if (this.Type == 'optouts') {
            processOptOuts(scope);
        } else if (this.Type == 'disqualified') {
            processDisqualified(scope);
        } else {
            System.debug('⚠️ Skipping execution. Unknown file type: ' + this.Type + ' for file ' + this.fileName);
        }
    }
    
    private void processOptOuts(List<String> scope) {
        system.debug('OptOuts Record Creation>>'+scope);
        List<Opt_Out_From_PFC__c> records = new List<Opt_Out_From_PFC__c>();
        
        for (String row : scope) {
            if (String.isNotBlank(row)) {
                List<String> cols = row.split(',');
                if (cols.size() >= 3) {
                    try {
                        Opt_Out_From_PFC__c optOut = new Opt_Out_From_PFC__c();
                        optOut.Email_Id__c = cols[0];
                        optOut.Opt_Out_Date__c = Date.valueOf(cols[1]); // This could fail if col[1] is not 'YYYY-MM-DD'
                        optOut.Optout__c = (cols[2] == 'Y');
                        system.debug('optOut>>'+optOut);
                        records.add(optOut);
                    } catch (Exception e) {
                        System.debug('⚠️ Error parsing OptOut row: ' + row + '. Error: ' + e.getMessage());
                    }
                }
            }
        }
        
        if (!records.isEmpty()) {
            Database.SaveResult[] results = Database.insert(records, false);
            System.debug('✅ Prepared ' + records.size() + ' Opt_Out_From_PFC__c rows from ' + fileName);
        }
    }
    private void processDisqualified(List<String> scope) {
        System.debug('ℹ️ Reached processDisqualified method for ' + scope.size() + ' rows. Implement logic here.');
        
        
        List<Opt_Out_From_PFC__c> records = new List<Opt_Out_From_PFC__c>();
        
        for (String row : scope) {
            if (String.isNotBlank(row)) {
                List<String> cols = row.split(',');
                if (cols.size() >= 3) {
                    try {
                        Opt_Out_From_PFC__c optOut = new Opt_Out_From_PFC__c();
                        optOut.Email_Id__c = cols[0];
                        optOut.Opt_Out_Date__c = Date.valueOf(cols[1]); // This could fail if col[1] is not 'YYYY-MM-DD'
                        optOut.Optout__c = (cols[2] == 'Y');
                        optOut.Disqualified__c = (cols[3] == 'Y');
                        system.debug('optOut>>'+optOut);
                        records.add(optOut);
                    } catch (Exception e) {
                        System.debug('⚠️ Error parsing OptOut row: ' + row + '. Error: ' + e.getMessage());
                    }
                }
            }
        }
        
        if (!records.isEmpty()) {
            Database.SaveResult[] results = Database.insert(records, false);
            System.debug('✅ Prepared ' + records.size() + ' Opt_Out_From_PFC__c rows from ' + fileName);
        }
    }
    
    /**
     * Finish Method: Moves the file to an archive.
     */
    public void finish(Database.BatchableContext bc) {
       if (String.isNotBlank(this.fileName)){
           RD1_Settings__mdt setting = RD1_Settings__mdt.getInstance('RD1_Setting');
        	String orgPrefix = setting.GCS_Files_Org__c.toLowerCase();
           String archiveName = orgPrefix+'/archive';
            Boolean moved = GoogleCloudDownloader.moveFile(bucketName, this.fileName, archiveName);
           system.debug('Moved??'+moved);
            if (!moved){
                sendErrorEmail('File move failed', 
                 'The file ' + this.fileName + ' could not be moved to archive after processing.');
            }
        }
        System.debug('✅ Batch finished for file: ' + this.fileName);
    }
}