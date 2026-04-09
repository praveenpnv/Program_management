/***
 * Data Loader class to load S3 files into a target object (e.g., Account)
 * - Schedules can run in parallel without stepping on each other by selecting
 *   records in opposite CreatedDate order (ASC vs DESC).
 * - Uses CreatedDate for ORDER BY (runtime direction via constructor).
 * - Selects only rows with Status__c = null (no 'Failure' condition).
 */
public class DataLoad_S3FileToContentBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    String destination = '';
    Integer limitRecords = 10;
    Boolean orderAscending = true; // true = ASC, false = DESC
    Boolean appendTrailingSpace = false; // NEW: when true, append one extra trailing space to the URL path

    public DataLoad_S3FileToContentBatch(String destination, Integer limitRecords) {
        this(destination, limitRecords, true, false); // default: ASC, no extra space
    }

    public DataLoad_S3FileToContentBatch(String destination, Integer limitRecords, Boolean orderAscending) {
        this(destination, limitRecords, orderAscending, false); // default: no extra space
    }

    // NEW: constructor to accept the "appendTrailingSpace" flag
    public DataLoad_S3FileToContentBatch(String destination, Integer limitRecords, Boolean orderAscending, Boolean appendTrailingSpace) {
        this.destination = (destination == null) ? '' : destination;
        this.limitRecords = (limitRecords == null || limitRecords <= 0) ? 10 : limitRecords;
        this.orderAscending = (orderAscending == null) ? true : orderAscending;
        this.appendTrailingSpace = (appendTrailingSpace == null) ? false : appendTrailingSpace;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String direction = orderAscending ? 'ASC' : 'DESC';

        String q =
            'SELECT Id, Date_Added__c, Destination__c, File_ID__c, S3_File_Url__c, Source_BH_ID__c, ' +
            'Status__c, Title__c, Type__c, SFDC_ID__c, Candidate_ID__c, CreatedDate ' +
            'FROM Data_Load_Resume__c ' +
            'WHERE Status__c = null ' +
            'AND Destination__c = \'' + String.escapeSingleQuotes(destination) + '\' ' +
            'ORDER BY CreatedDate ' + direction + ', Id ' + direction + ' ' + // stable tiebreaker
            'LIMIT ' + String.valueOf(limitRecords);

        return Database.getQueryLocator(q);
    }

    public void execute(Database.BatchableContext BC, List<Data_Load_Resume__c> scope) {
        this.process(scope);
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: logging or post-processing
    }

    // ---------- Core Processing ----------
    public void process(List<Data_Load_Resume__c> scope) {

        // Collect source IDs from scope
        Set<String> sourceIDs = new Set<String>();
        for (Data_Load_Resume__c record : scope) {
            sourceIDs.add(record.Source_BH_ID__c);
        }

        // Find destination records by Legacy_BH_ID__c in the target sObject (destination)
        Map<String, SObject> mp = queryExistingID(sourceIDs, this.destination);

        List<ContentVersion> contentToInsert = new List<ContentVersion>();
        Map<String, Data_Load_Resume__c> fileIDToDataLoad = new Map<String, Data_Load_Resume__c>();
        List<Data_Load_Resume__c> recordsToUpdate = new List<Data_Load_Resume__c>();

        // Optional linking to Contact by Candidate_ID__c → Legacy_BH_ID__c
        Map<String, Contact> mpContacts = queryAllContacts(scope);

        for (Data_Load_Resume__c record : scope) {
            try {
                SObject destinationRecord = mp.get(record.Source_BH_ID__c);

                if (destinationRecord == null) {
                    record.Status__c = 'Failure';
                    record.Error__c = 'No ' + record.Destination__c + ' found for : ' + record.Source_BH_ID__c;
                    recordsToUpdate.add(record);
                    continue;
                }
                record.Exists__c = true;

                // Prepare S3 GET request
                HttpRequest req = new HttpRequest();
                // Use the new overload that can append a trailing space (%20) if the batch flag is true
                req.setEndpoint('callout:S3/' + encodeS3Path(record.S3_File_Url__c, this.appendTrailingSpace));
                req.setMethod('GET');

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Blob fileBody = res.getBodyAsBlob();
                    String fileName = extractFileName(record.S3_File_Url__c);

                    ContentVersion content = new ContentVersion(
                        Title = fileName,
                        PathOnClient = '/' + fileName,
                        VersionData = fileBody,
                        FirstPublishLocationId = destinationRecord.Id,
                        CreatedDate = ParseDate(record.Date_Added__c),
                        LastModifiedDate = ParseDate(record.Date_Added__c)
                    );

                    if (record.Type__c == 'Resume') {
                        content.Is_Resume__c = true;
                    }
                    content.File_Category__c = record.Type__c;
                    content.Legacy_BH_ID__c = record.File_ID__c;

                    contentToInsert.add(content);
                    fileIDToDataLoad.put(record.File_ID__c, record);

                    record.Status__c = 'Success';
                    record.Error__c = null;
                    record.SFDC_ID__c = destinationRecord.Id;
                } else {
                    record.Status__c = 'Failure';
                    record.Error__c = 'HTTP error: ' + res.getStatus() + ' - ' + res.getBody();
                    recordsToUpdate.add(record);
                }

            } catch (Exception ex) {
                record.Status__c = 'Failure';
                record.Error__c = ex.getMessage().substring(0, Math.min(255, ex.getMessage().length()));
                recordsToUpdate.add(record);
            }
        }

        // Optionally link to Contact if Candidate_ID__c matched a Contact by Legacy_BH_ID__c
        List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();

        if (!contentToInsert.isEmpty()) {
            insert contentToInsert;

            List<ContentVersion> insertedVersions = [
                SELECT Id, ContentDocumentId, Legacy_BH_ID__c
                FROM ContentVersion
                WHERE Id IN :contentToInsert
            ];

            for (ContentVersion version : insertedVersions) {
                if (fileIDToDataLoad.containsKey(version.Legacy_BH_ID__c)) {
                    Data_Load_Resume__c resumeRecord = fileIDToDataLoad.get(version.Legacy_BH_ID__c);
                    resumeRecord.Content_ID__c = version.ContentDocumentId;
                    recordsToUpdate.add(resumeRecord);

                    Contact contact = mpContacts.get(resumeRecord.Candidate_ID__c);
                    if (contact != null) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = version.ContentDocumentId;
                        cdl.LinkedEntityId = contact.Id;
                        cdl.ShareType = 'V';
                        lstContentDocumentLink.add(cdl);
                    }
                }
            }
        }

        if (!lstContentDocumentLink.isEmpty()) {
            // insert lstContentDocumentLink; // uncomment if you want to link Content to Contact
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    // ---------- Utilities ----------
    public Map<String, SObject> queryExistingID(Set<String> sourceIDs, String destination) {
        String query =
            'SELECT Id, Legacy_BH_ID__c FROM ' + destination +
            ' WHERE Legacy_BH_ID__c IN :sourceIDs AND Legacy_BH_ID__c != null';
        List<SObject> lstObject = Database.query(query);

        Map<String, SObject> mp = new Map<String, SObject>();
        for (SObject sObj : lstObject) {
            mp.put(String.valueOf(sObj.get('Legacy_BH_ID__c')), sObj);
        }
        return mp;
    }

    public Map<String, Contact> queryAllContacts(List<Data_Load_Resume__c> scope) {
        Map<String, Contact> mp = new Map<String, Contact>();
        for (Data_Load_Resume__c resume : scope) {
            if (resume.Candidate_ID__c != null) {
                mp.put(resume.Candidate_ID__c, null);
            }
        }
        for (Contact contact : [
            SELECT Id, Legacy_BH_ID__c
            FROM Contact
            WHERE Legacy_BH_ID__c IN :mp.keySet()
        ]) {
            mp.put(contact.Legacy_BH_ID__c, contact);
        }
        return mp;
    }

    // Backward-compatible helper (no extra trailing space)
    public static String encodeS3Path(String path) {
        return encodeS3Path(path, false);
    }

    // NEW: Overload that can append one extra trailing space (%20) to the final URL path
    public static String encodeS3Path(String path, Boolean appendTrailingSpace) {
        // Encode
        String encoded = EncodingUtil.urlEncode(path, 'UTF-8');

        // Normalize for S3 canonical URI
        encoded = encoded
            .replace('%2F', '/')   // keep slashes as separators
            .replace('+', '%20')   // spaces as %20 (never '+')
            .replace('%7E', '~');  // tilde as ~ (unreserved)

        // IMPORTANT: Do NOT unescape %24 to '$' — leave %24 (SigV4 expects it encoded)
        // encoded = encoded.replace('%24', '$');

        // If requested, append exactly one extra trailing space (as %20) to survive SFDC trimming
        if (appendTrailingSpace) {
            encoded += '%20';
        }
        return encoded;
    }

    public DateTime ParseDate(String rawDateTime) {
        return coerceSourceDateTime(rawDateTime);
    }

    // Parse to DateTime while preserving time; accepts ISO-like strings (e.g., 2023-08-30T20:09:14.527Z)
    public static Datetime coerceSourceDateTime(Object val) {
        if (val == null) return System.now();
        try {
            if (val instanceof Datetime) return (Datetime)val;
            if (val instanceof Date)     return Datetime.newInstance((Date)val, Time.newInstance(0, 0, 0, 0));
            String s = String.valueOf(val).trim();
            s = s.replace('T', ' ');
            Integer dot = s.indexOf('.');
            if (dot > 0) s = s.substring(0, dot); // drop fractional seconds
            if (s.endsWith('Z')) s = s.substring(0, s.length() - 1);
            Integer plus = s.lastIndexOf('+');
            Integer minus = s.lastIndexOf('-');
            Integer tzIdx = (plus > 10) ? plus : ((minus > 10) ? minus : -1); // ignore date dashes
            if (tzIdx > 10) s = s.substring(0, tzIdx);
            if (s.length() == 10) s += ' 00:00:00';
            return Datetime.valueOf(s);
        } catch (Exception e) {
            return System.now();
        }
    }

    private String extractFileName(String path) {
        if (String.isBlank(path)) return 'unknown_file';
        List<String> parts = path.split('/');
        return parts.isEmpty() ? 'file_from_s3' : parts[parts.size() - 1];
    }
}