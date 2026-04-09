@IsTest
private class RD_ChangeEvent_Test {

    @isTest
    private static void test_RDChangeEvent() {
        RD_ChangeEvent__e evt = new RD_ChangeEvent__e();
        evt.Change_Type__c = 'Insert';
        evt.Changed_By__c = 'ABC';
        evt.Entity__c = 'Account';
        evt.Fields__c = '{"A":"B"}';
        evt.Record_Id__c = 'AAAA';
        evt.Source__c = 'User';
        evt.Timestamp__c = System.now();
        
        Test.startTest();
            Database.SaveResult result = EventBus.publish(evt);
        Test.stopTest();
    }

}