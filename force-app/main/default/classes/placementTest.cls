@isTest
private class placementTest 
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData();
        testUtils.deactivateVR();
    }
    @isTest
    private static void Test1() 
    {
        OpportunityLineItem oLine= [Select ID, OpportunityId,Torc_user__c from OpportunityLineItem where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
        Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified');
        update opp;
        test.startTest();
        Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Closed Won');
        update opp;
        Torc_User__c tu = [Select Id,Name from Torc_user__c where id!=:oLine.Torc_user__c LIMIT 1];
        oLine.Talent_username__c = tu.Name;
        update tu;
        test.stopTest();
        placement.addWorkingDays(Date.today(),15);
    }
     @isTest
    private static void Test1Ext() 
    {
        OpportunityLineItem oLine= [Select ID, OpportunityId,Torc_user__c from OpportunityLineItem where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL AND opportunity.Torc_Opportunity__c = TRUE Order By Opportunity.CloseDate DESC LIMIT 1];
        Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified', Create_Forecast__c=true);
        update opp;
        test.startTest();
        Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified', Create_Forecast__c=false);
        update opp;
        test.stopTest();
    }
    @isTest
    private static void Test2() 
    {
        OpportunityLineItem oLine= [Select 
        Id, OpportunityId, PricebookEntryId, Product2Id, ProductCode, Name, Quantity, UnitPrice, ListPrice, ServiceDate, Description, Customer_Hourly_Bill_Rate__c, Engagement_Duration_weeks__c, Weekly_Bill_Rate__c, Engagement_Start_Date__c, Torc_User__c, Talent_Hourly_Pay_Rate__c, Talent_Name__c, Weekly_Talent_Rate__c, Talent_Username__c, Engagement_End_Date__c, Product_Code_Text__c, Hours_Week__c, Product_Type__c, Product_Category__c
         from OpportunityLineItem 
         where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
        Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified');
        update opp;
        test.startTest();
        Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Closed Won');
        update opp;
        OpportunityLineItem oLine1 = oLine.Clone(false, false, false, false);
        oLine1.Engagement_Start_Date__c = Date.newInstance(2022,1,26);
        oLine1.Engagement_Duration_weeks__c = 20;
        insert oLine1;
        Delete oLine1;
        test.stopTest();
    }
    @isTest
    private static void Test3() 
    {
        OpportunityLineItem oLine= [Select 
                Id, OpportunityId, PricebookEntryId, Product2Id, ProductCode, Name, Quantity, UnitPrice, ListPrice, ServiceDate, Description, Customer_Hourly_Bill_Rate__c, Engagement_Duration_weeks__c, Weekly_Bill_Rate__c, Engagement_Start_Date__c, Torc_User__c, Talent_Hourly_Pay_Rate__c, Talent_Name__c, Weekly_Talent_Rate__c, Talent_Username__c, Engagement_End_Date__c, Product_Code_Text__c, Hours_Week__c, Product_Type__c, Product_Category__c
                 from OpportunityLineItem 
                 where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
        Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified');
        update opp;
        test.startTest();
        Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Closed Won');
        update opp;
        OpportunityContactRole ocr=new OpportunityContactRole(OpportunityId=opp.Id, ContactId=[Select ID from Contact Where Recordtype.name='Client' LIMIT 1].id, Role='Other POC');
        insert ocr;
        ocr.Role='Decision Maker';
        update ocr;
        delete ocr;
        test.stopTest();        
    }
    @isTest
    private static void Test4() 
    {
        OpportunityLineItem oLine= [Select 
                Id, OpportunityId, PricebookEntryId, Product2Id, ProductCode, Name, Quantity, UnitPrice, ListPrice, ServiceDate, Description, Customer_Hourly_Bill_Rate__c, Engagement_Duration_weeks__c, Weekly_Bill_Rate__c, Engagement_Start_Date__c, Torc_User__c, Talent_Hourly_Pay_Rate__c, Talent_Name__c, Weekly_Talent_Rate__c, Talent_Username__c, Engagement_End_Date__c, Product_Code_Text__c, Hours_Week__c, Product_Type__c, Product_Category__c
                 from OpportunityLineItem 
                 where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
        Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified');
        update opp;
        test.startTest();
        Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Closed Won');
        update opp;
        OpportunityContactRole ocr=new OpportunityContactRole(OpportunityId=opp.Id, ContactId=[Select ID from Contact Where Recordtype.name='Client'  LIMIT 1].id, Role='Other POC');
        insert ocr;
        Contact c=new Contact(id=ocr.ContactId,Email='sumit9829113328@abc.com');
        update c;
        Torc_User__c tu=new Torc_User__c(id=oLine.Torc_User__c,Given_Name__c='SumitXpX');
        update tu;
        test.stopTest();           
    }
    @isTest
    private static void Test6() 
    {
        Account act = testUtils.getNewAccount();
        Opportunity opp = testUtils.getFreelancerOpportunity(act);
        test.startTest();
        system.debug('=======');
        system.debug([Select Id, recordType.Name,Torc_Opportunity__c from opportunity where id=:opp.id]);
        system.debug(torc_constants__c.getinstance().torc_record_type__c);
        system.debug(opp);
        opp.StageName='Closed Won';
        update opp;
        Placement__c p = [Select ID,Detail__c from Placement__c LIMIT 1];
        p.Detail__c='aaaaa';
        update p;
        p.Detail__c='bbbbb';
        update p;
        test.stopTest();
    }
}