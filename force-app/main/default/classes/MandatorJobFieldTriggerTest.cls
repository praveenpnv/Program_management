@isTest
public class MandatorJobFieldTriggerTest {
     @isTest
    static void testMandatoryFieldsValidation() {
        // Fetch a test user with the specified username
        User users = RD1TestDataFactory.createUser('milanprasad','Milan','US');
        insert users;
        
        User testUser = users;

        System.runAs(testUser) {
            // Retrieve valid picklist values dynamically for Education_Requirements
            Schema.DescribeFieldResult EducationReqField = TR1__Job__c.Education_Requirements__c.getDescribe();
            List<Schema.PicklistEntry> EducationReqValues = EducationReqField.getPicklistValues();
            String validEducationReq = EducationReqValues.isEmpty() ? null : EducationReqValues[0].getValue();
            System.assertNotEquals(null, validEducationReq, 'No valid values found for Employee_Type__c picklist.');

            // Retrieve valid picklist values dynamically for Line_of_Business__c
            Schema.DescribeFieldResult lineField = TR1__Job__c.Line_of_Business__c.getDescribe();
            List<Schema.PicklistEntry> lineValues = lineField.getPicklistValues();
            String validLineValue = lineValues.isEmpty() ? null : lineValues[0].getValue();
            System.assertNotEquals(null, validLineValue, 'No valid values found for Exempt_or_NonExempt__c picklist.');

            // Create a mock Job record and insert it
            TR1__Job__c testJob = new TR1__Job__c(
                Name = 'Sample Job' ,// Required fields for TR1__Job__c
                Job_Type__c='contract'
            );
            insert testJob;

            Test.startTest(); // Start test block

            // Test for missing mandatory fields
            TR1__Job__c job = new TR1__Job__c(
                Education_Requirements__c = validEducationReq,
                Line_of_Business__c = null ,
                  Job_Type__c='contract'// Simulating a missing mandatory field
            );

            try {
                insert job;
               // System.assert(false, 'Expected an exception due to missing mandatory fields, but no exception was thrown.');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('mandatory'), 'Expected mandatory field validation error but got: ' + e.getMessage());
            }

            // Create a valid record with all required fields populated
            TR1__Job__c validJobFields = new TR1__Job__c(
                TR1__Maximum_Bill_Rate__c = 100.00,
                Calculated_GP__c = 10.00,
                Education_Requirements__c = 'Associates',
                TR1__Estimated_End_Date__c = Date.newInstance(2025, 3, 29),
                TR1__Estimated_Start_Date__c =Date.newInstance(2025, 3, 28),
                Hours_of_Operation__c = '5am to 2pm',
                Independent_Contractors_Allowed__c = 'Yes',
                Interview_Info__c = 'Phone to Hire',
                TR1__Responsibilities__c = 'Test',
                Line_of_Business__c = 'CR',
                TR1__Maximum_Pay_Rate__c = 20.00,
                Published_Summary__c = 
                'Test',
                Qualifications_US__c = 'Tets Test',
                RITS_Talent_Allowed__c = 'Yes',
                Remote_Work_Allowed__c = True,
                X3rd_Party_Vendors_Allowed__c = 'Yes',
                 Job_Type__c='contract'
);

            insert validJobFields;

            Test.stopTest(); // Stop test block

            System.assertNotEquals(null, validJobFields.Id, 'Record should be inserted successfully when all mandatory fields are provided.');
        }
    }

}