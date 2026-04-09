/**
 * Test Class for RIG_LinkController
 */
@isTest
private class RIG_LinkControllerTest {

@IsTest
    public static void getBaseUrlTest() {
        
        Test.startTest();
        String url = RIG_LinkController.getBaseRIGURL(UserInfo.getUserId());

        //System.assertNotEquals(null, url);
        // Negative Scenario
        url = RIG_LinkController.getBaseRIGURL(null);
        System.assert(url == null, 'Url should be null');

        RIG_LinkController.getFormattedUrl('http://abc.com',UserInfo.getUserId());
        RIG_LinkController.getAlternateID('Account', null);
        RIG_LinkController.getAlternateID('Contact', null);
        RIG_LinkController.getAlternateID('TR1__JOB__c', null);
        RIG_LinkController.getAlternateID('TR1__ClOSING_REPORT__c', null);

        Test.stopTest();
    }
}