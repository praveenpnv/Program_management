global with sharing class ConvertStringToList {
	@InvocableMethod (Label='Convert comma separated string to list')
	global static List<List<String>> ConvertStringToList(List<String> inputStrings) {
		List<List<String>> results = new List<List<String>>();

		if (!inputStrings.isEmpty()) {
			for (String str : inputStrings) {
				if (String.isNotBlank(str)) {
					results.add(str.split('\\,'));
				}
			}
		}

		return results;
	}
}