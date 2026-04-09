public with sharing class DNBTypeaheadSearch {
    private static final String BASE_URL = 'https://plus.dnb.com/v1/search/typeahead?searchTerm=';

    @AuraEnabled(cacheable=true)
    public static String searchDNB(String searchTerm) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            // Dynamically get a valid access token
            String accessToken = DnBTokenManager.getAccessToken();

            request.setEndpoint(BASE_URL + EncodingUtil.urlEncode(searchTerm, 'UTF-8'));
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Content-Type', 'application/json');

            HttpResponse response = http.send(request);

            System.debug('API Raw Response: ' + response.getBody());

            if (response.getStatusCode() == 200 && String.isNotBlank(response.getBody())) {
                return response.getBody().trim();  // Ensure no extra whitespace
            } else {
                return '{"error": "API Call Failed", "status": ' + response.getStatusCode() + '}';
            }
        } catch (Exception e) {
            System.debug('❌ Exception during DNB Search: ' + e.getMessage());
            return '{"error": "' + e.getMessage() + '"}';
        }
    }   
    
    @AuraEnabled
    public static Map<String, Object> importOrUpdateAccount(Map<String, Object> accountData) {
        try {
            // Convert the received data into an Account object
            system.debug('from importOrUpdateAccount pri---accountData--'+accountData);
            Account newAccount = new Account();
            
            // Set the Account fields from the accountData map
            newAccount.Name = (String) accountData.get('Name');
            newAccount.D_U_N_S_Number__c = (Decimal) accountData.get('D_U_N_S_Number__c');
            newAccount.BillingStreet = (String) accountData.get('BillingStreet');
            newAccount.BillingCity = (String) accountData.get('BillingCity');
            newAccount.BillingCountry = (String) accountData.get('BillingCountry');
            
            // Handle numeric fields
            Object annualRevenue = accountData.get('AnnualRevenue');
            if (annualRevenue != null) {
                if (annualRevenue instanceof String) {
                    newAccount.AnnualRevenue = Decimal.valueOf((String) annualRevenue);
                } else if (annualRevenue instanceof Decimal) {
                    newAccount.AnnualRevenue = (Decimal) annualRevenue;
                } else if (annualRevenue instanceof Double) {
                    newAccount.AnnualRevenue = Decimal.valueOf((Double) annualRevenue);
                }
            }
            
            newAccount.SIC = (String) accountData.get('SIC');
            newAccount.Industry = (String) accountData.get('Industry');
            newAccount.Phone = (String) accountData.get('Phone');
            
            // Set the Parent Account
            String parentId = (String) accountData.get('ParentId');
            if (String.isNotBlank(parentId)) {
                newAccount.ParentId = Id.valueOf(parentId);
            }
            
            // Check if an account with this DUNS number already exists
            List<Account> existingAccounts = [SELECT Id FROM Account WHERE D_U_N_S_Number__c = :newAccount.D_U_N_S_Number__c LIMIT 1];
            
            Map<String, Object> result = new Map<String, Object>();
            
            if (!existingAccounts.isEmpty()) {
                // Update existing account
                newAccount.Id = existingAccounts[0].Id;
                update newAccount;
                result.put('id', newAccount.Id);
                result.put('message', 'Account updated successfully');
            } else {
                // Create new account
                insert newAccount;
                result.put('id', newAccount.Id);
                result.put('message', 'Account created successfully');
            }
            
            return result;
        } catch (Exception e) {
            System.debug('Error in importOrUpdateAccount: ' + e.getMessage());
            throw new AuraHandledException('Error processing account: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getParentAccounts() {
        try {
            // Query for potential parent accounts
            // Limit to a reasonable number and consider adding search filters
            return [SELECT Id, Name FROM Account ORDER BY Name LIMIT 100];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching parent accounts: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRecordTypes(String objectApiName) {
        try {
            List<Map<String, String>> recordTypeList = new List<Map<String, String>>();

            // Describe the SObject
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjType == null) {
                throw new AuraHandledException('Invalid object: ' + objectApiName);
            }

            // Get all RecordTypes that are available to the current user
            Map<String, Schema.RecordTypeInfo> rtInfoMap = sObjType.getDescribe().getRecordTypeInfosByName();

            for (Schema.RecordTypeInfo rtInfo : rtInfoMap.values()) {
                if (rtInfo.isAvailable() && !rtInfo.isMaster() ) {
                    Map<String, String> rtDetails = new Map<String, String>();
                    rtDetails.put('Id', rtInfo.getRecordTypeId());
                    rtDetails.put('Name', rtInfo.getName());
                    recordTypeList.add(rtDetails);
                }
            }

            return recordTypeList;
        } catch (Exception e) {
            System.debug('❌ Error in getRecordTypes: ' + e.getMessage());
            throw new AuraHandledException('Error fetching record types: ' + e.getMessage());
        }
    }
}