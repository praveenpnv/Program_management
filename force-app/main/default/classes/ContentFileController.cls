/**
* @File Name : ContentFileController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 11, 2025 |   | Initial Version
**/

public with sharing class ContentFileController {
    @AuraEnabled(cacheable=true)
    public static Integer getFileCount(String linkedEntityId, String fileCategory) {
        if (String.isEmpty(linkedEntityId) || String.isEmpty(fileCategory)) {
            return 0;
        }

        Integer count = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :linkedEntityId
            AND ContentDocument.LatestPublishedVersion.File_Category__c = :fileCategory
        ];

        return count;
    }
}