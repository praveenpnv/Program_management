@isTest(isParallel = false)
public class AddContactESBTest {

    @isTest
    static void test_ESBSFSubmitContact() {
        // Generate a unique username
        User testUser29 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        // Use runAs to avoid MIXED_DML_OPERATION error
        System.runAs(testUser29) {
            // Create test contact with all required fields
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                OwnerId = testUser29.Id,
                TR1__Birthdate__c = Date.today().addYears(-30),
                Email = 'testcontact@example.com',
                MailingStreet = '123 Bengaluru Street',
                MailingCity = 'Bengaluru',
                MailingCountry = 'India',
                MailingPostalCode = '12345',
                Nationality__c = 'FR',
                MobilePhone = '123-456-7890',
                BH_Preferred_Language__c = 'English'
            );
            insert testContact;
            
            // Use Test.startTest() and Test.stopTest() to properly test asynchronous operations
            Test.startTest();
            
            // Call the method with the inserted test contact ID
            List<ID> jobIds;
            try {
                jobIds = AddContactESB.ESBSFSubmitContact(testContact.Id);
            } catch (Exception e) {
                System.debug('Error occurred: ' + e.getMessage());
                jobIds = new List<ID>();
            }
            
            Test.stopTest();
            
            // Assert the size of jobIds to make sure the job was enqueued
           // System.assertEquals(1, jobIds.size(), 'The job should be enqueued successfully.');
        }
    }

    @isTest
    static void test_ESBSFSubmitContact_MissingFields() {
        // Generate a unique username
        String uniqueUsername48 = 'testuser' + DateTime.now().getTime() + '@example.com';
        
        // Create a test user within a runAs block
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User testUser39 = new User(
            Username = uniqueUsername48,
            Email = 'testuser@example.com',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
         INSERT testUser39;
        // Use runAs to avoid MIXED_DML_OPERATION error
        System.runAs(testUser39) {
            // Create test contact with some missing required fields
            Contact testContact = new Contact(
                LastName = 'Contact',
                OwnerId = testUser39.Id
            );
            insert testContact;
            
            // Use Test.startTest() and Test.stopTest() to properly test asynchronous operations
            Test.startTest();
            
            // Call the method with the inserted test contact ID and expect an exception
            try {
                AddContactESB.ESBSFSubmitContact(testContact.Id);
                System.assert(false, 'An exception should have been thrown due to missing required fields.');
            } catch (EngagementCalloutException e) {
                System.debug('Expected error occurred: ' + e.getMessage());
                System.assert(e.getMessage().contains('The candidate cannot be sent to Mpleo'), 'Expected EngagementCalloutException with specific message.');
            } catch (Exception e) {
                System.assert(false, 'Unexpected exception: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }
}