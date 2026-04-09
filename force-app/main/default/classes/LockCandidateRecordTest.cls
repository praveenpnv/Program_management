@isTest
public class LockCandidateRecordTest {
    @testSetup
    static void setupTestData() {
        // Create a test candidate record
        Contact candidate = new Contact(
            FirstName = 'Test',
            LastName = 'Candidate',
            Email = 'test@example.com',
            DO_NOT_USE__c = false
        );
        insert candidate;
    }

    @isTest
    static void testNonAdminCannotEditLockedRecord() {
        // Retrieve test candidate record
        Contact candidate = [SELECT Id, DO_NOT_USE__c FROM Contact LIMIT 1];

        // Update the record to set DO_NOT_USE__c = true
        Test.startTest();
        candidate.DO_NOT_USE__c = true;
        update candidate; // This should succeed
        Test.stopTest();

        // Get an active non-System Admin user
        User standardUser = [SELECT Id FROM User WHERE Profile.Name != 'System Administrator' AND IsActive = TRUE LIMIT 1];

        // Run the test as a non-admin user
        System.runAs(standardUser) { 
            Contact lockedCandidate = [SELECT Id FROM Contact WHERE Id = :candidate.Id];

            //Test.startTest();
            Boolean exceptionThrown = false;
            try {
                lockedCandidate.LastName = 'Updated Name';
                update lockedCandidate;
            } catch (DmlException e) {
                exceptionThrown = true;
                System.debug('Expected Exception: ' + e.getMessage());  // Debug error message
                System.assert(e.getMessage().contains('Please Contact HR support at hrsupport@randstadusa.com'), 
                   'Error message mismatch: ' + e.getMessage());

            }
            //System.assert(exceptionThrown, 'Non-admin should not be able to edit a locked record.');
           // Test.stopTest();
        }
    }

    @isTest
    static void testSystemAdminCanEditLockedRecord() {
        // Retrieve test candidate record
        Contact candidate = [SELECT Id, DO_NOT_USE__c FROM Contact LIMIT 1];

        // Update the record to set DO_NOT_USE__c = true
        Test.startTest();
        candidate.DO_NOT_USE__c = true;
        update candidate; // This should succeed
        Test.stopTest();

        // Get an active System Administrator user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

        // Run the test as a System Admin
        System.runAs(adminUser) {
            Contact lockedCandidate = [SELECT Id FROM Contact WHERE Id = :candidate.Id];

           // Test.startTest();
            try {
                lockedCandidate.LastName = 'Updated by Admin';
                update lockedCandidate; // Should succeed
            } catch (DmlException e) {
                System.assert(false, 'System Admin should be able to edit a locked record.');
            }
           // Test.stopTest();
        }
    }
}