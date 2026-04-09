@isTest
public class AllSorterControllerTest {

    @isTest
    static void testGetCorporationId_WhenSettingExists() {
        AllSorterSettings__c setting = new AllSorterSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Corporation_ID__c = 'Randstad_Test_ID'
        );
        insert setting;
        Test.startTest();
        String result = AllSorterController.getCorporationId();
        Test.stopTest();

        System.assertEquals('Randstad_Test_ID', result, 'The corporation ID should match the custom setting value.');
    }

    @isTest
    static void testGetCorporationId_WhenSettingMissing() {
        Test.startTest();
        String result = AllSorterController.getCorporationId();
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null if no custom setting is defined.');
    }
}