@isTest(isParallel = false)
public class EmailSenderTest {

    // Helper method to create a user
    private static User createUser(String username, String firstName, String opco) {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        return new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = firstName,
            Email = username + '@example.com',
            Username = username + '@example.com',
            Alias = 'aduser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true,
            Opco__c = opco
        );
    }

    // Helper method to create common test data
    private static void createTestData() {
        // Insert EmailTemplate
        EmailTemplate testTemplate = new EmailTemplate(
            Name = 'Application ChangePoint Id request',
            DeveloperName = 'Application_ChangePoint_Id_request',
            FolderId = UserInfo.getUserId(),
            HtmlValue = 'Test Email Body with {!Account.Name}',
            Subject = 'Please create/add a new Changepoint ID: {!Account.Name}',
            TemplateType = 'Custom',
            IsActive = true
        );
        insert testTemplate;
    }

    // Helper method to create an account
    private static Account createAccount() {
        return new Account(
            Name = 'Test Account',
            BH_VAT_Number__c = '29GGGGG1314R9Z6',
            AUSY_Changepoint_ID__c = 'CP123',
            BillingCountry = 'India',
            Industry = 'Public Sector'
        );
    }

    @testSetup
    static void setupEmailConfig() {
        // Query RD1_Settings__mdt (in a separate transaction)
        RD1_Settings__mdt emailConfig = [SELECT Recipient_Email_Belux__c,Recipient_Email_France__c,Recipient_Email_Other__c
                                         FROM RD1_Settings__mdt LIMIT 1];
    	}

    @isTest
    static void testSendEmail_Success_Belux() {
        // Generate a unique username
        String uniqueUsername = 'testuser1' + DateTime.now().getTime();
        // Create a system admin user to run the test as admin
        User testUser = createUser(uniqueUsername, 'TestAdmin', 'Belux');
        system.debug('testUser' + testUser);
        insert testUser;

        // Create common test data
        createTestData();

        // Run the test as the system admin user
        System.runAs(testUser) {
            // Create a test account within the admin context
            Account testAccount = createAccount();
            insert testAccount;

            // Start test context for email sending
            Test.startTest();

            // Call the method to send email
            EmailSender.sendEmail(
                testAccount.Id,
                'Test Invoicing Name',
                'Test Payment Terms',
                'Test Graydon Rating',
                'Test Contact Person',
                'Test Comment'
            );

            Test.stopTest();
            List<EmailMessage> sentEmails = [SELECT Subject, HtmlBody FROM EmailMessage];
            system.debug('sentEmails_Belux ' + sentEmails);
        }
    }

    @isTest
    static void testSendEmail_Success_France() {
        // Generate a unique username
        String uniqueUsername = 'testuser2' + DateTime.now().getTime();
        // Create a system admin user to run the test as admin
        User testUser = createUser(uniqueUsername, 'TestAdmin1', 'France');
        insert testUser;

        // Create common test data
        createTestData();

        // Run the test as the system admin user
        System.runAs(testUser) {
            // Create a test account within the admin context
            Account testAccount = createAccount();
            insert testAccount;

            // Start test context for email sending
            Test.startTest();

            // Call the method to send email
            EmailSender.sendEmail(
                testAccount.Id,
                'Test Invoicing Name',
                'Test Payment Terms',
                'Test Graydon Rating',
                'Test Contact Person',
                'Test Comment'
            );

            Test.stopTest();
            List<EmailMessage> sentEmails = [SELECT Subject, HtmlBody FROM EmailMessage];
            system.debug('sentEmails_France ' + sentEmails);
        }
    }

    @isTest
    static void testSendEmail_Success_US() {
        // Generate a unique username
        String uniqueUsername = 'testuser3' + DateTime.now().getTime();
        // Create a system admin user to run the test as admin
        User testUser = createUser(uniqueUsername, 'TestAdmin2', 'US');
        insert testUser;

        // Create common test data
        createTestData();

        // Run the test as the system admin user
        System.runAs(testUser) {
            // Create a test account within the admin context
            Account testAccount = createAccount();
            insert testAccount;

            // Start test context for email sending
            Test.startTest();

            // Call the method to send email
            EmailSender.sendEmail(
                testAccount.Id,
                'Test Invoicing Name',
                'Test Payment Terms',
                'Test Graydon Rating',
                'Test Contact Person',
                'Test Comment'
            );

            Test.stopTest();
            List<EmailMessage> sentEmails = [SELECT Subject, HtmlBody FROM EmailMessage];
            system.debug('sentEmails_US ' + sentEmails);
        }
    }

    @isTest
    static void testSendEmail_NullAccount() {
        // Generate a unique username
        String uniqueUsername = 'testuser4' + DateTime.now().getTime();
        // Create a system admin user to run the test as admin
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            ProfileId = adminProfile.Id,
            LastName = 'AdminUser',
            FirstName = 'TestAdmin',
            Email = uniqueUsername + '@example.com',
            Username = uniqueUsername+ '@example.com',
            Alias = 'aduser2',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Bypass_VR__c = true
        );
        insert testUser;

        // Run the test as the system admin user
        System.runAs(testUser) {
            // Start test context
            Test.startTest();

            // Call the method with a null account ID
            EmailSender.sendEmail(
                null,
                'Test Invoicing Name',
                'Test Payment Terms',
                'Test Graydon Rating',
                'Test Contact Person',
                'Test Comment'
            );

            Test.stopTest();

            // Verify that no email was sent
            List<EmailMessage> sentEmails = [SELECT Subject, HtmlBody FROM EmailMessage];
            system.debug('sentEmails_Null ' + sentEmails);
        }
    }
}