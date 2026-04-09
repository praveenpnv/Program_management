public with sharing class DNBCreditCheckCallout {
    
    private static final String BLOCK_IDS = 'financialstrengthinsight_L1_v1,companyinfo_L1_v1';
    private static final Integer TIMEOUT_SECONDS = 120000;

    @AuraEnabled
    public static Map<String, Object> performCreditCheck(Id accountId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Account accObj = getAccountById(accountId);
            if (accObj == null) {
                result.put('success', false);
                result.put('message', 'Account not found');
                return result;
            }
            
            result.put('accountName', accObj.Name);
            result.put('success', true);
            
            if (accObj.D_U_N_S_Number__c != null) {
                // Account has DUNS, initiate async update and return immediately
                fetchAndUpdateAccount(accObj.Id);
                result.put('directCreditCheck', true);
                result.put('message', 'Credit check initiated successfully');
            } else {
                // Account doesn't have DUNS, signal LWC to start search
                result.put('directCreditCheck', false);
            }
            
            return result;
        } catch (Exception e) {
            System.debug('Error in performCreditCheck: ' + e.getMessage());
            result.put('success', false);
            result.put('message', e.getMessage());
            return result;
        }
    }

    @AuraEnabled
    public static Map<String, Object> checkCreditDataStatus(Id accountId) {
        try {
            Account acc = [SELECT Id, DnB_Failure_Score_Class__c, DnB_Standard_Rating__c FROM Account WHERE Id = :accountId LIMIT 1];
            
            // Polling is successful if key credit data is populated
            Boolean hasCreditData = (acc.DnB_Failure_Score_Class__c != null || acc.DnB_Standard_Rating__c != null);
            
            Map<String, Object> result = new Map<String, Object>();
            result.put('hasCreditData', hasCreditData);
            result.put('success', true);
            return result;
        } catch (Exception e) {
            Map<String, Object> result = new Map<String, Object>();
            result.put('success', false);
            result.put('message', e.getMessage());
            return result;
        }
    }

    @AuraEnabled
    @future(callout=true)
    public static void fetchAndUpdateAccount(Id accountId) {
        try {
            Account accObj = getAccountById(accountId);
            if (accObj == null || accObj.D_U_N_S_Number__c == null) {
                System.debug('No valid account or DUNS Number found for ID: ' + accountId);
                return;
            }

            String accessToken = getValidAccessToken();
            if (String.isBlank(accessToken)) {
                return;
            }
            String path = '/v1/data/duns/' + accObj.D_U_N_S_Number__c + '?blockIDs=' + BLOCK_IDS;
            HTTPResponse res = makeAPICall(path);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> organizationMap = (Map<String, Object>) responseMap.get('organization');
                
                if (organizationMap != null) {
                    Account accToUpdate = new Account(Id = accObj.Id);

                    accToUpdate.Name = (String) organizationMap.get('primaryName');

                    if (organizationMap.containsKey('telephone')) {
                        List<Object> phones = (List<Object>) organizationMap.get('telephone');
                        if (phones != null && !phones.isEmpty()) {
                            Map<String, Object> firstPhone = (Map<String, Object>) phones[0];                          
                            String phone = (String) firstPhone?.get('telephoneNumber');
                            // Apply formatting logic
                            if (!String.isBlank(phone) && !phone.startsWith('+') && phone.length() == 10) {
                                phone = '+1' + phone;
                            }
                            accToUpdate.Phone = phone;
                        }
                    }
                    
                    if (organizationMap.containsKey('primaryIndustryCode')) {
                        Map<String, Object> sic = (Map<String, Object>) organizationMap.get('primaryIndustryCode');
                        if (sic != null) {
                            accToUpdate.Sic = (String) sic.get('usSicV4');
                            accToUpdate.SicDesc = (String) sic.get('usSicV4Description');
                        }
                    }

                    if (organizationMap.containsKey('primaryAddress')) {
                        Map<String, Object> address = (Map<String, Object>) organizationMap.get('primaryAddress');
                        if (address != null) {
                            Map<String, Object> streetAddr = (Map<String, Object>) address.get('streetAddress');
                            if (streetAddr != null) accToUpdate.BillingStreet = (String) streetAddr.get('line1');
                            
                            Map<String, Object> locality = (Map<String, Object>) address.get('addressLocality');
                            if (locality != null) accToUpdate.BillingCity = (String) locality.get('name');

                            Map<String, Object> region = (Map<String, Object>) address.get('addressRegion');
                          //  if (region != null) accToUpdate.BillingState = (String) region.get('name');
                            
                            accToUpdate.BillingPostalCode = (String) address.get('postalCode');
                            
                            Map<String, Object> country = (Map<String, Object>) address.get('addressCountry');
                            if (country != null) accToUpdate.BillingCountry = (String) country.get('name');
                        }
                    }

                    if (organizationMap.containsKey('dnbAssessment')) {
                        Map<String, Object> dnbAssessmentMap = (Map<String, Object>) organizationMap.get('dnbAssessment');
                        Map<String, Object> failureScoreMap = (Map<String, Object>) dnbAssessmentMap.get('failureScore');
                        if (failureScoreMap != null) {
                            accToUpdate.DnB_Failure_Score_Class__c = String.valueOf(failureScoreMap.get('classScore'));
                            accToUpdate.DnB_Failure_Score_Description__c = (String) failureScoreMap.get('classScoreDescription');
                        }
                        Map<String, Object> standardRatingMap = (Map<String, Object>) dnbAssessmentMap.get('standardRating');
                        if (standardRatingMap != null) {
                            accToUpdate.DnB_Standard_Rating__c = (String) standardRatingMap.get('rating');
                            accToUpdate.DnB_Financial_Strength__c = (String) standardRatingMap.get('financialStrength');
                            accToUpdate.DnB_Risk_Segment__c = (String) standardRatingMap.get('riskSegment');
                        }
                    }

                    if(accToUpdate.getPopulatedFieldsAsMap().size() > 1) {
                        update accToUpdate;
                    }
                } else {
                    System.debug('No organization data found in response'); 
                }
            } else {
                System.debug('API Call failed: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in fetchAndUpdateAccount: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> searchCompaniesByName(String companyName) {
        try {
            if (String.isBlank(companyName)) {
                throw new AuraHandledException('Company name is required');
            }
            String accessToken = getValidAccessToken();
            String path = '/v1/search/typeahead?searchTerm=' + EncodingUtil.urlEncode(companyName, 'UTF-8');
            HTTPResponse res = makeAPICall(path);

            if (res.getStatusCode() == 200 && String.isNotBlank(res.getBody())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Map<String, Object>> companies = new List<Map<String, Object>>();
                if (responseMap.containsKey('searchCandidates')) {
                    List<Object> searchCandidates = (List<Object>) responseMap.get('searchCandidates');
                    for (Object candidate : searchCandidates) {
                        Map<String, Object> candidateMap = (Map<String, Object>) candidate;
                        Map<String, Object> organization = (Map<String, Object>) candidateMap.get('organization');
                        if (organization != null) {
                            Map<String, Object> companyInfo = new Map<String, Object>();
                            companyInfo.put('duns', String.valueOf(organization.get('duns')));
                            companyInfo.put('primaryName', String.valueOf(organization.get('primaryName')));
                            companyInfo.put('address', buildAddress(organization));
                            companies.add(companyInfo);
                        }
                    }
                }
                return companies;
            } else if (res.getStatusCode() == 400 || res.getStatusCode() == 404) {
                
               // throw new AuraHandledException('Error searching companies: ' + e.getMessage());
                return new List<Map<String, Object>>();
            }
            else {
                throw new AuraHandledException('DNB Search API failed: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in searchCompaniesByName: ' + e.getMessage());
            throw new AuraHandledException('Error searching companies: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateAccountWithDUNSAndFetchCredit(Id accountId, String selectedDUNS) {
        try {
            if (String.isBlank(selectedDUNS)) {
                throw new AuraHandledException('DUNS number is required');
            }
            Account accToUpdate = new Account(Id = accountId, D_U_N_S_Number__c = Decimal.valueOf(selectedDUNS));
            update accToUpdate;
            
            fetchAndUpdateAccount(accountId);
            
            return 'Success: Account updated with DUNS and data refresh initiated.';
        } catch (Exception e) {
            System.debug('Error in updateAccountWithDUNSAndFetchCredit: ' + e.getMessage());
            throw new AuraHandledException('Error updating account: ' + e.getMessage());
        }
    }

    // HELPER METHODS
    private static String buildAddress(Map<String, Object> organization) {
        List<String> addressParts = new List<String>();
        if (organization.containsKey('primaryAddress')) {
            Map<String, Object> address = (Map<String, Object>) organization.get('primaryAddress');
            if (address != null) {
                Map<String, Object> street = (Map<String, Object>) address.get('streetAddress');
                if (street != null && street.get('line1') != null) addressParts.add(String.valueOf(street.get('line1')));
                
                Map<String, Object> locality = (Map<String, Object>) address.get('addressLocality');
                if (locality != null && locality.get('name') != null) addressParts.add(String.valueOf(locality.get('name')));

                Map<String, Object> region = (Map<String, Object>) address.get('addressRegion');
                if (region != null && region.get('name') != null) addressParts.add(String.valueOf(region.get('name')));

                if (address.get('postalCode') != null) addressParts.add(String.valueOf(address.get('postalCode')));
            }
        }
        return addressParts.isEmpty() ? 'Address not available' : String.join(addressParts, ', ');
    }

    private static Account getAccountById(Id accountId) {
        return [SELECT Id, Name, D_U_N_S_Number__c FROM Account WHERE Id = :accountId LIMIT 1];
    }

    private static String getValidAccessToken() {
        return DnBTokenManager.getAccessToken();
    }

    
    private static HTTPResponse makeAPICall(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DnB_API_Data' + path);
        req.setMethod('GET');
        req.setTimeout(TIMEOUT_SECONDS);
        String accessToken = DnBTokenManager.getAccessToken();
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        
        return new Http().send(req);
    }

}