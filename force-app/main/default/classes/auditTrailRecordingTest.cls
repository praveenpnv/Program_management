@isTest 
private class auditTrailRecordingTest 
{
    @isTest
    private static void Test_Params() 
    {
        Audit_Trail__c t = new Audit_Trail__c(Audit_ID__c='11AABCDDD', Performed_On__c = System.now());
        insert t;
        
        Test.startTest();
    
        auditTrailRecording atr=new auditTrailRecording();
        atr.execute(null);
        
        Test.stopTest();
    } 
}