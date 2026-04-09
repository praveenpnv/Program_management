public with sharing class DnBAccountImport {
     /**
     * @description Checks if an account with the given D-U-N-S number already exists
     * @param dunsNumber The D-U-N-S number to check
     * @return A wrapper object containing whether the D-U-N-S exists and its associated account Id
     */
    @AuraEnabled
    public static DunsCheckResult checkDunsNumber(Decimal dunsNumber) {
        DunsCheckResult result = new DunsCheckResult();
        result.exists = false;
         System.debug('inside DunsCheckResult' + dunsNumber); 
        
        if (String.isBlank(String.valueOf(dunsNumber))) {
            return result;
        }
        
        try {
            // Query for accounts with the specified D-U-N-S number
            List<Account> accounts = [
                SELECT Id 
                FROM Account 
                WHERE D_U_N_S_Number__c =: dunsNumber 
                LIMIT 1
            ];
              System.debug('inside DunsCheckResult line 25'); 
            if (!accounts.isEmpty()) {
                  System.debug('inside DunsCheckResult line 27' + accounts[0].Id); 
                result.exists = true;
                result.accountId = accounts[0].Id;
            }
            
            return result;
        } catch (Exception e) {
            // Log the error and return the default result
            System.debug('Error checking D-U-N-S number: ' + e.getMessage());
            return result;
        }
    }

@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getAccountMaps(Id recordId) {
    List<Map<String, String>> result = new List<Map<String, String>>();

    try {
        // Step 1: Fetch metadata records for Account
        List<Mandatory_Field__mdt> mappings = [
            SELECT DeveloperName, Field_List__c, NamespacePrefix
            FROM Mandatory_Field__mdt
            WHERE Object__c = 'Account'
        ];

        // Step 2: Extract field names
        Set<String> accountFields = new Set<String>();
        for (Mandatory_Field__mdt item : mappings) {
            if (String.isNotBlank(item.Field_List__c)) {
                String prefix = String.isNotBlank(item.NamespacePrefix) ? item.NamespacePrefix + '__' : '';
                accountFields.add(prefix + item.Field_List__c.trim());
            }
        }

        // Step 3: Query account record dynamically
        Map<String, Object> accountData = new Map<String, Object>();
        if (recordId != null && !accountFields.isEmpty()) {
            String query = 'SELECT ' + String.join(new List<String>(accountFields), ',') +
                           ' FROM Account WHERE Id = :recordId LIMIT 1';
            SObject accountRecord = Database.query(query);
            accountData = accountRecord.getPopulatedFieldsAsMap();
        }

        // Step 4: Build final field-value map
        for (Mandatory_Field__mdt item : mappings) {
            String prefix = String.isNotBlank(item.NamespacePrefix) ? item.NamespacePrefix + '__' : '';
            String fieldName = item.Field_List__c;
            String value;

            if (String.isNotBlank(fieldName)) {
                String key = prefix + fieldName.trim();
                value = accountData.containsKey(key) ? String.valueOf(accountData.get(key)) : null;

                // Use default if empty
                if (String.isBlank(value) && String.isNotBlank(item.Field_List__c)) {
                    value = item.Field_List__c;
                }

                result.add(new Map<String, String>{
                    'fieldName' => fieldName,
                    'value' => value
                });
            }
        }
    } catch (Exception ex) {
        throw new AuraHandledException('Error fetching mandatory fields: ' + ex.getMessage());
    }
    system.debug('result from metadata '+ result);
    return result;
}

// Helper method to determine current OPCO - implement based on your business logic
public static String getCurrentOpco() {
    // Example implementation - adjust based on your requirements
    User currentUser = [SELECT Opco__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return currentUser.Opco__c;
}
    
    /**
     * @description Wrapper class for D-U-N-S number check results
     */
    public class DunsCheckResult {
        @AuraEnabled public Boolean exists;
        @AuraEnabled public String accountId;
    }
    
}