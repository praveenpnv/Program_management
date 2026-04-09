@IsTest(IsParallel=false)
public with sharing class SaveToListControllerTest {

	@IsTest
	public static void test_getSearchFromLookups() {
		System.assertEquals(null, SaveToListController.getSearchFromLookups(), 'Wrong result count of converted strings');
	}

	@IsTest
	public static void test_saveRecordsToList() {
		TextkernelList__c list1 = new TextkernelList__c(Name = 'list1');
		Textkernel1__TestRootObject__c obj1 = new Textkernel1__TestRootObject__c(Name = 'obj1');

		insert new List<SObject>{list1, obj1};

		SaveToListController.saveRecordsToList(list1.Id, new List<String>{obj1.Id});

		List<TextkernelList__c> results = [SELECT Id,
													Name,
													(SELECT Id,
															Name,
															TestObject__c
													FROM ListItems__r)
											FROM TextkernelList__c];

		System.assertEquals(1, results.size(), 'Wrong count of saved lists');

		System.assertEquals(1, results.get(0).ListItems__r.size(), 'Wrong count of saved lists');
		System.assertEquals(obj1.Id, results.get(0).ListItems__r.get(0).TestObject__c, 'Wrong count of saved lists');
	}


	@IsTest
	public static void test_getFieldSetFields() {
		System.assertEquals(null, SaveToListController.getFieldSetFields(), 'Wrong list of fields');
	}

	@IsTest
	public static void test_Coverage() {
		try {
			SaveToListController.throwException('CustomException');
			System.assert(false);
		} catch (Exception e) {
			System.assertEquals('CustomException', e.getMessage());
			System.assertEquals('System.AuraHandledException', e.getTypeName());
		}
	}

}