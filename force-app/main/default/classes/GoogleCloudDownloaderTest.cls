@isTest
public class GoogleCloudDownloaderTest {
    
    // 🔹 Mock implementation for HTTP responses
    private class GCSHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            String endpoint = req.getEndpoint();
            
            // Handle listFilesInFolder mock
            if (endpoint.contains('/o?prefix=')) {
                res.setStatusCode(200);
                res.setBody('{"items":[{"name":"qa/report.csv","size":"1024"},{"name":"qa/"}]}');
            }
            // Handle downloadFile mock
            else if (endpoint.endsWith('?alt=media')) {
                res.setStatusCode(200);
                res.setBody('email@example.com,2025-09-20,Y\nanother@example.com,2025-09-21,N');
            }
            // Handle copyTo mock
            else if (endpoint.contains('/copyTo/')) {
                res.setStatusCode(200);
                res.setBody('{"kind":"storage#object","name":"qa/archive/report.csv"}');
            }
            // Handle delete mock
            else if (req.getMethod() == 'DELETE') {
                res.setStatusCode(204);
                res.setBody('');
            }
            else {
                res.setStatusCode(400);
                res.setBody('Unexpected mock call: ' + endpoint);
            }
            
            return res;
        }
    }
    
    @isTest
    static void testListFilesInFolder() {
        Test.setMock(HttpCalloutMock.class, new GCSHttpMock());
        
        List<String> files = GoogleCloudDownloader.listFilesInFolder('my-bucket', 'qa/');
        
        System.assertNotEquals(null, files, 'File list should not be null');
        System.assert(files.size() > 0, 'Should return some files');
        System.assert(files[0].contains('.csv'), 'Expected CSV file in result');
    }
    
    @isTest
    static void testDownloadFile() {
        Test.setMock(HttpCalloutMock.class, new GCSHttpMock());
        
        String content = GoogleCloudDownloader.downloadFile('my-bucket', 'qa/report.csv');
        
        System.assertNotEquals(null, content, 'Download should return file content');
        System.assert(content.contains('@example.com'), 'File content should contain emails');
    }
    
    @isTest
    static void testMoveFile() {
        Test.setMock(HttpCalloutMock.class, new GCSHttpMock());
        
        Boolean moved = GoogleCloudDownloader.moveFile('my-bucket', 'qa/report.csv', 'qa/archive');
        
        System.assertEquals(true, moved, 'File should be moved successfully');
    }
}