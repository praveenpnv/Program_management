@IsTest
public class FieldSetControllerTest {

    @IsTest
    static void testGetFieldSetFields_ValidFieldSet() {
        // Make sure this Field Set exists in your org
        String objectName = 'Contact';
        String fieldSetName = 'Mandatory_Interview_Fields';

        Test.startTest();
        List<Map<String, Object>> fieldNames = FieldSetController.getFieldSetFields(objectName, fieldSetName);
        Test.stopTest();

        System.assert(!fieldNames.isEmpty(),
            'Expected field names from field set ' + fieldSetName);

        // Validate structure of each map
        for (Map<String, Object> fieldInfo : fieldNames) {
            System.assert(fieldInfo.containsKey('fieldPath'),
                'Each field must contain fieldPath');
            System.assert(fieldInfo.containsKey('required'),
                'Each field must contain required flag');
        }

        System.debug('Field Info: ' + fieldNames);
    }

    @IsTest
    static void testGetFieldSetFields_InvalidFieldSet() {
        String objectName = 'Account';
        String fieldSetName = 'Non_Existent_Field_Set';

        Test.startTest();
        List<Map<String, Object>> fieldNames = FieldSetController.getFieldSetFields(objectName, fieldSetName);
        Test.stopTest();

        System.assertEquals(0, fieldNames.size(),
            'Expected no fields for invalid field set.');
    }

    @IsTest
    static void testGetFieldSetFields_InvalidObject() {
        String objectName = 'InvalidObject';
        String fieldSetName = 'Test_Field_Set';

        Test.startTest();
        List<Map<String, Object>> fieldNames = FieldSetController.getFieldSetFields(objectName, fieldSetName);
        Test.stopTest();

        System.assertEquals(0, fieldNames.size(),
            'Expected no fields for invalid object.');
    }
}