@isTest
public class MandatoryContactFieldTriggerTest {

    @isTest
    static void testBeforeInsert() {
        // Get *any* available record type for Contact (to avoid query exception)
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' LIMIT 1];

        Contact con = new Contact(
            FirstName='Test',
            LastName = 'Smith',
            RecordTypeId = rt.Id
        );

        Test.startTest();
        try {
            insert con;
        } catch (Exception e) {
            System.debug('Insert Exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdate() {
        // Get any available record type for Contact
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' LIMIT 1];

        Contact con = new Contact(
            FirstName='Test',
            LastName = 'Doe',
            RecordTypeId = rt.Id
        );
        insert con;

        // Simulate missing mandatory field
        con.LastName = null;

        Test.startTest();
        try {
            update con;
        } catch (Exception e) {
            System.debug('Update Exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}