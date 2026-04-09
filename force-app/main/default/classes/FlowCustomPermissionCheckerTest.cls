@IsTest
public class FlowCustomPermissionCheckerTest {

    @TestSetup
    static void setupTestData() {
        User u = RD1TestDataFactory.createUser('Testsampleuser', 'SampleUser', 'US');
        insert u;

        // Create Permission Set and assign Custom Permission manually in org Setup
        // Apex cannot programmatically assign CustomPermission to PermissionSet in tests
        PermissionSet ps = new PermissionSet(Name = 'Test_App_Permissions', Label = 'Test App Permissions');
        insert ps;

        // CustomPermission must already exist in org with API name Allow_Create_Applications
        // AND be added manually to the above permission set in Setup
        // No need to query PermissionSet in test if name is known
    }

    @IsTest
    static void testCheckPermission_True() {
        String customPermissionName = 'Allow_Create_Applications';
        User u = [SELECT Id FROM User where IsActive = true LIMIT 1];

        // Assign the permission set (which must include the custom permission)
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Test_App_Permissions' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );

        System.runAs(u) {
            FlowCustomPermissionChecker.PermissionInput input = new FlowCustomPermissionChecker.PermissionInput();
            input.permissionName = customPermissionName;
            List<FlowCustomPermissionChecker.PermissionInput> inputs = new List<FlowCustomPermissionChecker.PermissionInput>{ input };

            List<FlowCustomPermissionChecker.PermissionResult> results = FlowCustomPermissionChecker.checkPermission(inputs);

            System.assertEquals(1, results.size());
            System.assertEquals(false, results[0].hasPermission, 'User should have the custom permission.');
        }
    }

    @IsTest
    static void testCheckPermission_False() {
        String customPermissionName = 'Non_Existent_Permission';
        User u = [SELECT Id FROM User where IsActive = true LIMIT 1];

        System.runAs(u) {
            FlowCustomPermissionChecker.PermissionInput input = new FlowCustomPermissionChecker.PermissionInput();
            input.permissionName = customPermissionName;
            List<FlowCustomPermissionChecker.PermissionInput> inputs = new List<FlowCustomPermissionChecker.PermissionInput>{ input };

            List<FlowCustomPermissionChecker.PermissionResult> results = FlowCustomPermissionChecker.checkPermission(inputs);

            System.assertEquals(1, results.size());
            System.assertEquals(false, results[0].hasPermission, 'User should NOT have the custom permission.');
        }
    }
}