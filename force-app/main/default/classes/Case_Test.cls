@isTest(SeeallData=True)
private class Case_Test 
{
    @isTest
    private static void test1() 
    {
        Case c = new Case(Origin='Codealike', SuppliedEmail='request@codealike.com',Description = 'sumit@a.com----------------Codealike Support Request First name: adam');
        insert c;
    }
}