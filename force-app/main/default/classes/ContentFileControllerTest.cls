@isTest
private class ContentFileControllerTest {
    @testSetup
    static void setupTestData() {
        // ✅ Step 1: Create Test Account
        Account acc = new Account(Name = 'Test Account', BH_VAT_Number__c = '565453452');
        insert acc;
        
        // ✅ Step 2: Create ContentVersion (Attach to Account)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file content'),
            FirstPublishLocationId = acc.Id // ✅ Links the file to Account
        );
        insert contentVersion;

        // ✅ Step 3: Fetch ContentDocument (Ensure It Exists)
        ContentDocument contentDoc;
        for (Integer i = 0; i < 5; i++) { // Retry loop
            List<ContentDocument> docs = [
                SELECT Id, LatestPublishedVersionId 
                FROM ContentDocument 
                WHERE LatestPublishedVersionId = :contentVersion.Id 
                LIMIT 1
            ];
            if (!docs.isEmpty()) {
                contentDoc = docs[0];
                break;
            }
        }
        System.assertNotEquals(null, contentDoc, '❌ ContentDocument not found after insert.');

        // ✅ Step 4: Update File_Category__c (SOQL in getFileCount depends on this)
        ContentVersion latestVersion = [SELECT Id FROM ContentVersion WHERE Id = :contentDoc.LatestPublishedVersionId LIMIT 1];
        latestVersion.File_Category__c = 'Resume';
        update latestVersion;

        // ✅ Step 5: Check If ContentDocumentLink Exists
        List<ContentDocumentLink> existingLinks = [
            SELECT Id FROM ContentDocumentLink 
            WHERE LinkedEntityId = :acc.Id AND ContentDocumentId = :contentDoc.Id
        ];
        
        if (existingLinks.isEmpty()) {
            // ✅ Step 6: Link ContentDocument to Account (Only if not already linked)
            ContentDocumentLink contentLink = new ContentDocumentLink(
                LinkedEntityId = acc.Id,
                ContentDocumentId = contentDoc.Id,
                ShareType = 'V'
            );
            insert contentLink;
        }
        
        // ✅ Debug Logs
        System.debug('📌 Account ID: ' + acc.Id);
        System.debug('📌 ContentDocument ID: ' + contentDoc.Id);
        System.debug('📌 Latest Version ID: ' + latestVersion.Id);
    }

    @isTest
    static void testGetFileCountValidInput() {
        // ✅ Fetch the Account
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Integer fileCount = ContentFileController.getFileCount(acc.Id, 'Resume');
        Test.stopTest();
        
        System.assertEquals(1, fileCount, '❌ File count should be 1 for valid input');
    }
    
    }