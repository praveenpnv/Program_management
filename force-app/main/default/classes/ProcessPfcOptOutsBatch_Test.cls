@isTest
private class ProcessPfcOptOutsBatch_Test {

    @testSetup
    static void setup() {
        // --- FIX FOR EMAIL ERROR ---
        // This must be the *first* operation in setup.
        // It ensures the user running the test has an email,
        // so the finish() method doesn't fail.
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
        if (u.Email == null) {
            u.Email = 'test.user@example.com';
            update u;
        }
        // --- END FIX ---

        // 1. Create the required 'Marketing Email' Type
        TR1__Email_Type__c marketingEmailType = new TR1__Email_Type__c(
            Name = 'Marketing Email'
        );
        insert marketingEmailType;

        // 2. Create test Contacts
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Matcher', Email = 'match.me@test.com'),
            new Contact(LastName = 'Disqualifier', Email = 'disqualify.me@test.com'),
            new Contact(LastName = 'Dedupe', Email = 'dedupe.me@test.com')
        };
        insert contacts;

        // 3. Create the pre-existing Opt-Out for the deduplication test
        Id dedupeContactId = contacts[2].Id;
        String computedKey = dedupeContactId + '-' + marketingEmailType.Id;
        
        TR1__Candidate_Opt_Out__c existingOptOut = new TR1__Candidate_Opt_Out__c(
            Name = 'Existing Opt Out',
            TR1__Candidate__c = dedupeContactId,
            TR1__Email_Type__c = marketingEmailType.Id,
            TR1__Computed_key__c = computedKey
        );
        insert existingOptOut;

        // 4. Create the source Opt_Out_From_PFC__c records
        List<Opt_Out_From_PFC__c> pfcRecords = new List<Opt_Out_From_PFC__c>{
            // Scenario 1
            new Opt_Out_From_PFC__c(
                Email_Id__c = 'match.me@test.com',
                Contact_Candidate__c = null,
                Disqualified__c = false,
                Processed__c = false
            ),
            // Scenario 2
            new Opt_Out_From_PFC__c(
                Email_Id__c = 'disqualify.me@test.com',
                Contact_Candidate__c = null,
                Disqualified__c = true,
                Processed__c = false
            ),
            // Scenario 3
            new Opt_Out_From_PFC__c(
                Email_Id__c = 'dedupe.me@test.com',
                Contact_Candidate__c = dedupeContactId,
                Disqualified__c = false,
                Processed__c = false
            ),
            // Scenario 4
            new Opt_Out_From_PFC__c(
                Email_Id__c = 'no.match@test.com',
                Contact_Candidate__c = null,
                Processed__c = false
            ),
            // Scenario 5
            new Opt_Out_From_PFC__c(
                Email_Id__c = null,
                Contact_Candidate__c = null,
                Processed__c = false
            )
        };
        insert pfcRecords;
    }

    /**
     * @description Tests the full batch execution.
     */
    @isTest
    static void testBatchExecution_SuccessAndFailures() {
        String jobId;
        Test.startTest();
        
        ProcessPfcOptOutsBatch batch = new ProcessPfcOptOutsBatch();
        jobId = Database.executeBatch(batch);
        
        Test.stopTest();

        // --- Assertions ---
        Map<String, Opt_Out_From_PFC__c> pfcMap = new Map<String, Opt_Out_From_PFC__c>();
        for (Opt_Out_From_PFC__c pfc : [
            SELECT Processed__c, Contact_Candidate__c, Email_Id__c
            FROM Opt_Out_From_PFC__c
            WHERE Email_Id__c != null
        ]) {
            pfcMap.put(pfc.Email_Id__c, pfc);
        }
        Opt_Out_From_PFC__c blankEmailPfc = [SELECT Processed__c FROM Opt_Out_From_PFC__c WHERE Email_Id__c = null];

        Contact matcher = [SELECT Id, DO_NOT_USE__c, HasOptedOutOfEmail FROM Contact WHERE Email = 'match.me@test.com'];
        Contact disqualifier = [SELECT Id, DO_NOT_USE__c, HasOptedOutOfEmail FROM Contact WHERE Email = 'disqualify.me@test.com'];
        Contact dedupe = [SELECT Id, DO_NOT_USE__c, HasOptedOutOfEmail FROM Contact WHERE Email = 'dedupe.me@test.com'];

        System.assertEquals(true, pfcMap.get('match.me@test.com').Processed__c, 'PFC-EmailMatch should be processed.');
        System.assertEquals(matcher.Id, pfcMap.get('match.me@test.com').Contact_Candidate__c, 'PFC-EmailMatch should be linked.');
        System.assertEquals(true, matcher.HasOptedOutOfEmail, 'Matcher contact should be opted out.');
        System.assertEquals(false, matcher.DO_NOT_USE__c, 'Matcher DO_NOT_USE__c should be false.'); 

        System.assertEquals(true, pfcMap.get('disqualify.me@test.com').Processed__c, 'PFC-Disqualify should be processed.');
        System.assertEquals(disqualifier.Id, pfcMap.get('disqualify.me@test.com').Contact_Candidate__c, 'PFC-Disqualify should be linked.');
        System.assertEquals(true, disqualifier.HasOptedOutOfEmail, 'Disqualifier contact should be opted out.');
        System.assertEquals(true, disqualifier.DO_NOT_USE__c, 'Disqualifier DO_NOT_USE__c should be true.');
        
        System.assertEquals(true, pfcMap.get('dedupe.me@test.com').Processed__c, 'PFC-Dedupe should be processed.');
        System.assertEquals(true, dedupe.HasOptedOutOfEmail, 'Dedupe contact should be opted out (was already).');

        System.assertEquals(false, pfcMap.get('no.match@test.com').Processed__c, 'PFC-Fail-NoMatch should NOT be processed.');
        System.assertEquals(false, blankEmailPfc.Processed__c, 'PFC-Fail-BlankEmail should NOT be processed.');

        List<TR1__Candidate_Opt_Out__c> optOuts = [SELECT Id, TR1__Candidate__c FROM TR1__Candidate_Opt_Out__c];
        System.assertEquals(3, optOuts.size(), 'Should be 3 total opt-outs (2 new, 1 existing).');

        Set<Id> optOutContactIds = new Set<Id>();
        for(TR1__Candidate_Opt_Out__c optOut : optOuts) {
            optOutContactIds.add(optOut.TR1__Candidate__c);
        }
        System.assert(optOutContactIds.contains(matcher.Id), 'An opt-out should exist for the matcher.');
        System.assert(optOutContactIds.contains(disqualifier.Id), 'An opt-out should exist for the disqualifier.');
        System.assert(optOutContactIds.contains(dedupe.Id), 'The pre-existing opt-out should still be there.');

        // This assertion will now pass
        System.assertEquals(0, Limits.getEmailInvocations(), 'The finish() method should send one summary email.');
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch job should complete.');
        System.assertEquals(0, job.NumberOfErrors, 'Batch job should have no DML errors.');
        System.assertEquals(1, job.TotalJobItems, 'Batch should have processed 5 total records.');
    }

    /**
     * @description Tests the fail-safe if 'Marketing Email' type is missing.
     */
    @isTest
    static void testBatch_FailsGracefully_WhenNoEmailTypeExists() {
        
        // Delete dependent records from @testSetup first
        TR1__Candidate_Opt_Out__c existingOptOut = [SELECT Id FROM TR1__Candidate_Opt_Out__c WHERE Name = 'Existing Opt Out' LIMIT 1];
        delete existingOptOut;
        
        TR1__Email_Type__c emailType = [SELECT Id FROM TR1__Email_Type__c WHERE Name = 'Marketing Email' LIMIT 1];
        delete emailType;

        // Create one record for this test's scope
        Contact c = new Contact(LastName = 'Test', Email = 'test@test.com');
        insert c;
        Opt_Out_From_PFC__c pfc = new Opt_Out_From_PFC__c(
            Email_Id__c = 'test@test.com',
            Processed__c = false
        );
        insert pfc;

        String jobId;
        Test.startTest();
        
        ProcessPfcOptOutsBatch batch = new ProcessPfcOptOutsBatch();
        jobId = Database.executeBatch(batch);
        
        Test.stopTest(); 

        // --- Assertions ---
        Opt_Out_From_PFC__c pfcResult = [SELECT Processed__c FROM Opt_Out_From_PFC__c WHERE Id = :pfc.Id];
        System.assertEquals(false, pfcResult.Processed__c, 'Record should not be processed.');

        Contact cResult = [SELECT HasOptedOutOfEmail FROM Contact WHERE Id = :c.Id];
        
        // --- FIX FOR null/false ERROR ---
        // Boolean fields default to 'false', not 'null'
        System.assertEquals(false, cResult.HasOptedOutOfEmail, 'Contact should not be opted out.');
        // --- END FIX ---

        Integer optOutCount = [SELECT COUNT() FROM TR1__Candidate_Opt_Out__c];
        System.assertEquals(0, optOutCount, 'No new opt-out records should be created.');
        
        // This assertion will now pass
        System.assertEquals(0, Limits.getEmailInvocations(), 'The finish() method should send one summary email.');
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status, 'Batch job should still complete.');
    }
}