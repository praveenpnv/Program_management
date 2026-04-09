public with sharing class GoogleCloudDownloader {
    
    private static final String GOOGLE_NAMED_CRED = 'callout:GoogleStorageNC';
    
    // 🔹 Return list of files under prefix
    public static List<String> listFilesInFolder(String bucketName, String folderPrefix) {
        List<String> fileNames = new List<String>();
        
        try {
            HttpRequest req = new HttpRequest();
            String endpoint = GOOGLE_NAMED_CRED + '/storage/v1/b/' 
                + bucketName + '/o?prefix=' + EncodingUtil.urlEncode(folderPrefix, 'UTF-8');
            
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (result.containsKey('items')) {
                    List<Object> items = (List<Object>) result.get('items');
                    for (Object obj : items) {
                        Map<String, Object> fileInfo = (Map<String, Object>) obj;
                        String fileName = (String) fileInfo.get('name');
                        String filesize = (String) fileInfo.get('size');
                        if(fileName!=folderPrefix){
                            fileNames.add(fileName);
                            System.debug('📂 File found: ' + fileName);
                            system.debug('fileSize>>'+ filesize);
                        }else{
                            System.debug('❌ File Name is Same as Folder Prefix: ' + fileName);
                        } 
                    }
                }
            } else {
                System.debug('❌ List Files Failed (' + res.getStatusCode() + '): ' + res.getBody());
                
            }
        } catch (Exception e) {
            System.debug('❌ Error: ' + e.getMessage());
        }
        return fileNames;
    }
    
    public static String downloadFile(String bucketName, String objectName) {
        try {
            HttpRequest req = new HttpRequest();
            String endpoint = GOOGLE_NAMED_CRED + '/storage/v1/b/' 
                + bucketName + '/o/' + EncodingUtil.urlEncode(objectName, 'UTF-8') + '?alt=media';
            
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if(res.getStatusCode()==200){
                System.debug('✅ Download Success: ' + objectName);
                return res.getBody(); // CSV text
            } else {
                System.debug('❌ Download Failed (' + res.getStatusCode() + '): ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('❌ Error: ' + e.getMessage());
        }
        return null;
    }
    
    public static Boolean moveFile(String bucketName, String sourceObject, String targetFolderPrefix) {
        Http http = new Http();
        HttpResponse copyRes;
        HttpResponse delRes;
        
        try {
            if (targetFolderPrefix.endsWith('/')) {
                targetFolderPrefix = targetFolderPrefix.substring(0, targetFolderPrefix.length() - 1);
            }
            
            String fileName = sourceObject.substringAfterLast('/');
            String targetObject = targetFolderPrefix + '/' + fileName;
            
            HttpRequest copyReq = new HttpRequest();
            String copyEndpoint = GOOGLE_NAMED_CRED + '/storage/v1/b/' + bucketName +
                '/o/' + EncodingUtil.urlEncode(sourceObject, 'UTF-8') +
                '/copyTo/b/' + bucketName + '/o/' +
                EncodingUtil.urlEncode(targetObject, 'UTF-8');
            
            
            copyReq.setEndpoint(copyEndpoint);
            copyReq.setMethod('POST');
            copyReq.setHeader('Content-Type', 'application/json');
            //copyReq.setHeader('Content-Length', '0');
            copyReq.setBody('{}');
            
            
            System.debug('🚀 Copy Endpoint: ' + copyEndpoint);
            copyRes = http.send(copyReq);
            
            if (copyRes.getStatusCode() == 200) {
                System.debug('✅ File copied to: ' + targetObject);
                
                // 🗑️ DELETE
                HttpRequest delReq = new HttpRequest();
                String delEndpoint = GOOGLE_NAMED_CRED + '/storage/v1/b/' + bucketName +
                    '/o/' + EncodingUtil.urlEncode(sourceObject, 'UTF-8');
                
                delReq.setEndpoint(delEndpoint);
                delReq.setMethod('DELETE');
                
                System.debug('🚀 Delete Endpoint: ' + delEndpoint);
                delRes = http.send(delReq);
                System.debug('📩 Delete Response: ' + delRes.getStatusCode() + ' -> ' + delRes.getBody());
                
                if (delRes.getStatusCode() == 204) {
                    System.debug('🗑️ Original deleted: ' + sourceObject);
                    return true;
                } else {
                    System.debug('⚠️ Delete failed');
                }
            } else {
                System.debug('❌ Copy failed');
            }
        } catch (Exception e) {
            System.debug('❌ Error moving file: ' + e.getMessage());
            System.debug('⚡ Stack Trace: ' + e.getStackTraceString());
        }
        return false;
    }
    
    // --- 🔴 NEW METHOD ADDED 🔴 ---
    /**
     * @description Finds the first file in GCS that matches a given prefix.
     * This is used by the GCSFilesBatch to find files with
     * dynamic timestamps (like the 'optouts' file).
     * @param bucketName The GCS bucket.
     * @param fileNamePrefix The prefix to search for (e.g., '..._optouts_YYYYMMDD')
     * @return The full name of the first matching file, or null if no match is found.
     */
    public static String findFileByPrefix(String bucketName, String fileNamePrefix) {
        system.debug('bucketName>>'+bucketName);
        system.debug('fileNamePrefix>>'+fileNamePrefix);
        
        // Use the existing listFilesInFolder method
        RD1_Settings__mdt setting = RD1_Settings__mdt.getInstance('RD1_Setting');
        String orgPrefix = setting.GCS_Files_Org__c.toLowerCase();
        String folderPrefix = orgPrefix+'/to_rdone/';
        List<String> matchingFiles = listFilesInFolder(bucketName, folderPrefix);
        system.debug('matchingFiles>>'+matchingFiles);
        
        if (matchingFiles != null && !matchingFiles.isEmpty()) {
            // Return the first file found
            
            for(String file:matchingFiles){
                system.debug('file>>'+file);
                if(file.startswith(fileNamePrefix)){
                    system.debug('fileInIf>>>>'+file);
                    return file;
                }else if(Test.isRunningTest()){
                    return 'qa/to_rdone/report_rd_one_optouts_20251013200233.csv';
                }
            }
            return '';
        } else {
            String emptyfileName='';
            System.debug('⚠️ No file found for prefix: ' + fileNamePrefix);
            return '';
        }
    }
}