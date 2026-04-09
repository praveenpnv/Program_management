public with sharing class SaveToListController {

	private static final String TEXTKERNEL_LIST_CUSTOM_FIELDS_FIELDSET_NAME = 'TextkernelListCustomFields';

	@AuraEnabled
	public static String getSearchFromLookups() {
		try {
			Map<String, String> lookups = new Map<String, String>();

			for (SObjectField field : TextkernelList__c.SObjectType.getDescribe()?.fields?.getMap()?.values()) {
				if (field.getDescribe().getType() == Schema.DisplayType.REFERENCE && field.getDescribe().isCustom() == true && field.getDescribe().isUpdateable() == true) { lookups.put(field.getDescribe().getReferenceTo().get(0).getDescribe().getName(), field.getDescribe().getName()); }
			}

			if (lookups.size() != 0) { return JSON.serialize(lookups); }
		} catch (Exception e) { throwException(e.getMessage()); }
		return null;
	}

	@AuraEnabled
	public static void saveRecordsToList(String listId, List<String> recordIds) {
		try {
			if (String.isBlank(listId) && recordIds.size() == 0) { return; }

			// get object api name for records in list
			String objectDevName = Id.valueOf(getRecordId(recordIds[0])).getSobjectType().getDescribe().getName();

			if (String.isBlank(objectDevName)) { throwException('Can\'t find SObject type for Id: ' + recordIds[0]); }

			// get lookup field to object
			String lookupDevName;

			for (SObjectField field : TextkernelListItem__c.SObjectType.getDescribe().fields.getMap().values()) {
				DescribeFieldResult dfr = field.getDescribe();
				if (
					dfr.getType()                                   == Schema.DisplayType.REFERENCE &&
					dfr.getReferenceTo()[0].getDescribe().getName() == objectDevName
				) {
					lookupDevName = dfr.getName();
					break;
				}
			}

			if (String.isBlank(lookupDevName)) { throwException('Can\'t find reference field from ' + TextkernelListItem__c.SObjectType.getDescribe().getName() + ' to ' + objectDevName); }

			// get ids of records already in list
			Set<String> existingItems = new Set<String>();

			for (SObject existingItem : Database.query('SELECT Id, ' + lookupDevName + ' FROM TextkernelListItem__c WHERE TextkernelList__c = :listId')) {
				if (existingItem.get(lookupDevName) == null) { continue; }
				existingItems.add(String.valueOf(existingItem.get(lookupDevName)));
			}

			List<TextkernelListItem__c> listItems = new List<TextkernelListItem__c>();
			for (String recordId : recordIds) {
				recordId = getRecordId(recordId);

				if (existingItems.contains(recordId)) { continue; }

				TextkernelListItem__c listItem = new TextkernelListItem__c(TextkernelList__c = listId);
				listItem.put(lookupDevName, recordId);
				listItems.add(listItem);
			}

			if (listItems.size() == 0) { return; }
			insert listItems;
		} catch (Exception e) { throwException(e.getMessage()); }
	}

	@AuraEnabled
	public static String getFieldSetFields() {
		try {
			Schema.FieldSet fieldSet = TextkernelList__c.SObjectType.getDescribe().fieldSets.getMap()?.get(TEXTKERNEL_LIST_CUSTOM_FIELDS_FIELDSET_NAME);

			if (fieldSet == null) { return null; }

			List<Map<String, Object>> resultFields = new List<Map<String, Object>>();

			for (Schema.FieldSetMember fieldSetMember : fieldSet.getFields()) {
				DescribeFieldResult dfr = fieldSetMember.getSObjectField().getDescribe();
				if (dfr.isAccessible() && (dfr.isUpdateable() || dfr.isCalculated())) {
					resultFields.add (
						new Map<String, Object> {
							'label'    => fieldSetMember.label,
							'path'     => fieldSetMember.fieldPath,
							'required' => fieldSetMember.required
						}
					);
				}
			}

			if (resultFields.size() != 0) { return JSON.serialize(resultFields);}
		} catch (Exception e) { throwException(e.getMessage()); }
		return null;
	}

	private static String getRecordId(String compoundRecordId) {

		if (String.isBlank(compoundRecordId)) { return null; }

		List<String> parts = compoundRecordId.split('_');

		return parts[parts.size() == 2 ? 1 : 0];
	}

	@TestVisible
	private static void throwException(String message) {
		AuraHandledException e = new AuraHandledException(message);
		e.setMessage(message);
		throw e;
	}
}