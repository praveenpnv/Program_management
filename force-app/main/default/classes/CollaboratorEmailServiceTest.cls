@isTest
private class CollaboratorEmailServiceTest {

    @testSetup
    static void setupTestData() {
        // Create a test Profile to assign to a User, a common practice to avoid DML errors.
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        // Create test User. DML on a Setup object.
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;

        // Create a test Group, a Setup object, and a GroupMember
        Group testGroup = new Group(Name = 'Test Group');
        insert testGroup;
        GroupMember testGroupMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert testGroupMember;
    }

    @isTest
    static void testGetEmailsWithValidInput() {
        // Start a new test context
        Test.startTest();

        // The DML for Account is inside the test method.
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Get test data from setup method
        User testUser = [SELECT Id, Email FROM User WHERE FirstName = 'Test' LIMIT 1];
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Prepare the input for the invocable method
        String collaboratorIdsString = testUser.Id + ';' + testContact.Id;
        List<CollaboratorEmailService.Request> requests = new List<CollaboratorEmailService.Request>();
        CollaboratorEmailService.Request req = new CollaboratorEmailService.Request();
        req.inputIdsString = collaboratorIdsString;
        req.delimiter = ';';
        requests.add(req);
        
        // Call the invocable method
        List<List<String>> result = CollaboratorEmailService.getEmails(requests);
        Test.stopTest(); // Stop the test and process asynchronous calls

        // Assert the results
        System.assertEquals(1, result.size(), 'Expected a single list of emails to be returned.');
        System.assertEquals(2, result[0].size(), 'Expected two emails in the list.');
        System.assert(result[0].contains(testUser.Email), 'The user email should be in the list.');
        System.assert(result[0].contains(testContact.Email), 'The contact email should be in the list.');
    }

    @isTest
    static void testGetEmailsWithEmptyInput() {
        // Start a new test context
        Test.startTest();
        
        // Prepare the input for the invocable method with an empty string
        List<CollaboratorEmailService.Request> requests = new List<CollaboratorEmailService.Request>();
        CollaboratorEmailService.Request req = new CollaboratorEmailService.Request();
        req.inputIdsString = '';
        req.delimiter = ';';
        requests.add(req);

        // Call the invocable method
        List<List<String>> result = CollaboratorEmailService.getEmails(requests);
        Test.stopTest(); // Stop the test and process asynchronous calls

        // Assert the results
        System.assertEquals(1, result.size(), 'Expected a single list to be returned.');
        System.assertEquals(0, result[0].size(), 'Expected an empty list of emails.');
    }
}