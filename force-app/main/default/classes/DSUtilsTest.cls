@IsTest
public with sharing class DSUtilsTest {

	@IsTest
	public static void test(){
		Test.startTest();
		DSUtils.getExternalId('12123123231131');
		Test.stopTest();
	}
}