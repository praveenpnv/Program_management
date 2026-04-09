/**
 * Created by iharpleshkov on 7.03.24.
 */

public with sharing class DSUtils {

	public static String ORG_ID = String.valueOf(UserInfo.getOrganizationId()).substring(0, 15);

	@AuraEnabled
	public static String getExternalId(String recordId) {
		try {
			String result;

			if (String.isNotBlank(recordId)) {
				result = ORG_ID + '_' + recordId.trim();
			}
			return result;
		} catch (Exception e) {
			throw new CustomException(e.getMessage());
		}
	}
	private class CustomException extends Exception {}
}