public class MandatoryFieldValidatorByRecType {

    @InvocableMethod(label='Validate Records by Record Type and OpCo' description='Validates mandatory fields and formats of records based on Record Type and Responsible OpCo__c using metadata.')
    public static List<ValidateFieldsResult> validateRecordsInFlow(List<ValidateFieldsRequest> requests) {
        List<ValidateFieldsResult> results = new List<ValidateFieldsResult>();
        for (ValidateFieldsRequest request : requests) {
            List<SObject> recordsToValidate = request.records;
            String objectName = request.objectApiName;
            List<RecordFieldError> recordErrors = validateMandatoryFields(objectName, recordsToValidate);
            results.add(new ValidateFieldsResult(recordErrors));
        }
        return results;
    }
	private static Boolean hasRun = false;
    public static List<RecordFieldError> validateMandatoryFields(String objectName, List<SObject> records) {
        List<RecordFieldError> allErrors = new List<RecordFieldError>();
        if (hasRun) return allErrors; hasRun = true; // Prevents re-entry in same transaction                         
        if (records == null || records.isEmpty()) return allErrors;
        if(torcRD1Integration.runningtorcCodeToUpdateData)return allErrors; // Exit if Torc updating fields

        // ----- DESCRIBE (moved up once) -----
        Schema.SObjectType sobType = Schema.getGlobalDescribe().get(objectName); // 🔹 NEW
        Schema.DescribeSObjectResult objectDescribe = sobType.getDescribe();     // 🔹 NEW
        Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap(); // 🔹 NEW
        Map<Id, Schema.RecordTypeInfo> recordTypeInfoMap = objectDescribe.getRecordTypeInfosById(); // 🔹 CHANGED (from chained call)

        // Step 1: Collect unique Responsible_Opco__c values
        Set<String> opcoSet = new Set<String>();
        for (SObject record : records) {
            String opco = (String) record.get('Responsible_Opco__c');
            if (!String.isEmpty(opco)) {
                opcoSet.add(opco);
            } else {
                opcoSet.add(Test.isRunningTest() ? 'Australia' : 'US');
            }
        }
        if (opcoSet.isEmpty()) return allErrors;

        // Step 2: Fetch relevant Mandatory Field Metadata
        Map<String, Id> mandatoryFieldMap = new Map<String, Id>();
        Map<Id, Set<String>> mandatoryFieldsByMandatoryField = new Map<Id, Set<String>>();

        List<Mandatory_Field__mdt> listOfMandatoryFieldmdt = [
            SELECT Id, Opco__c
            FROM Mandatory_Field__mdt
            WHERE Object__c = :objectName AND Opco__c IN :opcoSet
        ];

        for (Mandatory_Field__mdt mdt : listOfMandatoryFieldmdt) {
            if (!String.isEmpty(mdt.Opco__c)) {
                mandatoryFieldMap.put(mdt.Opco__c, mdt.Id);
                mandatoryFieldsByMandatoryField.put(mdt.Id, new Set<String>());
            }
        }
        if (mandatoryFieldMap.isEmpty()) return allErrors;

        // Step 3: Fetch field validation rules from Field_Format__mdt
        Map<String, String> fieldFormatMap = new Map<String, String>();
        Map<String, String> fieldMessageMap = new Map<String, String>();
        Map<String, String> formulaMap = new Map<String, String>();
        Map<String, String> subFieldMap = new Map<String, String>();
        Map<String, Set<String>> validRecordTypesByField = new Map<String, Set<String>>();

        List<Field_Format__mdt> formats = [
            SELECT Field_Name__c, Field_Format__c, Format_Message__c, Formula__c, Mandatory_Field__c, Record_Type__c
            FROM Field_Format__mdt
            WHERE Mandatory_Field__c IN :mandatoryFieldMap.values()
        ];
        for (Field_Format__mdt fmt : formats) {
            if (fmt.Field_Name__c != null && mandatoryFieldsByMandatoryField.containsKey(fmt.Mandatory_Field__c)) {
                mandatoryFieldsByMandatoryField.get(fmt.Mandatory_Field__c).add(fmt.Field_Name__c);

                if (!validRecordTypesByField.containsKey(fmt.Field_Name__c)) {
                    validRecordTypesByField.put(fmt.Field_Name__c, new Set<String>());
                }
                if (!String.isEmpty(fmt.Record_Type__c)) {
                    validRecordTypesByField.get(fmt.Field_Name__c).addAll(fmt.Record_Type__c.split(';'));
                }
                if (!String.isEmpty(fmt.Field_Format__c)) {
                    fieldFormatMap.put(fmt.Field_Name__c, fmt.Field_Format__c);
                }
                if (!String.isEmpty(fmt.Format_Message__c)) {
                    fieldMessageMap.put(fmt.Field_Name__c, fmt.Format_Message__c);
                }
                if (!String.isEmpty(fmt.Formula__c)) {
                    formulaMap.put(fmt.Field_Name__c, fmt.Formula__c);
                }
            }
        }

        // 🔹 Move compound address validation logic here (unchanged structurally)
        Set<String> compoundFieldsToRemove = new Set<String>();

        for (String fieldName : formulaMap.keySet()) {
            if (!fieldsMap.containsKey(fieldName)) continue;

            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();

            if (fieldDescribe.getType() == Schema.DisplayType.ADDRESS) {
                for (Schema.SObjectField subfield : fieldsMap.values()) {
                    Schema.DescribeFieldResult subfieldDescribe = subfield.getDescribe();

                    if (subfieldDescribe.getCompoundFieldName() == fieldName) {
                        String subNameLower = subfieldDescribe.getName().toLowerCase();
                        if (!formulaMap.containsKey(subfieldDescribe.getName())) {
                            if (!(subNameLower.contains('latitude') ||
                                  subNameLower.contains('longitude') ||
                                  (subNameLower.contains('country') && !subNameLower.contains('countrycode')) ||
                                  (subNameLower.contains('state') && !subNameLower.contains('statecode')) ||
                                  subNameLower.contains('geocodeaccuracy'))) {
                                subFieldMap.put(subfieldDescribe.getName(), formulaMap.get(fieldName));
                                if (validRecordTypesByField.containsKey(fieldName)) {
                                    validRecordTypesByField.put(subfieldDescribe.getName(), validRecordTypesByField.get(fieldName));
                                }
                            }
                        }
                    }
                }
                compoundFieldsToRemove.add(fieldName);
            }
        }

        // Remove compound fields from formulaMap & add subfields
        for (String compoundField : compoundFieldsToRemove) {
            formulaMap.remove(compoundField);
        }
        formulaMap.putAll(subFieldMap);

        Map<String, Schema.SObjectField> fieldMap = fieldsMap; // 🔹 keep your variable name

        Map<String, String> fieldLabelMap = new Map<String, String>();
        for (String compoundField : subFieldMap.keySet()) {
            fieldLabelMap.put(compoundField, fieldMap.get(compoundField).getDescribe().getLabel());
        }

        if (mandatoryFieldsByMandatoryField.isEmpty()) return allErrors;

        // Step 4: Fetch field labels for the object
        for (Set<String> fieldSet : mandatoryFieldsByMandatoryField.values()) {
            for (String fieldName : fieldSet) {
                if (fieldName != null) {
                    String k = fieldName.trim();
                    if (fieldMap.containsKey(k)) {
                        fieldLabelMap.put(k, fieldMap.get(k).getDescribe().getLabel());
                    }
                }
            }
        }

        // ---------- 🔹 NEW: CACHES ----------
        // Compile regex patterns once per field
        Map<String, Pattern> patternCache = new Map<String, Pattern>();
        for (String f : fieldFormatMap.keySet()) {
            try {
                patternCache.put(f, Pattern.compile(fieldFormatMap.get(f)));
            } catch (Exception e) {
                // if bad regex, skip caching; runtime will surface message via addError below
                patternCache.put(f, null);
            }
        }

        // Compile formulas once per field
        Map<String, FormulaEval.FormulaInstance> formulaCache = new Map<String, FormulaEval.FormulaInstance>();
        for (String f : formulaMap.keySet()) {
            try {
                FormulaEval.FormulaInstance fi =
                    Formula.builder()
                        .withReturnType(FormulaEval.FormulaReturnType.Boolean)
                        .withType(sobType)
                        .withFormula(formulaMap.get(f))
                        .build();
                formulaCache.put(f, fi);
            } catch (Exception e) {
                formulaCache.put(f, null); // mark bad compile; we’ll message per-record below
            }
        }

        // Cache RecordTypeId -> DeveloperName
        Map<Id, String> rtIdToDevName = new Map<Id, String>();
        for (SObject r : records) {
            Id rtId = (Id) r.get('RecordTypeId');
            if (rtId != null && !rtIdToDevName.containsKey(rtId)) {
                Schema.RecordTypeInfo rti = recordTypeInfoMap.get(rtId);
                rtIdToDevName.put(rtId, rti == null ? '' : rti.getDeveloperName());
            }
        }
        // ---------- end caches ----------

        // Step 5: Validate each record in bulk and store errors
        List<RecordFieldError> recordSpecificErrors = new List<RecordFieldError>();

        for (SObject record : records) {
            String responsibleOpco = (String) record.get('Responsible_Opco__c');
            if (String.isEmpty(responsibleOpco)) {
                responsibleOpco = Test.isRunningTest() ? 'Australia' : 'US';
            }
            if (String.isEmpty(responsibleOpco) || !mandatoryFieldMap.containsKey(responsibleOpco)) {
                continue;
            }

            Id mandatoryFieldId = mandatoryFieldMap.get(responsibleOpco);
            Set<String> mandatoryFields = mandatoryFieldsByMandatoryField.get(mandatoryFieldId);
            if (mandatoryFields != null) {
                for (String compoundField : compoundFieldsToRemove) {
                    mandatoryFields.remove(compoundField);
                }
                for (String compoundField : subFieldMap.keySet()) {
                    mandatoryFields.add(compoundField);
                }
            }
            if (mandatoryFields == null || mandatoryFields.isEmpty()) continue;

            Map<String, String> errorMessages = new Map<String, String>();

            Id recordTypeId = (Id) record.get('RecordTypeId');
            String recordDevName = (recordTypeId != null && rtIdToDevName.containsKey(recordTypeId))
                ? rtIdToDevName.get(recordTypeId) : '';

            for (String fieldName : mandatoryFields) {
                if (fieldName == null) continue;
                String key = fieldName.trim();
                if (!fieldMap.containsKey(key)) continue;

                Object fieldValue = record.get(key);
                String fieldLabel = fieldLabelMap.containsKey(key) ? fieldLabelMap.get(key) : key;

                Set<String> allowedRTs = validRecordTypesByField.get(key);
                Boolean rtAllowed = (allowedRTs == null || allowedRTs.isEmpty() || allowedRTs.contains(recordDevName));

                Boolean isBlank = (fieldValue == null) || String.isEmpty(String.valueOf(fieldValue).trim());

                // Mandatory Field Validation (config-based)
                if (isBlank && !formulaMap.containsKey(key) && rtAllowed) {
                    String errorMessage = fieldLabel + ' is mandatory.';
                    errorMessages.put(key, errorMessage);
                    record.addError(key, errorMessage);
                }

                // Format Validation — use cached Pattern
                if (!isBlank && fieldFormatMap.containsKey(key)) {
                    Pattern p = patternCache.get(key); // 🔹 CHANGED
                    if (p == null || !p.matcher(String.valueOf(fieldValue)).matches()) {
                        String errorMessage = fieldMessageMap.containsKey(key) ? fieldMessageMap.get(key) : 'Invalid format.';
                        errorMessages.put(key, errorMessage);
                        record.addError(key, errorMessage);
                    }
                }

                // Formula-driven mandatory — use cached FormulaInstance
                if (isBlank && rtAllowed && formulaMap.containsKey(key)) {
                    FormulaEval.FormulaInstance fi = formulaCache.get(key); // 🔹 CHANGED
                    if (fi == null) {
                        String msg = fieldMessageMap.containsKey(key) ? fieldMessageMap.get(key) : 'Error compiling formula.';
                        errorMessages.put(key, msg);
                        record.addError(key, msg);
                    } else {
                        try {
                            Boolean result = (Boolean) fi.evaluate(record);
                            if (result) {
                                String formulaMessage = fieldMessageMap.containsKey(key) ? fieldMessageMap.get(key) : 'Formula validation failed.';
                                errorMessages.put(key, formulaMessage);
                                record.addError(key, formulaMessage);
                            }
                        } catch (Exception e) {
                            String msg = 'Error evaluating formula: ' + e.getMessage();
                            errorMessages.put(key, msg);
                            record.addError(key, msg);
                        }
                    }
                }
            }

            if (!errorMessages.isEmpty()) {
                for (String fieldWithError : errorMessages.keySet()) {
                    recordSpecificErrors.add(new RecordFieldError(record.Id, fieldWithError, errorMessages.get(fieldWithError)));
                }
            }
        }

        return recordSpecificErrors;
    }

    public class ValidateFieldsRequest {
        @AuraEnabled
        @InvocableVariable(required=true)
        public String objectApiName;

        @AuraEnabled
        @InvocableVariable(required=true)
        public List<SObject> records;

        public ValidateFieldsRequest() {}
    }

    public class ValidateFieldsResult {
        @AuraEnabled
        @InvocableVariable
        public List<RecordFieldError> recordFieldErrors;

        public ValidateFieldsResult(List<RecordFieldError> recordFieldErrors) {
            this.recordFieldErrors = recordFieldErrors;
        }
    }
}