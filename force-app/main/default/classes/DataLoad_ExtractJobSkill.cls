//
// DataLoad_ExtractJobSkill
// - Batch over Data_Load_Legacy_Skill__c where Process_Status__c = NULL
// - For each marker, load related TR1__Job__c, extract skills via Textkernel
// - Create TR1__Skills__c rows (deduped), lookup TR1__Master_Skill__c by TR1__Skill_Code__c
// - Update marker: Process_Status__c = Success/Failure, Error__c on failure
// - Supports dynamic LIMIT (pass -1 for no limit)
//
public class DataLoad_ExtractJobSkill implements Database.Batchable<SObject>, Database.AllowsCallouts
{
    // ---- config ----
    private final String srcField;     // e.g., 'TR1__Client_Job_Description__c'
    private final Integer maxLimit;    // -1 => no LIMIT

    // API path (relative to Named Credential)
    private static final String PATH = '/tx/v10/skills/extract';
    private static final String DEFAULT_NAMED_CRED = 'TextKernelEU';

    // Back-compat constructor (ignores where-clause per new design)
    public DataLoad_ExtractJobSkill(String sourceFieldApiName) {
        this(sourceFieldApiName, -1);
    }
    // Constructor with LIMIT
    public DataLoad_ExtractJobSkill(String sourceFieldApiName, Integer maxRecords) {
        this.srcField  = sourceFieldApiName;
        this.maxLimit  = (maxRecords == null ? -1 : maxRecords);
    }

    // ---- Batchable ----
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Pick unprocessed markers; LIMIT if requested
        String q = 'SELECT Id, Job__c FROM Data_Load_Legacy_Skill__c ' +
                   'WHERE Process_Status__c = NULL';
        if (maxLimit != null && maxLimit > 0) q += ' LIMIT ' + String.valueOf(maxLimit);
        return Database.getQueryLocator(q);
    }

    public void execute(Database.BatchableContext bc, List<Data_Load_Legacy_Skill__c> scope) {
        if (scope.isEmpty()) return;

        // Gather Job ids, fetch jobs with source field
        Set<Id> jobIds = new Set<Id>();
        for (Data_Load_Legacy_Skill__c m : scope) if (m.Job__c != null) jobIds.add(m.Job__c);

        Map<Id, TR1__Job__c> jobsById = new Map<Id, TR1__Job__c>();
        if (!jobIds.isEmpty()) {
            String q = 'SELECT Id,' + srcField + ' FROM TR1__Job__c WHERE Id IN :jobIds';
            for (TR1__Job__c j : Database.query(q)) jobsById.put(j.Id, j);
        }

        // Process each marker individually to capture success/failure per record
        List<Data_Load_Legacy_Skill__c> updates = new List<Data_Load_Legacy_Skill__c>();

        for (Data_Load_Legacy_Skill__c marker : scope) {
            String errMsg;
            Boolean ok = true;

            try {
                TR1__Job__c job = (marker.Job__c == null) ? null : jobsById.get(marker.Job__c);
                if (job == null) {
                    ok = false;
                    errMsg = 'Related Job not found.';
                } else {
                    ProcessSummary sum = processJobsReturningSummary(new List<TR1__Job__c>{ job }, srcField, DEFAULT_NAMED_CRED);
                    if (!sum.errors.isEmpty()) {
                        ok = false;
                        errMsg = String.join(sum.errors, '\n');
                    }
                }
            } catch (Exception e) {
                ok = false;
                errMsg = e.getMessage();
            }

            Data_Load_Legacy_Skill__c upd = new Data_Load_Legacy_Skill__c(
                Id = marker.Id,
                Process_Status__c = ok ? 'Success' : 'Failure',
                Error__c = ok ? null : errMsg
            );
            updates.add(upd);
        }

        if (!updates.isEmpty()) Database.update(updates, false);
    }

    public void finish(Database.BatchableContext bc) {
        // optional: summary/notifications
    }

    // =========================
    // Public utility entry points (unchanged semantics)
    // =========================
    public static void extractAndStoreSkillsForJobIds(Set<Id> jobIds, String sourceFieldApiName) {
        if (jobIds == null || jobIds.isEmpty()) return;
        String q = 'SELECT Id,' + sourceFieldApiName + ' FROM TR1__Job__c WHERE Id IN :jobIds';
        List<TR1__Job__c> jobs = Database.query(q);
        // fire-and-forget; ignore the summary
        processJobsReturningSummary(jobs, sourceFieldApiName, DEFAULT_NAMED_CRED);
    }

    public static void extractAndStoreSkillsForJobs(List<TR1__Job__c> jobs, String sourceFieldApiName) {
        // fire-and-forget; ignore the summary
        processJobsReturningSummary(jobs, sourceFieldApiName, DEFAULT_NAMED_CRED);
    }

    // =========================
    // Core implementation (returns summary so batch can set Success/Failure)
    // =========================
    private class ProcessSummary {
        public Integer inserted = 0;
        public List<String> errors = new List<String>();
    }

    private static ProcessSummary processJobsReturningSummary(
        List<TR1__Job__c> jobs,
        String sourceFieldApiName,
        String namedCredential
    ) {
        ProcessSummary summary = new ProcessSummary();
        if (jobs == null || jobs.isEmpty()) return summary;

        Map<String, TR1__Skills__c> planned = new Map<String, TR1__Skills__c>();
        Set<Id> jobIds = new Set<Id>();
        Set<String> allSkillCodes = new Set<String>(); // for master lookup

        // 1) Call Textkernel per Job and stage inserts
        for (TR1__Job__c job : jobs) {
            jobIds.add(job.Id);
            String text = (String) job.get(sourceFieldApiName);
            if (String.isBlank(text)) continue;

            List<ExtractedSkill> skills;
            try {
                skills = extractSkills(text, namedCredential);
            } catch (Exception e) {
                summary.errors.add('Job ' + job.Id + ': ' + e.getMessage());
                continue;
            }
            if (skills == null || skills.isEmpty()) continue;

            for (ExtractedSkill es : skills) {
                if (es == null || String.isBlank(es.name)) continue;

                String normCode = es.code == null ? null : es.code.trim().toLowerCase();
                String normName = es.name.trim().toLowerCase();
                String dedupeKey = job.Id + '|' + (String.isBlank(normCode) ? normName : normCode);

                if (!planned.containsKey(dedupeKey)) {
                    TR1__Skills__c row = new TR1__Skills__c();
                    row.TR1__Job__c = job.Id;
                    row.TR1__Source__c = 'Parser';
                    row.TR1__Extracted_Skill_Name__c = es.name.trim();
                    planned.put(dedupeKey, row);
                }
                if (!String.isBlank(es.code)) {
                    allSkillCodes.add(es.code); // keep original case for IN filter
                }
            }
        }
        if (planned.isEmpty()) return summary;

        // 2) De-dupe against existing TR1__Skills__c for these Jobs (by Extracted_Skill_Name__c)
        Set<String> namesPlanned = new Set<String>();
        for (TR1__Skills__c s : planned.values()) {
            if (s.TR1__Extracted_Skill_Name__c != null) namesPlanned.add(s.TR1__Extracted_Skill_Name__c);
        }

        Map<String, Boolean> exists = new Map<String, Boolean>();
        for (TR1__Skills__c ex : [
            SELECT Id, TR1__Job__c, TR1__Extracted_Skill_Name__c
            FROM TR1__Skills__c
            WHERE TR1__Job__c IN :jobIds
              AND TR1__Extracted_Skill_Name__c IN :namesPlanned
        ]) {
            String k = ex.TR1__Job__c + '|' +
                (ex.TR1__Extracted_Skill_Name__c == null ? '' : ex.TR1__Extracted_Skill_Name__c.toLowerCase());
            exists.put(k, true);
        }

        // 3) STRICT master lookup by TR1__Skill_Code__c only (no name fallback)
        Map<String, Id> masterByCodeLower = new Map<String, Id>();
        if (!allSkillCodes.isEmpty()) {
            for (TR1__Master_Skill__c ms : [
                SELECT Id, TR1__Skill_Code__c
                FROM TR1__Master_Skill__c
                WHERE TR1__Skill_Code__c IN :allSkillCodes
            ]) {
                if (ms.TR1__Skill_Code__c != null) {
                    masterByCodeLower.put(ms.TR1__Skill_Code__c.trim().toLowerCase(), ms.Id);
                }
            }
        }

        // 4) Stage inserts with lookup populated when found
        List<TR1__Skills__c> toInsert = new List<TR1__Skills__c>();
        for (String k : planned.keySet()) {
            if (exists.containsKey(k)) continue;

            TR1__Skills__c row = planned.get(k);
            Integer pipeIdx = k.lastIndexOf('|');
            String suffix = pipeIdx >= 0 ? k.substring(pipeIdx+1) : null; // lowercased code or name
            if (suffix != null && masterByCodeLower.containsKey(suffix)) {
                row.TR1__Master_Skill__c = masterByCodeLower.get(suffix);
            }
            toInsert.add(row);
        }
        if (toInsert.isEmpty()) return summary;

        Database.SaveResult[] sr = Database.insert(toInsert, false);
        for (Integer i = 0; i < sr.size(); i++) {
            if (sr[i].isSuccess()) {
                summary.inserted++;
            } else {
                for (Database.Error err : sr[i].getErrors()) {
                    summary.errors.add(
                        'Insert failed (Job=' + toInsert[i].TR1__Job__c +
                        ', Name=' + toInsert[i].TR1__Extracted_Skill_Name__c + '): ' + err.getMessage()
                    );
                }
            }
        }
        return summary;
    }

    // ---- Callout + minimal JSON parsing ----
    // Returns list of ExtractedSkill { code = Textkernel Skill Id, name = Description }
    public static List<ExtractedSkill> extractSkills(String text) {
        return extractSkills(text, DEFAULT_NAMED_CRED);
    }

    private static List<ExtractedSkill> extractSkills(String text, String namedCredential) {
        if (String.isBlank(text)) return new List<ExtractedSkill>();

        // 24,000 char cap
        final Integer MAX_CHARS = 24000;
        String sendText = (text.length() > MAX_CHARS) ? text.left(MAX_CHARS) : text;

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:' + namedCredential + PATH);
        req.setHeader('accept', 'text/plain');
        req.setHeader('Content-Type', 'application/json-patch+json');

        // per your instruction (no change)
        req.setHeader('Tx-AccountId', '{!$Credential.Username}');
        req.setHeader('Tx-ServiceKey', '{!$Credential.Password}');

        Map<String, Object> payload = new Map<String, Object>{
            'Text'           => sendText,
            'Language'       => 'en',
            'Threshold'      => 0.5,
            'OutputLanguage' => 'en'
        };
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        Integer code = res.getStatusCode();
        if (code < 200 || code >= 300) {
            System.debug(LoggingLevel.WARN, 'Textkernel non-2xx ' + code + ' body=' + res.getBody());
            throw new CalloutException('Textkernel returned HTTP ' + code);
        }

        // Keep your debug logs
        System.debug('******');
        System.debug(res.getBody());
        System.debug('*****');

        // Minimal typed parsing: only Value -> Skills -> (Id, Description)
        ResponseWrapper rw = (ResponseWrapper) JSON.deserialize(res.getBody(), ResponseWrapper.class);

        List<ExtractedSkill> out = new List<ExtractedSkill>();
        if (rw != null && rw.Value != null && rw.Value.Skills != null) {
            for (Skill sk : rw.Value.Skills) {
                if (sk == null) continue;
                if (!String.isBlank(sk.Description)) {
                    ExtractedSkill es = new ExtractedSkill();
                    es.name = sk.Description.trim();                  // display name
                    es.code = String.isBlank(sk.Id) ? null : sk.Id.trim(); // TK Skill Id
                    out.add(es);
                }
            }
        }
        return out;
    }

    // ==== Minimal JSON wrapper classes (only needed fields) ====
    public class ResponseWrapper { public ValueObj Value; }
    public class ValueObj { public List<Skill> Skills; }
    public class Skill {
        public String Id;           // Textkernel Skill Id -> TR1__Master_Skill__c.TR1__Skill_Code__c
        public String Description;  // Skill display name
    }

    // Helper DTO
    public class ExtractedSkill {
        public String code; // Textkernel Skill Id
        public String name; // Description
    }
}