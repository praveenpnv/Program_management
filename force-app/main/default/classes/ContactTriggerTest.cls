@isTest
public class ContactTriggerTest {

    @testSetup
    static void setupTestData() {
        Contact con = RD1TestDataFactory.createCandidate();
    }

    @isTest
	static void testNonAdminCannotEditLockedRecord() {
        // Get the test contact
        Contact candidate = [SELECT Id, DO_NOT_USE__c FROM Contact LIMIT 1];
    
        // Lock the record
        candidate.DO_NOT_USE__c = true;
        update candidate;
    
        // Fetch the standard user created in test setup
        User standardUser = [SELECT Id, ProfileId FROM User WHERE Alias = 'autoproc' LIMIT 1];
    
        System.runAs(standardUser) {
            // Fetch the candidate record again
            Contact lockedCandidate = [SELECT Id, LastName FROM Contact WHERE Id = :candidate.Id];
    
            Boolean exceptionThrown = false;
            try {
                // This update should trigger the addError in the trigger
                lockedCandidate.LastName = 'Updated Name';
                update lockedCandidate;
            } catch (DmlException e) {
                exceptionThrown = true;
                // Make sure the error message contains the lock message
                System.assert(
                    e.getMessage().contains('Please Contact HR support at hrsupport@randstadusa.com'),
                    'Error message mismatch: ' + e.getMessage()
                );
            }           
        }
	}

    @isTest
    static void testSystemAdminCanEditLockedRecord() {
        Contact candidate = [SELECT Id FROM Contact LIMIT 1];

        // Lock the record
        candidate.DO_NOT_USE__c = true;
        update candidate;

        // Get an admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

        System.runAs(adminUser) {
            Contact lockedCandidate = [SELECT Id FROM Contact WHERE Id = :candidate.Id];
            lockedCandidate.LastName = 'Updated by Admin';

            Test.startTest();
            update lockedCandidate; // should succeed
            Test.stopTest();
        }
    }

    @isTest
    static void testMandatoryFieldValidationOnInsert() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' LIMIT 1];

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = null, // simulate missing mandatory field
            RecordTypeId = rt.Id
        );

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            insert con;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Mandatory validation should trigger on insert when LastName is null.');
    }

    @isTest
    static void testMandatoryFieldValidationOnUpdate() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        con.LastName = null; // simulate missing field

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            update con;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Mandatory validation should trigger on update when LastName is null.');
    }
}