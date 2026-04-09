public class UpdateLegacyBHIdBatch_Account implements Database.Batchable<SObject> {

    public String query = 'SELECT Id, Legacy_BH_ID__c, Account_Import_ID__c FROM Account  WHERE Account_Import_ID__c != null AND Legacy_BH_ID__c = null AND CreatedById = \'0059X00000LZ6RRQA1\'';

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        /*
        List<Account> toUpdate = new List<Account>();

        for (SObject s : scope) {
            Account c = (Account)s;
            String importId = c.Account_Import_ID__c;

            if (importId != null && System.Pattern.matches('^\\d+(\\.\\d+)?$', importId.trim())) {
                c.Legacy_BH_ID__c = Decimal.valueOf(importId);
                toUpdate.add(c);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }*/
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: add logging or email notifications here
    }
}