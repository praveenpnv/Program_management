/**
 * This batch job finds 'Opt_Out_From_PFC__c' records that have not been processed.
 *
 * It performs TWO passes in one 'execute' method:
 * 1. Finds records with a blank 'Contact_Candidate__c' lookup and populates
 * it by matching on an email field (assumed to be 'Email_Id__c	').
 * 2. For all records that now have a Contact ID, it performs THREE actions:
 * - Creates a 'TR1__Candidate_Opt_Out__c' record.
 * - Updates the matched Contact's 'HasOptedOutOfEmail' field to true.
 * - If 'Disqualified__c' is true, updates the Contact's 'DO_NOT_USE__c' to true.
 *
 * It assumes an "Email Type" record with Name = 'Marketing Email' exists.
 */
public class ProcessPfcOptOutsBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Id marketingEmailTypeId;
    private Integer recordsFailed = 0;

    // --- !! UPDATE THIS IF YOUR FIELD NAME IS DIFFERENT !! ---
    // Aggiorna questo se il nome del tuo campo e-mail è diverso
    public String emailFieldApiName = 'Email_Id__c';
    // --------------------------------------------------------

    /**
     * Constructor
     * Finds the 'Marketing' Email Type ID when the batch starts.
     */
    public ProcessPfcOptOutsBatch() {
        try {
            TR1__Email_Type__c emailType = [
                SELECT Id 
                FROM TR1__Email_Type__c 
                WHERE Name = 'Marketing Email' 
                LIMIT 1
            ];
            this.marketingEmailTypeId = emailType.Id;
            System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch CONSTRUCTOR: Found "Marketing Email" Type ID: ' + this.marketingEmailTypeId);
        } catch (QueryException e) {
            this.marketingEmailTypeId = null;
            System.debug(LoggingLevel.ERROR, 'ProcessPfcOptOutsBatch CRITICAL ERROR: Could not find "Marketing Email" Email Type. Batch will fail. Error: ' + e.getMessage());
        }
    }

    /**
     * START Method
     * Gathers all unprocessed records. The email matching logic
     * requires us to fetch records even if Contact_Candidate__c is null.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // --- MODIFIED QUERY ---
        // Fetch ALL unprocessed records. We will handle null lookups in execute.
        String query = 'SELECT Id, Contact_Candidate__c, Name, Disqualified__c, ' + this.emailFieldApiName + ' ' +
                         'FROM Opt_Out_From_PFC__c ' +
                         'WHERE Processed__c = false';
        
        System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch START: Executing query: ' + query);
        return Database.getQueryLocator(query);
    }

    /**
     * EXECUTE Method
     * Processes each batch of records.
     */
    public void execute(Database.BatchableContext bc, List<Opt_Out_From_PFC__c> scope) {
        System.debug(LoggingLevel.DEBUG, 'ProcessPfcOptOutsBatch EXECUTE: Processing ' + scope.size() + ' records.');

        // Stop processing if the Marketing Email Type wasn't found in the constructor
        if (this.marketingEmailTypeId == null) {
            recordsFailed += scope.size();
            System.debug(LoggingLevel.WARN, 'ProcessPfcOptOutsBatch EXECUTE: Stopped processing batch. marketingEmailTypeId is null.');
            return;
        }

        // --- NEW LOGIC: START - Populate missing lookups ---
        
        // 1. Find records that need an email lookup
        Map<String, List<Opt_Out_From_PFC__c>> emailToPfcMap = new Map<String, List<Opt_Out_From_PFC__c>>();
        for (Opt_Out_From_PFC__c pfc : scope) {
            if (pfc.Contact_Candidate__c == null) {
                String email = (String)pfc.get(this.emailFieldApiName);
                if (String.isNotBlank(email)) {
                    String emailKey = email.toLowerCase();
                    if (!emailToPfcMap.containsKey(emailKey)) {
                        emailToPfcMap.put(emailKey, new List<Opt_Out_From_PFC__c>());
                    }
                    emailToPfcMap.get(emailKey).add(pfc);
                }
            }
        }

        // 2. Query for Contacts if we have emails to look up
        if (!emailToPfcMap.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'ProcessPfcOptOutsBatch EXECUTE: Found ' + emailToPfcMap.size() + ' emails to look up.');
            
            Map<String, Id> emailToContactIdMap = new Map<String, Id>();
            // Find Contacts matching the emails
            for (Contact c : [SELECT Id, Email FROM Contact WHERE Email IN :emailToPfcMap.keySet()]) {
                if (c.Email != null) {
                    emailToContactIdMap.put(c.Email.toLowerCase(), c.Id);
                }
            }

            // 3. Populate the lookup field *in memory*
            for (String emailKey : emailToContactIdMap.keySet()) {
                Id matchedContactId = emailToContactIdMap.get(emailKey);
                for (Opt_Out_From_PFC__c pfcToFix : emailToPfcMap.get(emailKey)) {
                    // This update only exists in this transaction's memory
                    pfcToFix.Contact_Candidate__c = matchedContactId;
                }
            }
        }
        // --- NEW LOGIC: END ---


        // --- ORIGINAL LOGIC (Now runs on the in-memory-fixed records) ---
        
        // Collect all *now-populated* Contact IDs
        Set<Id> contactIds = new Set<Id>();
        for (Opt_Out_From_PFC__c pfcRecord : scope) {
            if (pfcRecord.Contact_Candidate__c != null) {
                contactIds.add(pfcRecord.Contact_Candidate__c);
            }
        }

        if (contactIds.isEmpty()) {
            recordsFailed += scope.size(); // No records had/found a Contact ID
            System.debug(LoggingLevel.WARN, 'ProcessPfcOptOutsBatch EXECUTE: No Contact IDs found/matched in this scope.');
            return;
        }
        
        System.debug(LoggingLevel.DEBUG, 'ProcessPfcOptOutsBatch EXECUTE: Collected ' + contactIds.size() + ' unique Contact IDs.');
        
        // Find existing Opt-Outs to prevent creating duplicates
        Set<String> existingComputedKeys = new Set<String>();
        for(TR1__Candidate_Opt_Out__c existingOptOut : [
            SELECT TR1__Computed_key__c 
            FROM TR1__Candidate_Opt_Out__c 
            WHERE TR1__Candidate__c IN :contactIds
            AND TR1__Email_Type__c = :this.marketingEmailTypeId
        ]) {
            existingComputedKeys.add(existingOptOut.TR1__Computed_key__c);
        }
        System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch EXECUTE: Found ' + existingComputedKeys.size() + ' existing opt-outs for deduplication.');

        List<TR1__Candidate_Opt_Out__c> newOptOutsToInsert = new List<TR1__Candidate_Opt_Out__c>();
        List<Opt_Out_From_PFC__c> pfcRecordsToUpdate = new List<Opt_Out_From_PFC__c>();
        Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>();

        // Process each PFC record
        for (Opt_Out_From_PFC__c pfcRecord : scope) {
            
            // If lookup is *still* null (email match failed), mark as failed and skip
            if (pfcRecord.Contact_Candidate__c == null) {
                recordsFailed++;
                continue;
            }

            Id contactId = pfcRecord.Contact_Candidate__c;
            
            // Generate the required, unique computed key
            String computedKey = contactId + '-' + this.marketingEmailTypeId;
            
            String optOutName = pfcRecord.Name;
            if(optOutName != null && optOutName.length() > 80) {
                optOutName = optOutName.substring(0, 80);
            }

            // Create new Opt-Out record if it doesn't already exist
            if (!existingComputedKeys.contains(computedKey)) {
                newOptOutsToInsert.add(new TR1__Candidate_Opt_Out__c(
                    Name = optOutName,
                    TR1__Candidate__c = contactId,
                    TR1__Email_Type__c = this.marketingEmailTypeId,
                    TR1__Computed_key__c = computedKey
                ));
            } else {
                System.debug(LoggingLevel.DEBUG, 'ProcessPfcOptOutsBatch: Skipping duplicate for Contact ID: ' + contactId);
            }
            
            // Mark source PFC record as processed
            pfcRecord.Processed__c = true;
            // The pfcRecord SObject *also* contains the Contact_Candidate__c
            // that we populated in memory. Both fields will be updated.
            pfcRecordsToUpdate.add(pfcRecord);
            
            // --- Prepare Contact for update ---
            Contact contactToUpdate = contactsToUpdateMap.get(contactId);
            if (contactToUpdate == null) {
                contactToUpdate = new Contact(Id = contactId);
            }
            
            contactToUpdate.HasOptedOutOfEmail = true;
            if (pfcRecord.Disqualified__c == true) {
                contactToUpdate.DO_NOT_USE__c = true;
            }
            
            contactsToUpdateMap.put(contactToUpdate.Id, contactToUpdate);
        }

        // --- Perform all DML operations ---
        try {
            // 1. Insert new Candidate Opt-Out records
            if (!newOptOutsToInsert.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch DML: Inserting ' + newOptOutsToInsert.size() + ' new TR1__Candidate_Opt_Out__c records.');
                Database.insert(newOptOutsToInsert, false);
            }
            // 2. Update source PFC records (This saves BOTH Processed__c AND the new Contact_Candidate__c)
            if (!pfcRecordsToUpdate.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch DML: Updating ' + pfcRecordsToUpdate.size() + ' Opt_Out_From_PFC__c records.');
                Database.update(pfcRecordsToUpdate, false);
            }
            // 3. Update matched Contact records
            if (!contactsToUpdateMap.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch DML: Updating ' + contactsToUpdateMap.size() + ' Contact records.');
                Database.update(contactsToUpdateMap.values(), false);
            }

        } catch (Exception e) {
            recordsFailed += newOptOutsToInsert.size(); // Assume all inserts in this batch failed
            System.debug(LoggingLevel.ERROR, 'ProcessPfcOptOutsBatch DML ERROR: ' + e.getMessage() + '\nStackTrace: ' + e.getStackTraceString());
        }
    }

    /**
     * FINISH Method
     * Runs after all batches are processed and sends a summary email.
     */
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                                TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        
        String emailBody = 'The Opt-Out Batch Process has completed.<br/><br/>' +
                           'Status: '.escapeHtml4() + job.Status.escapeHtml4() + '<br/>' +
                           'Total Records Processed: ' + job.TotalJobItems + '<br/>' +
                           'Records Failed (No Contact / No "Marketing" Type / No Email Match): ' + recordsFailed + '<br/>' +
                           'DML Errors: ' + job.NumberOfErrors;

        System.debug(LoggingLevel.INFO, 'ProcessPfcOptOutsBatch FINISH: Job Complete.' +
            ' Status: ' + job.Status +
            '. Processed: ' + job.TotalJobItems +
            '. Failed: ' + recordsFailed +
            '. DML Errors: ' + job.NumberOfErrors);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { job.CreatedBy.Email });
        mail.setSubject('Opt-Out Batch Process Completed: ' + job.Status);
        mail.setHtmlBody(emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}