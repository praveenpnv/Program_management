public class MandatoryFieldValidator {
    public static void validateMandatoryFields(String objectName, List<SObject> records) {
        if (records == null || records.isEmpty()) return; // Exit if no records

        // Step 1: Collect unique Responsible_Opco__c values
        Set<String> opcoSet = new Set<String>();
        for (SObject record : records) {
            String opco = (String) record.get('Responsible_Opco__c');
            if (!String.isEmpty(opco)) {
                opcoSet.add(opco);
            }
        }

        if (opcoSet.isEmpty()) return; // No Opco values found

        // Step 2: Fetch relevant Mandatory Field Metadata
        Map<String, Id> mandatoryFieldMap = new Map<String, Id>();
        Map<Id, Set<String>> mandatoryFieldsByMandatoryField = new Map<Id, Set<String>>();

        for (Mandatory_Field__mdt mdt : [
            SELECT Id, Opco__c 
            FROM Mandatory_Field__mdt 
            WHERE Object__c = :objectName AND Opco__c IN :opcoSet
        ]) {
            if (!String.isEmpty(mdt.Opco__c)) {
                mandatoryFieldMap.put(mdt.Opco__c, mdt.Id);
                mandatoryFieldsByMandatoryField.put(mdt.Id, new Set<String>());
            }
        }

        if (mandatoryFieldMap.isEmpty()) return; // No mandatory field configurations

        // Step 3: Fetch field validation rules from Field_Format__mdt
        Map<String, String> fieldFormatMap = new Map<String, String>();
        Map<String, String> fieldMessageMap = new Map<String, String>(); // 🔹 NEW Map for format messages

        for (Field_Format__mdt fmt : [
            SELECT Field_Name__c, Field_Format__c, Format_Message__c, Mandatory_Field__c 
            FROM Field_Format__mdt 
            WHERE Mandatory_Field__c IN :mandatoryFieldMap.values()
        ]) {
            if (fmt.Field_Name__c != null && mandatoryFieldsByMandatoryField.containsKey(fmt.Mandatory_Field__c)) {
                mandatoryFieldsByMandatoryField.get(fmt.Mandatory_Field__c).add(fmt.Field_Name__c);

                if (!String.isEmpty(fmt.Field_Format__c)) {
                    fieldFormatMap.put(fmt.Field_Name__c, fmt.Field_Format__c);
                }
                if (!String.isEmpty(fmt.Format_Message__c)) { // 🔹 Store format message
                    fieldMessageMap.put(fmt.Field_Name__c, fmt.Format_Message__c);
                }
            }
        }

        if (mandatoryFieldsByMandatoryField.isEmpty()) return; // No mandatory fields found

        // Step 4: Fetch field labels for the object
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Map<String, String> fieldLabelMap = new Map<String, String>();

        for (Set<String> fieldSet : mandatoryFieldsByMandatoryField.values()) {
            for (String fieldName : fieldSet) {
                if (fieldName != null) {
                    fieldName = fieldName.trim();
                    if (fieldMap.containsKey(fieldName)) {
                        fieldLabelMap.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
                    }
                }
            }
        }

        // Step 5: Validate each record in bulk
        Map<Id, Map<String, String>> errorMessagesByRecord = new Map<Id, Map<String, String>>();

        for (SObject record : records) {
            String responsibleOpco = (String) record.get('Responsible_Opco__c');
            if (String.isEmpty(responsibleOpco) || !mandatoryFieldMap.containsKey(responsibleOpco)) {
                continue;
            }

            Id mandatoryFieldId = mandatoryFieldMap.get(responsibleOpco);
            Set<String> mandatoryFields = mandatoryFieldsByMandatoryField.get(mandatoryFieldId);

            if (mandatoryFields == null || mandatoryFields.isEmpty()) {
                continue;
            }

            Map<String, String> errorMessages = new Map<String, String>();

            for (String fieldName : mandatoryFields) {
                if (fieldName != null) {
                    fieldName = fieldName.trim();
                    if (!fieldMap.containsKey(fieldName)) continue;

                    Object fieldValue = record.get(fieldName);
                    String fieldLabel = fieldLabelMap.containsKey(fieldName) ? fieldLabelMap.get(fieldName) : fieldName;

                    // Mandatory Field Validation
                    if (fieldValue == null || String.isEmpty(String.valueOf(fieldValue).trim())) {
                        errorMessages.put(fieldName, fieldLabel + ' is mandatory.');
                    }

                    // Format Validation
                    if (fieldFormatMap.containsKey(fieldName) && fieldValue != null) {
                        String fieldFormat = fieldFormatMap.get(fieldName);
                        String formatMessage = fieldMessageMap.containsKey(fieldName) ? fieldMessageMap.get(fieldName) : 'Invalid format.'; // 🔹 FIXED!

                        if (!Pattern.compile(fieldFormat).matcher(String.valueOf(fieldValue)).matches()) {
                            String existingError = errorMessages.containsKey(fieldName) ? errorMessages.get(fieldName) + ' ' : '';
                            errorMessages.put(fieldName, existingError + formatMessage); // 🔹 Use custom message
                        }
                    }
                }
            }

            if (!errorMessages.isEmpty()) {
                errorMessagesByRecord.put(record.Id, errorMessages);
            }
        }

        // Step 6: Attach consolidated errors in bulk
        for (SObject record : records) {
            if (errorMessagesByRecord.containsKey(record.Id)) {
                for (String fieldName : errorMessagesByRecord.get(record.Id).keySet()) {
                    record.addError(fieldName, errorMessagesByRecord.get(record.Id).get(fieldName));
                }
            }
        }
    }
}