/**
* @File Name : FileUploadHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : February 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 27, 2025 |   | Initial Version
**/

public with sharing class FileUploadHandler {
    @AuraEnabled
    public static void updateFileCategory(String contentVersionId, String recordId, String category) {
        system.debug('String contentVersionId'+ contentVersionId);
                system.debug('String recordId'+recordId);
                system.debug('String category'+category);

        if (String.isNotBlank(contentVersionId) && String.isNotBlank(category)) {
            ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];

            // Associate file with record
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
               // LinkedEntityId = recordId,
                ShareType = 'V' // View access
            );
           // insert cdl;

            // Update the file with Category
            cv.File_Category__c= category;
            update cv;

          //  updateResumeCount(recordId);
         // Check if recordId is a Contact before invoking updateResumeCount
            if (String.isNotBlank(recordId)) {
                // Convert the String recordId to an Id type
                Id recordIdAsId = (Id)recordId; // Explicitly cast to Id
                
                // Get the sObject type of the recordId
                String sObjectType = recordIdAsId.getSObjectType().getDescribe().getName();
                
                if (sObjectType == 'Contact') {
                    updateResumeCount(recordId); // Pass the original String recordId if updateResumeCount expects String
                    System.debug('updateResumeCount invoked for Contact recordId: ' + recordId);
                } else {
                    System.debug('recordId is not a Contact. updateResumeCount not invoked. SObject Type: ' + sObjectType);
                }
            }
            
    
    }
    }

  private static void updateResumeCount(String contactId) {
        system.debug('Updating Resume Count for Contact ID: ' + contactId);
        
        // Count the number of Resumes linked to this Contact
        AggregateResult[] resumeCountResult = [
            SELECT COUNT(Id) countResumes 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :contactId 
            AND ContentDocumentId IN (
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE File_Category__c = 'Resume'
            )
        ];

        Integer resumeCount = (resumeCountResult.isEmpty()) ? 0 : (Integer)resumeCountResult[0].get('countResumes');

        // Update Contact record
        Contact contactToUpdate = new Contact(Id = contactId, Resume_Count__c = resumeCount);
        update contactToUpdate;

        system.debug('Updated Resume Count: ' + resumeCount);
    }
     @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getFiles(String recordId) {
        // Fetch ContentDocumentIds linked to the record
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId
        ];
        
        // Extract ContentDocumentIds
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            documentIds.add(link.ContentDocumentId);
        }

        // Fetch ContentVersion records for these ContentDocumentIds
        if (!documentIds.isEmpty()) {
            return [
                SELECT Id, Title, File_Category__c, ContentDocumentId 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :documentIds
                ORDER BY CreatedDate DESC
            ];
        }
        
        return new List<ContentVersion>(); // Return empty list if no files exist
    }
}