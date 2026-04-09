public class ApplicationStagePermissionHandler {
    public static void handle(List<TR1__Application_V2__c> newList, Map<Id, TR1__Application_V2__c> oldMap, Boolean isInsert, Boolean isUpdate) {
        Set<String> stageNamesToCheck = new Set<String>();

        for (TR1__Application_V2__c app : newList) {
            String newStage = app.TR1__Stage__c;
            String oldStage = (isUpdate && oldMap != null && app.Id != null && oldMap.containsKey(app.Id)) 
                ? oldMap.get(app.Id).TR1__Stage__c 
                : null;

            Boolean isNewOrChanged = isInsert || (isUpdate && newStage != oldStage);
            if (isNewOrChanged && String.isNotBlank(newStage)) {
                stageNamesToCheck.add(newStage);
            }
        }

        if (stageNamesToCheck.isEmpty()) return;

        Map<String, Application_Stage_Access__mdt> stageAccessMap = new Map<String, Application_Stage_Access__mdt>();
        for (Application_Stage_Access__mdt mdt : [
            SELECT DeveloperName, Create__c, Edit__c
            FROM Application_Stage_Access__mdt
            WHERE DeveloperName IN :stageNamesToCheck
        ]) {
            stageAccessMap.put(mdt.DeveloperName, mdt);
        }

        for (TR1__Application_V2__c app : newList) {
            String newStage = app.TR1__Stage__c;
            String oldStage = (isUpdate && oldMap != null && app.Id != null && oldMap.containsKey(app.Id)) 
                ? oldMap.get(app.Id).TR1__Stage__c 
                : null;

            Boolean isNewOrChanged = isInsert || (isUpdate && newStage != oldStage);

            if (!isNewOrChanged || String.isBlank(newStage)) continue;

            Application_Stage_Access__mdt accessConfig = stageAccessMap.get(newStage);
            if (accessConfig == null) continue;

            String requiredPermission = isInsert ? accessConfig.Create__c : accessConfig.Edit__c;

            // Optional: skip permission checks in test context
            if (!Test.isRunningTest() && !String.isBlank(requiredPermission) && !FeatureManagement.checkPermission(requiredPermission)) {
                app.addError('You do not have the required permission "' + requiredPermission +
                             '" to set Stage to "' + newStage + '".');
            }
        }
    }
}