@IsTest(isParallel=false)
public with sharing class ConvertStringToListTest {

	@isTest
	public static void test_ConvertStringToList() {
		List<List<String>> results = ConvertStringToList.ConvertStringToList(new List<String>{
			'1',
			'1,2,3'
		});

		System.assertEquals(2, results.size(), 'Wrong result count of converted strings');

		System.assertEquals(1, results[0].size(), 'Wrong result count of converted items');
		System.assertEquals('1', results[0].get(0), 'Wrong value of converted string');

		System.assertEquals(3, results[1].size(), 'Wrong result count of converted items');
		System.assertEquals('1', results[1].get(0), 'Wrong value of converted string');
		System.assertEquals('2', results[1].get(1), 'Wrong value of converted string');
		System.assertEquals('3', results[1].get(2), 'Wrong value of converted string');
	}
}