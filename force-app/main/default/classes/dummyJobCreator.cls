public class dummyJobCreator {

    public static void run() {

        // ===============================
        // REFERENCE REGIONS
        // ===============================
        Region__c norCal   = [SELECT Id FROM Region__c WHERE Region_Label__c='Northern California' LIMIT 1];
        Region__c soCal    = [SELECT Id FROM Region__c WHERE Region_Label__c='Southern California' LIMIT 1];
        Region__c pnw      = [SELECT Id FROM Region__c WHERE Region_Label__c='Pacific Northwest' LIMIT 1];
        Region__c texas    = [SELECT Id FROM Region__c WHERE Region_Label__c='Texas Region' LIMIT 1];
        Region__c arizona  = [SELECT Id FROM Region__c WHERE Region_Label__c='Arizona Region' LIMIT 1];

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        List<TR1__Job__c> jobs = new List<TR1__Job__c>();
        String st;

        // ===============================
        // NORTHERN CALIFORNIA
        // ===============================
        for (Integer i = 1; i <= 22; i++) {
            st = i <= 12 ? 'Accepting Candidates'
               : i <= 16 ? 'On Hold'
               : i <= 20 ? 'Declined'
               : 'Closed';

            jobs.add(buildJob(
                'Job - NorCal - ' + i,
                norCal.Id, st, acc.Id, con.Id,
                i <= 8 ? 'P1' : i <= 15 ? 'P2' : 'P3',
                Date.today().addDays(i - 12),
                'Permanent',
                'Cloud'
            ));
        }

        // ===============================
        // SOUTHERN CALIFORNIA
        // ===============================
        for (Integer i = 1; i <= 14; i++) {
            st = i <= 8 ? 'Accepting Candidates'
               : i <= 12 ? 'Placed'
               : 'Closed';

            jobs.add(buildJob(
                'Job - SoCal - ' + i,
                soCal.Id, st, acc.Id, con.Id,
                i <= 4 ? 'P1' : 'P2',
                Date.today().addDays(i),
                'Permanent',
                'Customer Experience'
            ));
        }

        // ===============================
        // PACIFIC NORTHWEST
        // ===============================
        for (Integer i = 1; i <= 6; i++) {
            st = i <= 4 ? 'Accepting Candidates' : 'On Hold';

            jobs.add(buildJob(
                'Job - PNW - ' + i,
                pnw.Id, st, acc.Id, con.Id,
                i == 1 ? 'P1' : 'P3',
                Date.today().addDays(i + 5),
                'Permanent',
                'Data & Analytics'
            ));
        }

        // ===============================
        // TEXAS
        // ===============================
        for (Integer i = 1; i <= 30; i++) {
            st = i <= 18 ? 'Accepting Candidates'
               : i <= 24 ? 'Declined'
               : i <= 28 ? 'On Hold'
               : 'Archive';

            jobs.add(buildJob(
                'Job - Texas - ' + i,
                texas.Id, st, acc.Id, con.Id,
                i <= 10 ? 'P1' : i <= 20 ? 'P2' : 'P3',
                Date.today().addDays(i - 20),
                'Contract',
                'Digital & Product Engineering'
            ));
        }

        // ===============================
        // ARIZONA
        // ===============================
        for (Integer i = 1; i <= 10; i++) {
            st = i <= 5 ? 'Accepting Candidates'
               : i <= 7 ? 'On Hold'
               : 'Unqualified';

            jobs.add(buildJob(
                'Job - Arizona - ' + i,
                arizona.Id, st, acc.Id, con.Id,
                i <= 3 ? 'P2' : 'P3',
                Date.today().addDays(i + 10),
                'Permanent',
                'Customer Experience'
            ));
        }

        // ===============================
        // INSERT
        // ===============================
        insert jobs;
        System.debug('Inserted TR1__Job__c records: ' + jobs.size());
    }

    // ==================================================
    // HELPER METHOD — ALL VALIDATIONS HANDLED
    // ==================================================
    private static TR1__Job__c buildJob(
        String name,
        Id regionId,
        String status,
        Id accId,
        Id conId,
        String priority,
        Date expiryDate,
        String jobType,
        String serviceLine
    ) {
        return new TR1__Job__c(
            Name = name,
            Region__c = regionId,
            TR1__Status__c = status,

            // ===== Financials =====
            TR1__Maximum_Bill_Rate__c = (status == 'Accepting Candidates' ? 100 : null),
            TR1__Maximum_Pay_Rate__c  = (status == 'Accepting Candidates' ? 70 : null),
            Calculated_GP__c          = (status == 'Accepting Candidates' ? 500 : null),

            // ===== Eligibility =====
            Education_Requirements__c =
                (status == 'Accepting Candidates' ? 'Bachelors' : null),

            Independent_Contractors_Allowed__c =
                (status == 'Accepting Candidates' ? 'Yes' : 'No'),

            RITS_Talent_Allowed__c =
                (status == 'Accepting Candidates' ? 'Yes' : 'No'),

            Interview_Info__c =
                (status == 'Accepting Candidates' ? 'Phone to Hire' : null),

            // ===== Dates =====
            TR1__Estimated_Start_Date__c =
                (status == 'Accepting Candidates' ? Date.today().addDays(14) : null),

            TR1__Estimated_End_Date__c =
                (status == 'Accepting Candidates' ? Date.today().addMonths(6) : null),

            // ===== Worksite Address (STANDARD / MANAGED ADDRESS FIELD) =====
            Worksite_Address__Street__s =
                (status == 'Accepting Candidates' ? '123 Market Street' : null),

            Worksite_Address__City__s =
                (status == 'Accepting Candidates' ? 'San Francisco' : null),

            Worksite_Address__StateCode__s =
                (status == 'Accepting Candidates' ? 'CA' : null),

            Worksite_Address__PostalCode__s =
                (status == 'Accepting Candidates' ? '94105' : null),

            Worksite_Address__CountryCode__s =
                (status == 'Accepting Candidates' ? 'US' : null),

            // ===== Always required =====
            Job_Priority__c = priority,
            Job_Expiry_Date__c = expiryDate,
            TR1__Client_Job_Description__c = 'POC Job Description',
            Publishing_Status__c = 'Not Published',
            Job_Type__c = jobType,
            Source__c = 'Direct Manager',
            Service_line_job__c = serviceLine,
            Account__c = accId,
            TR1__Contact__c = conId
        );
    }
}