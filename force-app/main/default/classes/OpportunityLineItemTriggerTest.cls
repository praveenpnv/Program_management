@isTest
private class OpportunityLineItemTriggerTest {
    
    private static Map<String, Object> createTestData() {
        Map<String, Object> testData = new Map<String, Object>();
        
        Opportunity opp = RD1TestDataFactory.createTestOpportunity();
        Product2 product = RD1TestDataFactory.createTestProduct();
        PricebookEntry pbe = RD1TestDataFactory.createTestPricebookEntry(product.Id);
        JobFunction__c jobFunction = RD1TestDataFactory.createTestJobFunction();
        
        testData.put('opportunity', opp);
        testData.put('product', product);
        testData.put('pricebookEntry', pbe);
        testData.put('jobFunction', jobFunction);
        return testData;
    }
    
    @isTest
    static void testInsert_TriggersHelper() {
        Map<String, Object> testData = createTestData();
        
        Opportunity opp = (Opportunity) testData.get('opportunity');
        PricebookEntry pbe = (PricebookEntry) testData.get('pricebookEntry');
        JobFunction__c jobFunction = (JobFunction__c) testData.get('jobFunction');
        
        Id consultancyRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Service Request' LIMIT 1].Id;
        opp.RecordTypeId = consultancyRTId;
        opp.Service_Line__c = 'Customer Experience';
        opp.Sub_Service_Line__c = 'Application Development';
        update opp;
        
        Test.startTest();
        OpportunityLineItem lineItem = RD1TestDataFactory.createTestOpportunityLineItem(opp.Id, pbe.Id, jobFunction.Id);
        Test.stopTest();
        
        System.assertEquals('Customer Experience', opp.Service_Line__c);
        System.assertEquals('Application Development', opp.Sub_Service_Line__c);
    }
    
    @isTest
    static void testUpdate_TriggersHelper() {
        Map<String, Object> testData = createTestData();
        
        Opportunity opp = (Opportunity) testData.get('opportunity');
        PricebookEntry pbe = (PricebookEntry) testData.get('pricebookEntry');
        JobFunction__c jobFunction = (JobFunction__c) testData.get('jobFunction');
        
        Id consultancyRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Service Request' LIMIT 1].Id;
        opp.RecordTypeId = consultancyRTId;
        opp.Service_Line__c = 'Customer Experience';
        opp.Sub_Service_Line__c = 'Application Development';
        update opp;
        
        OpportunityLineItem lineItem = RD1TestDataFactory.createTestOpportunityLineItem(opp.Id, pbe.Id, jobFunction.Id);
        
        Test.startTest();
        lineItem.Service_Line__c = 'Digital & Product Engineering';
        update lineItem;
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Service_Line__c, Sub_Service_Line__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(updatedOpp.Service_Line__c.contains('Digital & Product Engineering'), 'Service Line should include updated value');
    }
    
    @isTest
    static void testSkippedIfRecordTypeIsSOW() {
        Map<String, Object> testData = createTestData();
        
        Opportunity opp = (Opportunity) testData.get('opportunity');
        PricebookEntry pbe = (PricebookEntry) testData.get('pricebookEntry');
        
        JobFunction__c jobFunction = (JobFunction__c) testData.get('jobFunction');
        
        Id consultancyRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'SoW' LIMIT 1].Id;
        opp.RecordTypeId = consultancyRTId;
        update opp;
       
       OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id,
            Service_Line__c = 'Customer Experience',
            Sub_Service_Line__c = 'Marketing Experience',
            Job_Type__c = 'Solutions'
        );
        
        Test.startTest();
        insert oli;
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Service_Line__c, Sub_Service_Line__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.Service_Line__c, 'Should not update SL');
        System.assertEquals(null, updatedOpp.Sub_Service_Line__c, 'Should not update SSL');
    }
}