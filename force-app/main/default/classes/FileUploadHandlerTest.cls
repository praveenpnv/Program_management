@isTest
public class FileUploadHandlerTest {
    @testSetup
    static void setup() {
        // Create a Contact record for testing
        Contact testContact = new Contact(LastName = 'Test Contact');
        insert testContact;
        
        // Create a ContentVersion record for testing
        ContentVersion testVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Content'),
            File_Category__c = 'Resume'
        );
        insert testVersion;
    }

    @isTest
    static void testUpdateFileCategory() {
        // Get test data
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Call method
        Test.startTest();
        FileUploadHandler.updateFileCategory(cv.Id, testContact.Id, 'Resume');
        Test.stopTest();
        
        // Verify updates
        ContentVersion updatedCV = [SELECT File_Category__c FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals('Resume', updatedCV.File_Category__c);
    }

    @isTest
    static void testGetFiles() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Associate ContentVersion with Contact
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId,
            LinkedEntityId = testContact.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        Test.startTest();
        List<ContentVersion> files = FileUploadHandler.getFiles(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, files.size(), 'Files should be returned');
    }
}