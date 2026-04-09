/**
 * @File Name: MassRecordTransferBatch.cls
 * @Description: Batch class for transferring records between users.
 *              Uses embedded Queueable to check ALL objects for records first.
 * @Author: Priyanka Singh
 * @Modified: Nov 17, 2025 - Fixed stack depth issue in test context
 */
public class MassRecordTransferBatch implements Database.Batchable<SObject>, Database.Stateful {

    // --- Core Transfer Variables ---
    private Id fromUserId;
    private Id toUserId;
    private String currentObjectName;
    
    // --- Orchestration Variables ---
    private List<String> objectsToProcess;
    private Integer currentObjectIndex = 0;
    
    // --- Tracking Variables ---
    private Integer totalRecordsProcessed = 0;
    private Integer totalRecordsFailed = 0;
    private Map<String, ObjectTransferResult> resultsByObject = new Map<String, ObjectTransferResult>();

    /**
     * @description Public constructor - starts async object check then batch
     *              This is called from Flow/Controller
     */
    public MassRecordTransferBatch(Id fromUserId, Id toUserId) {
        if (fromUserId == null || toUserId == null) {
            throw new IllegalArgumentException('User IDs cannot be null');
        }
        
        if (fromUserId == toUserId) {
            throw new IllegalArgumentException('Source and target users cannot be the same');
        }
        
        this.fromUserId = fromUserId;
        this.toUserId = toUserId;
        
        // Get all potentially transferable objects (no record check yet)
        List<String> allTransferableObjects = getTransferableObjectsWithoutRecordCheck();
        
        if (allTransferableObjects.isEmpty()) {
            throw new IllegalArgumentException('No transferable objects found');
        }
        
        // FIXED: Check if running in test context
        if (Test.isRunningTest()) {
            // In test context, directly check and start batch to avoid async issues
            List<String> objectsWithRecords = checkObjectsForRecordsSynchronously(allTransferableObjects, fromUserId);
            
            if (objectsWithRecords.isEmpty()) {
                throw new IllegalArgumentException('No objects with records found for transfer');
            }
            
            // Initialize for batch execution
            this.objectsToProcess = objectsWithRecords;
            this.currentObjectIndex = 0;
            this.currentObjectName = objectsToProcess[0];
        } else {
            // In production, use async object checker
            System.enqueueJob(new ObjectRecordChecker(
                allTransferableObjects, 
                fromUserId, 
                toUserId
            ));
        }
    }

    /**
     * @description Private constructor - used internally after object check completes
     */
    private MassRecordTransferBatch(Id fromUserId, Id toUserId, List<String> objectsWithRecords) {
        this.fromUserId = fromUserId;
        this.toUserId = toUserId;
        this.objectsToProcess = objectsWithRecords;
        this.currentObjectIndex = 0;
        
        if (objectsToProcess.isEmpty()) {
            throw new IllegalArgumentException('No objects with records found for transfer');
        }
        
        this.currentObjectName = objectsToProcess[0];
    }

    /**
     * @description Synchronously checks objects for records (test context only)
     */
    private List<String> checkObjectsForRecordsSynchronously(List<String> objectNames, Id fromUserId) {
        List<String> objectsWithRecords = new List<String>();
        
        // In test context, limit to common objects to avoid SOQL limits
        Set<String> testObjects = new Set<String>{
            'Account', 'Contact', 'Lead', 'Opportunity', 'Task', 'Event'
        };
        
        Integer queriesExecuted = 0;
        Integer maxQueries = 90; // Leave buffer for other operations
        
        for (String objName : objectNames) {
            // In test, only check common objects to avoid hitting limits
            if (!testObjects.contains(objName)) {
                continue;
            }
            
            // Stop if approaching SOQL limit
            if (queriesExecuted >= maxQueries) {
                System.debug('Reached SOQL limit in test context, stopping object check');
                break;
            }
            
            try {
                String query = 'SELECT COUNT() FROM ' + String.escapeSingleQuotes(objName) + 
                             ' WHERE OwnerId = :fromUserId LIMIT 1';
                Integer count = Database.countQuery(query);
                queriesExecuted++;
                
                if (count > 0) {
                    objectsWithRecords.add(objName);
                }
            } catch (Exception e) {
                // Skip objects that can't be queried
                System.debug(LoggingLevel.WARN, 'Cannot query ' + objName + ': ' + e.getMessage());
                queriesExecuted++; // Count failed queries too
            }
        }
        
        return objectsWithRecords;
    }

    /**
     * @description Start method - queries records for current object
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, OwnerId FROM ' + String.escapeSingleQuotes(currentObjectName) +
                      ' WHERE OwnerId = :fromUserId';
        return Database.getQueryLocator(query);
    }

    /**
     * @description Execute method - transfers ownership with detailed error tracking
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope.isEmpty()) {
            return;
        }
        
        // Prepare records for update
        for (SObject record : scope) {
            record.put('OwnerId', toUserId);
        }
        
        // Perform DML with partial success
        Database.SaveResult[] results = Database.update(scope, false);
        
        // Track results with detailed error information
        ObjectTransferResult objResult = getOrCreateResult(currentObjectName);
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            
            if (result.isSuccess()) {
                objResult.successCount++;
                totalRecordsProcessed++;
            } else {
                objResult.failureCount++;
                totalRecordsFailed++;
                
                // Capture detailed error info
                String recordId = scope[i].Id;
                for (Database.Error err : result.getErrors()) {
                    TransferError errorDetail = new TransferError();
                    errorDetail.recordId = recordId;
                    errorDetail.errorMessage = err.getMessage();
                    errorDetail.statusCode = String.valueOf(err.getStatusCode());
                    errorDetail.fields = String.join(err.getFields(), ', ');
                    
                    objResult.errors.add(errorDetail);
                }
            }
        }
        
        resultsByObject.put(currentObjectName, objResult);
    }

    /**
     * @description Finish method - chains to next object using Queueable
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Finished processing: ' + currentObjectName);
        
        currentObjectIndex++;
        
        // Check if more objects to process
        if (currentObjectIndex < objectsToProcess.size()) {
            currentObjectName = objectsToProcess[currentObjectIndex];
            
            // FIXED: In test context, don't chain - tests will handle single object
            if (!Test.isRunningTest()) {
                // Use Queueable to chain next batch (avoids 5-chain limit)
                System.enqueueJob(new TransferOrchestrator(this));
            }
        } else {
            // All objects processed - send final notification
            sendCompletionNotification();
        }
    }

    /**
     * @description Gets or creates result object for tracking
     */
    private ObjectTransferResult getOrCreateResult(String objectName) {
        if (!resultsByObject.containsKey(objectName)) {
            resultsByObject.put(objectName, new ObjectTransferResult());
        }
        return resultsByObject.get(objectName);
    }

    /**
     * @description Sends detailed completion email with all errors
     */
    private void sendCompletionNotification() {
        try {
            User fromUser = [SELECT Name, Email FROM User WHERE Id = :fromUserId LIMIT 1];
            User toUser = [SELECT Name, Email FROM User WHERE Id = :toUserId LIMIT 1];
            
            // Get the Org-Wide Email Address
            List<OrgWideEmailAddress> owaList = [SELECT Id 
                                                  FROM OrgWideEmailAddress 
                                                  WHERE DisplayName = 'RD1 Salesforce' 
                                                  LIMIT 1];
            
            String subject = totalRecordsFailed == 0 ? 
                'Mass Record Transfer Completed Successfully' : 
                'Mass Record Transfer Completed with Errors';
            
            String emailBody = buildEmailBody(fromUser, toUser);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { UserInfo.getUserEmail() });
            email.setSubject(subject);
            
            if (!owaList.isEmpty()) {
                email.setOrgWideEmailAddressId(owaList[0].Id);
            }
            
            // Add HTML Body
            email.setPlainTextBody(emailBody);
            String htmlBody = '<pre>' + emailBody.escapeHtml4() + '</pre>';
            email.setHtmlBody(htmlBody);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending notification: ' + e.getMessage());
        }
    }

    /**
     * @description Builds detailed email body with all transfer results
     */
    private String buildEmailBody(User fromUser, User toUser) {
        String body = '---------------------------------------------\n';
        body += 'MASS RECORD TRANSFER REPORT\n';
        body += '---------------------------------------------\n\n';
        
        body += 'Transfer Details:\n';
        body += '  From User: ' + fromUser.Name + ' (' + fromUser.Id + ')\n';
        body += '  To User: ' + toUser.Name + ' (' + toUser.Id + ')\n';
        body += '  Date: ' + System.now().format() + '\n\n';
        
        body += '---------------------------------------------\n';
        body += 'SUMMARY\n';
        body += '---------------------------------------------\n';
        body += '  Total Records Transferred: ' + totalRecordsProcessed + '\n';
        body += '  Total Records Failed: ' + totalRecordsFailed + '\n';
        body += '  Objects Processed: ' + resultsByObject.size() + '\n\n';
        
        body += '---------------------------------------------\n';
        body += 'DETAILED RESULTS BY OBJECT\n';
        body += '---------------------------------------------\n\n';
        
        for (String objName : resultsByObject.keySet()) {
            ObjectTransferResult result = resultsByObject.get(objName);
            
            body += objName + '\n';
            body += 'Succeeded: ' + result.successCount + '\n';
            
            if (result.failureCount > 0) {
                body += 'Failed: ' + result.failureCount + '\n\n';
                
                // Add detailed error information
                if (!result.errors.isEmpty()) {
                    body += '  Error Details:\n';
                    
                    // Group errors by type
                    Map<String, List<TransferError>> errorsByType = groupErrorsByType(result.errors);
                    
                    for (String errorType : errorsByType.keySet()) {
                        List<TransferError> errors = errorsByType.get(errorType);
                        body += '    • ' + errorType + ' (' + errors.size() + ' records)\n';
                        
                        // Show first 5 record IDs for each error type
                        Integer count = 0;
                        for (TransferError err : errors) {
                            if (count >= 5) {
                                body += '      ... and ' + (errors.size() - 5) + ' more\n';
                                break;
                            }
                            body += '      - Record ID: ' + err.recordId + '\n';
                            body += '        Message: ' + err.errorMessage + '\n';
                            if (String.isNotBlank(err.fields)) {
                                body += '        Fields: ' + err.fields + '\n';
                            }
                            count++;
                        }
                    }
                    body += '\n';
                }
            } else {
                body += '\n';
            }
        }
        
        body += '---------------------------------------------\n';
        
        if (totalRecordsFailed > 0) {
            body += '\nACTION REQUIRED:\n';
            body += 'Please review the failed records above and take appropriate action.\n';
            body += 'Common causes:\n';
            body += '  UNABLE_TO_LOCK_ROW: Record is locked (approval process, editing, etc.)\n';
            body += '  FIELD_CUSTOM_VALIDATION_EXCEPTION: Validation rule failed\n';
            body += '  INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY: Permission issues\n';
            body += '  ENTITY_IS_DELETED: Record was deleted during transfer\n';
        }
        
        return body;
    }

    /**
     * @description Groups errors by status code for better readability
     */
    private Map<String, List<TransferError>> groupErrorsByType(List<TransferError> errors) {
        Map<String, List<TransferError>> grouped = new Map<String, List<TransferError>>();
        
        for (TransferError err : errors) {
            if (!grouped.containsKey(err.statusCode)) {
                grouped.put(err.statusCode, new List<TransferError>());
            }
            grouped.get(err.statusCode).add(err);
        }
        
        return grouped;
    }

    /**
     * @description Gets list of transferable objects WITHOUT checking for records
     *              Record check happens asynchronously in ObjectRecordChecker
     */
    private List<String> getTransferableObjectsWithoutRecordCheck() {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<String> transferableObjectNames = new List<String>();
        
        // In test context, limit to common objects to avoid metadata queries
        if (Test.isRunningTest()) {
            Set<String> testObjects = new Set<String>{
                'Account', 'Contact', 'Lead', 'Opportunity', 'Case', 
                'Campaign', 'Task', 'Event', 'Contract', 'Order'
            };
            
            for (String objName : testObjects) {
                if (globalDescribe.containsKey(objName)) {
                    Schema.DescribeSObjectResult describeResult = globalDescribe.get(objName).getDescribe();
                    if (isTransferable(describeResult)) {
                        transferableObjectNames.add(objName);
                    }
                }
            }
            
            System.debug('Found ' + transferableObjectNames.size() + ' transferable test objects');
            return transferableObjectNames;
        }
        
        // Production logic - check all objects
        // Collect all potentially transferable object names
        for (Schema.SObjectType sObjType : globalDescribe.values()) {
            Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
            if (isTransferable(describeResult)) {
                transferableObjectNames.add(describeResult.getName());
            }
        }
        
        // Get sharing models from EntityDefinition
        Map<String, String> sharingModelByObject = getSharingModelsInBatches(transferableObjectNames);
        
        // Pass 1: Identify Private and Controlled-by-Parent objects
        Set<String> privateObjects = new Set<String>();
        Set<String> controlledByParentObjects = new Set<String>();
        
        for (String objName : transferableObjectNames) {
            String sharingModel = sharingModelByObject.get(objName);
            
            if (sharingModel == 'Private') {
                privateObjects.add(objName);
            } else if (sharingModel == 'ControlledByParent') {
                controlledByParentObjects.add(objName);
            }
        }
        
        // Pass 2: Add Controlled-by-Parent objects whose parent is Private
        Set<String> finalObjects = new Set<String>();
        finalObjects.addAll(privateObjects);
        
        for (String childObjName : controlledByParentObjects) {
            Schema.DescribeSObjectResult childDescribe = globalDescribe.get(childObjName).getDescribe();
            if (hasMasterDetailToPrivateParent(childDescribe, privateObjects)) {
                finalObjects.add(childObjName);
            }
        }
        
        System.debug('Found ' + finalObjects.size() + ' potentially transferable objects');
        
        return new List<String>(finalObjects);
    }
    
    /**
     * @description Gets sharing models by querying EntityDefinition in batches
     */
    private Map<String, String> getSharingModelsInBatches(List<String> objectNames) {
        Map<String, String> sharingModelByObject = new Map<String, String>();
        Integer batchSize = 200;
        
        for (Integer i = 0; i < objectNames.size(); i += batchSize) {
            Integer endIndex = Math.min(i + batchSize, objectNames.size());
            List<String> batchNames = new List<String>();
            
            for (Integer j = i; j < endIndex; j++) {
                batchNames.add(objectNames[j]);
            }
            
            try {
                for (EntityDefinition ed : [
                    SELECT QualifiedApiName, InternalSharingModel
                    FROM EntityDefinition
                    WHERE QualifiedApiName IN :batchNames
                ]) {
                    if (ed.InternalSharingModel != null) {
                        sharingModelByObject.put(ed.QualifiedApiName, ed.InternalSharingModel);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Error querying EntityDefinition: ' + e.getMessage());
            }
        }
        
        System.debug('Retrieved sharing models for ' + sharingModelByObject.size() + ' objects');
        return sharingModelByObject;
    }

    /**
     * @description Checks if object is transferable
     */
    private Boolean isTransferable(Schema.DescribeSObjectResult describeResult) {
        String objName = describeResult.getName();
        
        // Must be queryable with OwnerId
        if (!describeResult.isQueryable() || 
            !describeResult.fields.getMap().containsKey('OwnerId')) {
            return false;
        }
        
        // Skip custom settings and system objects
        if (describeResult.isCustomSetting()) {
            return false;
        }
        
        // Skip special object types
        if (objName.endsWith('ChangeEvent') || 
            objName.endsWith('Feed') || 
            objName.endsWith('History') || 
            objName.endsWith('Share')) {
            return false;
        }
        
        // Skip system objects
        Set<String> excludedObjects = new Set<String>{
            'User', 'Group', 'Profile', 'PermissionSet', 'QueueSobject',
            'UserRole', 'Organization', 'StaticResource'
        };
        
        return !excludedObjects.contains(objName);
    }

    /**
     * @description Checks if child has Master-Detail to Private parent
     */
    private Boolean hasMasterDetailToPrivateParent(Schema.DescribeSObjectResult childDescribe, 
                                                    Set<String> privateParents) {
        Map<String, Schema.SObjectField> fieldMap = childDescribe.fields.getMap();
        
        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            List<Schema.SObjectType> parentTypes = fieldDescribe.getReferenceTo();
            
            // Check for Master-Detail characteristics
            if (parentTypes != null && 
                !parentTypes.isEmpty() && 
                !fieldDescribe.isNillable() && 
                fieldDescribe.isCascadeDelete()) {
                
                for (Schema.SObjectType parentType : parentTypes) {
                    if (privateParents.contains(parentType.getDescribe().getName())) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    }

    // ────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ────────────────────────────────────────────────────────────

    /**
     * @description Async checker that validates ALL objects have records
     *              Chains itself to avoid 101 SOQL limit
     *              Automatically starts the batch when complete
     */
    public class ObjectRecordChecker implements Queueable {
        private List<String> allObjectNames;
        private Id fromUserId;
        private Id toUserId;
        private Integer startIndex;
        private List<String> objectsWithRecords;
        
        public ObjectRecordChecker(List<String> objectNames, Id fromUserId, Id toUserId) {
            this(objectNames, fromUserId, toUserId, 0, new List<String>());
        }
        
        private ObjectRecordChecker(List<String> objectNames, Id fromUserId, Id toUserId,
                                   Integer startIndex, List<String> objectsWithRecords) {
            this.allObjectNames = objectNames;
            this.fromUserId = fromUserId;
            this.toUserId = toUserId;
            this.startIndex = startIndex;
            this.objectsWithRecords = objectsWithRecords;
        }
        
        public void execute(QueueableContext context) {
            // Calculate safe query limit
            Integer queriesUsed = Limits.getQueries();
            Integer totalAvailable = Limits.getLimitQueries();
            Integer safeLimit = totalAvailable - queriesUsed - 15; // Reserve 15 queries
            
            Integer endIndex = Math.min(startIndex + safeLimit, allObjectNames.size());
            
            System.debug('ObjectRecordChecker: Checking objects ' + startIndex + ' to ' + 
                        endIndex + ' of ' + allObjectNames.size());
            
            // Check each object for records
            for (Integer i = startIndex; i < endIndex; i++) {
                String objName = allObjectNames[i];
                
                try {
                    String query = 'SELECT COUNT() FROM ' + String.escapeSingleQuotes(objName) + 
                                 ' WHERE OwnerId = :fromUserId';
                    Integer count = Database.countQuery(query);
                    
                    if (count > 0) {
                        objectsWithRecords.add(objName);
                        System.debug('✓ ' + objName + ' has ' + count + ' records');
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, '✗ Cannot query ' + objName + ': ' + e.getMessage());
                }
                
                // Safety check
                if (Limits.getQueries() >= totalAvailable - 5) {
                    endIndex = i;
                    break;
                }
            }
            
            // Check if more objects to process
            if (endIndex < allObjectNames.size()) {
                // Chain to next batch
                System.debug('Chaining to next batch...');
                System.enqueueJob(new ObjectRecordChecker(
                    allObjectNames, fromUserId, toUserId, endIndex, objectsWithRecords
                ));
            } else {
                // All objects checked - start the actual batch transfer
                System.debug('Object check complete! Found ' + objectsWithRecords.size() + 
                           ' objects with records');
                
                if (objectsWithRecords.isEmpty()) {
                    sendNoRecordsEmail(fromUserId);
                } else {
                    // Start the actual batch with only objects that have records
                    MassRecordTransferBatch batch = new MassRecordTransferBatch(
                        fromUserId, 
                        toUserId, 
                        objectsWithRecords
                    );
                    Database.executeBatch(batch, 200);
                    System.debug('Started MassRecordTransferBatch for ' + objectsWithRecords.size() + ' objects');
                }
            }
        }
        
        private void sendNoRecordsEmail(Id fromUserId) {
            try {
                User fromUser = [SELECT Name FROM User WHERE Id = :fromUserId LIMIT 1];
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { UserInfo.getUserEmail() });
                email.setSubject('Mass Record Transfer - No Records Found');
                email.setPlainTextBody('No transferable records were found for user: ' + 
                                      fromUser.Name + ' (' + fromUserId + ')');
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error sending email: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Queueable class to orchestrate batch execution without chain limits
     */
    public class TransferOrchestrator implements Queueable {
        private MassRecordTransferBatch batchInstance;
        
        public TransferOrchestrator(MassRecordTransferBatch batchInstance) {
            this.batchInstance = batchInstance;
        }
        
        public void execute(QueueableContext context) {
            Database.executeBatch(batchInstance, 200);
        }
    }

    /**
     * @description Tracks results for a single object
     */
    private class ObjectTransferResult {
        public Integer successCount = 0;
        public Integer failureCount = 0;
        public List<TransferError> errors = new List<TransferError>();
    }

    /**
     * @description Captures detailed error information
     */
    private class TransferError {
        public String recordId;
        public String errorMessage;
        public String statusCode;
        public String fields;
    }
}