public with sharing class ReleaseNotesService {
    @AuraEnabled
    public static String previewNotes(Id releaseId) { return ''; }

    @AuraEnabled
    public static void generateAndSave(Id releaseId) { }

    @AuraEnabled
    public static void sendReleaseEmail(Id releaseId) { }
}