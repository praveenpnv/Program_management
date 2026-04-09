/**
* JobAdGeneratorController.cls - Optimized Apex Controller
* @description Handles Job Ad generation with configurable fields
* @date 2025
*/
public with sharing class JobAdGeneratorController {
    private static final String API_BASE_URL = 'callout:Job_Ad_Generator_NC';
    private static final Integer TIMEOUT_SECONDS = 120;
    
    //Get configurable fields from Custom Metadata
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getIncludeFieldsConfig() {
        List<Map<String, Object>> fields = new List<Map<String, Object>>();
        
        try {
            // Fetch Custom Metadata
            List<Job_Ad_Field__mdt> fieldConfigs = [
                SELECT Label, Field_API_Name__c, Is_Active__c 
                FROM Job_Ad_Field__mdt 
                WHERE Is_Active__c = true 
                ORDER BY Sort_Order__c ASC NULLS LAST, Label ASC
            ];
            
            for (Job_Ad_Field__mdt config : fieldConfigs) {
                fields.add(new Map<String, Object>{
                    'label' => config.Label,
                        'apiName' => config.Field_API_Name__c,
                        'isActive' => config.Is_Active__c
                        });
            }
        } catch (Exception e) {
            System.debug('⚠️ Metadata load failed, returning defaults: ' + e.getMessage());
            return getDefaultFields();
        }
        
        return fields;
    }
    
    /**
* Fallback default fields if metadata is missing or fails
*/
    private static List<Map<String, Object>> getDefaultFields() {
        return new List<Map<String, Object>>{
            new Map<String, Object>{ 'label' => 'Work Location', 'apiName' => 'Billing_Country__c', 'isActive' => true },
                new Map<String, Object>{ 'label' => 'Industry', 'apiName' => 'TR1__Industry__c', 'isActive' => true },
                    new Map<String, Object>{ 'label' => 'Education Requirements', 'apiName' => 'Education_Requirements__c', 'isActive' => true },
                        new Map<String, Object>{ 'label' => 'Required Skills', 'apiName' => 'Generated_Skills_List', 'isActive' => true }
        };
            }
    
    /**
* Generate job ad from Job record
* Optimization: Accepts Map instead of JSON string to save CPU time
*/
    @AuraEnabled
    public static Map<String, Object> generateJobAdFromJob(Map<String, Object> requestData) {
        try {
            if (requestData == null || requestData.isEmpty()) {
                throw new CalloutException('Request data is empty');
            }
            
            String jobRecordId = (String) requestData.get('jobRecordId');
            String apiKey = getApiKeyFromSettings();
            String endPointUrl = getEndpointPath();
            
            // Build strictly typed API Request
            Map<String, Object> apiRequestBody = new Map<String, Object>{
                'intake_notes' => requestData.get('intake_notes'),
                    'language' => requestData.get('language'),
                    'country' => requestData.get('country'),
                    'brand' => requestData.get('brand')
                    };
                        
                        // Make Callout
                        HttpResponse response = makeApiCallout(apiKey,endPointUrl, apiRequestBody);
            
            // Deserialize Response
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            if (response.getStatusCode() == 200) {
                // Update Job Record if ID is present
                if (String.isNotBlank(jobRecordId)) {
                    updateJobWithGeneratedAd(jobRecordId, responseMap);
                }
                return responseMap;
            } else {
                // Handle API Errors
                String errorDetail = response.getStatus();
                if (responseMap.containsKey('detail')) {
                    errorDetail = (String) responseMap.get('detail');
                }
                throw new CalloutException('API Error (' + response.getStatusCode() + '): ' + errorDetail);
            }
            
        } catch (Exception e) {
            System.debug('❌ Error generating ad: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
* Update Job record with generated ad securely
*/
    private static void updateJobWithGeneratedAd(String jobRecordId, Map<String, Object> responseMap) {
        try {
            String jobAdText = extractJobAdText(responseMap);
            
            if (String.isNotBlank(jobAdText)) {
                TR1__Job__c job = new TR1__Job__c(
                    Id = jobRecordId,
                    Generated_Job_Ad__c = jobAdText
                );
                
                // SECURITY: Enforce Field Level Security (FLS)
                update as user job; 
            }
        } catch (Exception e) {
            System.debug('⚠️ Warning: Could not update job record: ' + e.getMessage());
        }
    }
   //get worksite address 
 

@AuraEnabled(cacheable=false)
public static Map<String, String> getJobAddress(Id jobId) {
    try {
        // Query the compound address field
        TR1__Job__c job = [
            SELECT Worksite_Address__c
            FROM TR1__Job__c
            WHERE Id = :jobId
            LIMIT 1
        ];
        
        // Initialize result map
        Map<String, String> addressMap = new Map<String, String>{
            'street' => '',
            'city' => '',
            'state' => '',
            'stateCode' => '',
            'postalCode' => '',
            'country' => '',
            'countryCode' => ''
        };
        
        // Extract address components if available
        if (job.Worksite_Address__c != null) {
            Address addr = job.Worksite_Address__c;
            
            addressMap.put('street', addr.getStreet() != null ? addr.getStreet() : '');
            addressMap.put('city', addr.getCity() != null ? addr.getCity() : '');
            addressMap.put('state', addr.getState() != null ? addr.getState() : '');
            addressMap.put('stateCode', addr.getStateCode() != null ? addr.getStateCode() : '');
            addressMap.put('postalCode', addr.getPostalCode() != null ? addr.getPostalCode() : '');
            addressMap.put('country', addr.getCountry() != null ? addr.getCountry() : '');
            addressMap.put('countryCode', addr.getCountryCode() != null ? addr.getCountryCode() : '');
        }
        
        System.debug('Address Map: ' + addressMap);
        return addressMap;
        
    } catch (Exception e) {
        System.debug('Error fetching address: ' + e.getMessage());
        throw new AuraHandledException('Error fetching job address: ' + e.getMessage());
    }
}
    
    // --- Private Helpers ---
    
    private static String extractJobAdText(Map<String, Object> responseMap) {
        if (responseMap.containsKey('content')) {
            Map<String, Object> content = (Map<String, Object>) responseMap.get('content');
            return (String) content.get('job_ad');
        }
        return (String) responseMap.get('job_ad');
    }
    
    private static String getApiKeyFromSettings() {
        //JobAdGeneratorSettings__c settings = JobAdGeneratorSettings__c.getOrgDefaults();
        JobAdGeneratorSettingsProd__c settings = JobAdGeneratorSettingsProd__c.getOrgDefaults(); 
        if (settings == null || String.isBlank(settings.Api_Key__c)) {
            throw new CalloutException('API Key not configured in Custom Settings');
        }
        return settings.Api_Key__c.trim();
    }
    private static String getEndpointPath() {
        //JobAdGeneratorSettings__c settings = JobAdGeneratorSettings__c.getOrgDefaults();
         JobAdGeneratorSettingsProd__c settings = JobAdGeneratorSettingsProd__c.getOrgDefaults();
        if (settings == null || String.isBlank(settings.Endpoint_Path__c)) {
            throw new CalloutException('End point not configured in Custom Settings');
        }
        return settings.Endpoint_Path__c;
    }
    
    private static HttpResponse makeApiCallout(String apiKey,String endPointUrl, Map<String, Object> requestBody) {
        HttpRequest req = new HttpRequest();
        String endpoint = API_BASE_URL + endPointUrl + '?key=' + EncodingUtil.urlEncode(apiKey, 'UTF-8');
        
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_SECONDS * 1000); // 120s
        req.setBody(JSON.serialize(requestBody));
        
        return new Http().send(req);
    }
}