public with sharing class FlowCustomPermissionChecker {

    public class PermissionInput {
        @InvocableVariable(required=true)
        public String permissionName;
    }

    public class PermissionResult {
        @InvocableVariable
        public Boolean hasPermission;
    }

    @InvocableMethod(label='Check Custom Permission' description='Returns true if the user has the specified custom permission')
    public static List<PermissionResult> checkPermission(List<PermissionInput> inputs) {
        List<PermissionResult> results = new List<PermissionResult>();

        for (PermissionInput input : inputs) {
            Boolean allowed = FeatureManagement.checkPermission(input.permissionName);
            PermissionResult result = new PermissionResult();
            result.hasPermission = allowed;
            results.add(result);
        }

        return results;
    }
}