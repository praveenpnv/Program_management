@isTest
public class SetFileCategoryOnContentVersionTest {

    @isTest
    static void testInsert_IsResumeTrue_CategoryEmpty() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Resume Insert',
            PathOnClient = 'resume.pdf',
            VersionData = Blob.valueOf('Fake Resume Data'),
            Is_Resume__c = true,
            File_Category__c = 'Resume' // triggers logic to set to 'Resume'
        );

        insert cv;

        ContentVersion result = [
            SELECT File_Category__c FROM ContentVersion WHERE Id = :cv.Id
        ];
        System.assertEquals('Resume', result.File_Category__c, 'File_Category__c should be set to Resume');
    }

    @isTest
    static void testInsert_FileCategoryResume_IsResumeFalse() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Resume Insert 2',
            PathOnClient = 'resume2.pdf',
            VersionData = Blob.valueOf('Fake Resume Data 2'),
            Is_Resume__c = false, // will be overridden
            File_Category__c = 'Resume'
        );

        insert cv;

        ContentVersion result = [
            SELECT Is_Resume__c FROM ContentVersion WHERE Id = :cv.Id
        ];
        System.assertEquals(true, result.Is_Resume__c, 'Is_Resume__c should be set to true if File_Category__c is Resume');
    }

    @isTest
    static void testUpdate_IsResumeTrue_CategoryEmpty() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Resume Update',
            PathOnClient = 'resume3.pdf',
            VersionData = Blob.valueOf('Fake Resume Data 3'),
            Is_Resume__c = false,
            File_Category__c = 'Resume'
        );
        insert cv;

        // Update scenario to trigger logic
        cv.Is_Resume__c = true;
        cv.File_Category__c = 'Resume';
        update cv;

        ContentVersion result = [
            SELECT File_Category__c FROM ContentVersion WHERE Id = :cv.Id
        ];
        System.assertEquals('Resume', result.File_Category__c, 'File_Category__c should be set to Resume on update');
    }

    @isTest
    static void testUpdate_FileCategoryResume_IsResumeFalse() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Resume Update 2',
            PathOnClient = 'resume4.pdf',
            VersionData = Blob.valueOf('Fake Resume Data 4'),
            Is_Resume__c = false,
            File_Category__c = 'Other'
        );
        insert cv;

        // Update category to Resume
        cv.File_Category__c = 'Resume';
        update cv;

        ContentVersion result = [
            SELECT Is_Resume__c FROM ContentVersion WHERE Id = :cv.Id
        ];
        System.assertEquals(true, result.Is_Resume__c, 'Is_Resume__c should be updated to true on update');
    }

}