@isTest
public class GoogleAPITest
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData();
    }
    public static string qooglLoadType='USER';
    private static opportunity setup()
    {
        Account act = new Account(Name='MyAccount',Payment_terms__c='Net 10',Invoice_Group_Type__c='Combined-Account',Quickbooks_Id__c='1001');
        insert act;
        Opportunity opp=new Opportunity(AccountId=act.id,Name='testMethod',CloseDate=date.Today(),StageName='Need Identification');
        insert opp;
        return opp;
    }
    @isTest
    private static void nonTrocTest1() 
    {
        Opportunity opp = setup();
        Pagereference pg = Page.loadQubikaData;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id', opp.accountId);
        ApexPages.StandardController sc = new ApexPages.StandardController(new Account(id=opp.AccountId));
        loadQubikaData controller = new loadQubikaData(sc);
        controller.sheetName='Sheet1';
        controller.sheetRange='A1:H';
        controller.spreadsheetId='Test';
        controller.loaddata();
        controller.updateData();
        
        Trolley_Recipient__c tr=new Trolley_Recipient__c(external_Id__c = 'externalId121', referenceId__c = 'devdevdev@dev.dev',Status__c='active',estimated_Fee__c=5);
        insert tr;
        
        Non_Torc_user__c nu = [Select Id, Explicit_Docusign_Mark_Complete__c from Non_Torc_user__c where Official_Email__c='devdevdev@dev.dev'];
        nu.Explicit_Docusign_Mark_Complete__c = true;
        update nu;
        
        qooglLoadType = 'PAYMENT';
        pg = Page.nonTorcpayment;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id', opp.id);
        sc = new ApexPages.StandardController(opp);
        nonTorcpayment controller1 = new nonTorcpayment(sc);
        controller1.sheetName='Sheet1';
        controller1.sheetRange='A1:C';
        controller1.spreadsheetId='Test';
        controller1.loaddata();
        controller1.updateData();
        controller1.getTotalbankFee();
        controller1.getTotalTorcFee();
        controller1.getShowTypes();
        controller1.getshowableRows();
        
        pg = Page.TrolleyNonQBPayments;
        Test.setCurrentPageReference(pg);
        System.currentPageReference().getParameters().put('id', opp.id);
        sc = new ApexPages.StandardController(opp);
        TrolleyNonQBPayments controller2 = new TrolleyNonQBPayments(sc);
        for(TrolleyNonQBPayments.DataRow  dr:controller2.lstDataRow)
        {
            dr.chk=true;
        }
        controller2.next();
        controller2.CreatePaymentsInTrolleyNew();
        controller2.reloadRecipient();
        controller2.dummyCall();   
        externalPlacementAccount e=new externalPlacementAccount();     
    }
    @isTest
    private static void qubikaOperationtest() 
    {
        Opportunity opp = setup();
        QubikaOperation controller = new QubikaOperation();
        controller.getShowTypes();
        controller.getDates();
        controller.filename='abc.csv';
        string s = 'Name,Email,Qubika Email,Start Date,Payment Start Date,Role,Country,USD Monthly,Monthly Expense,Terminated (Last day/Month)\n'+
                    'TestUser1 TestLN1,Test1@testuser.com,Test1@testuser.com,8/28/2023,8/31/2023,UX/UI Designer,Argentina,"$1,200.00",$100.00,\n'+
                    'TestUser2 TestLN2,Test2@testuser.com,Test2@testuser.com,8/28/2023,10/31/2023,UX/UI Designer,Argentina,"$2,200.00",$0.00,';
        controller.file = blob.valueOf(s);                    
        controller.loadcontactData();
        controller.updateContacts();
        controller.back();
        
        s='Qubika Email,Total Amount\n'+
            'Test1@testuser.com,1000\n'+
            'Test2@testuser.com,1000';
        controller.filename='abc.csv';
        controller.file = blob.valueOf(s);                    
        controller.loadpaymemntData();
        controller.getshowableRows();
        controller.getTotalbankFee();
        controller.getTotalTorcFee();
        controller.getTotalEmployeePayment();
        controller.lstPayments[0].getQubikaUserName();
        controller.lstPayments[0].getTrolleyStatus();
        controller.lstPayments[0].getDocusignStatus();
        controller.lstPayments[0].getBankFee();
        controller.lstPayments[0].getTrolleyPayoutMethod();
        
        
        
        controller.updatePayments();
        controller.dummyDate.Date__c=date.today().adddays(1000);
        controller.loadOpportunityAndLineItem();
        controller.backToLogin();
        controller.emailAddress='';
        controller.VerifyEmailAddress();
        Qubika_Employee__c q=new Qubika_Employee__c(Account__c = Torc_Constants__c.getInstance().Qubika_Account__c,name='Sumit Mishra',email__c='sumit@rtester.rest',Profile__c='Admin');
        insert q;
        controller.emailAddress='sumit@rtester.rest';
        controller.VerifyEmailAddress();
        controller.SendToverify();
        controller.verifycode1=controller.verifycode2=controller.verifycode3=controller.verifycode4='1';
        controller.verifyCode();
        
        
    }        
}