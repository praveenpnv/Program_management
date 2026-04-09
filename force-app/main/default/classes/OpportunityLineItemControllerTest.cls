@isTest
private class OpportunityLineItemControllerTest 
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData();
    }
    @isTest
    private static void testM1() 
    {        
        Test.startTest();
        Opportunity opp = [Select ID from Opportunity Where IsWON=FALSE Order By CreatedDATe DESC Limit 1];
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        
        for(id id:olic.priceBookEntrymap.keyset())
        {   
                olic.newrowProductId = id;
                olic.addnewRow();
        }
        olic.getlstLineItemsHIRING();
        olic.getlstLineItemsTAAS();
        olic.getlstLineItemsTransactionFee();
        
        olic.getshowTalentTab();
        olic.getshowHiringTab();
        olic.cancel();
    }    

    @isTest
    private static void test0() 
    {        
        Test.startTest();
        Opportunity opp = [Select ID from Opportunity Where IsWON=TRUE Order By CreatedDATe DESC Limit 1];
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        olic.cancel();
    }  
    @isTest
     private static void test1Ext() 
    {        
        Test.startTest();
        Account act=testUtils.getNewAccount();
        Opportunity opp = testUtils.getFreelancerOpportunity(act);
        opp.Job_Opportunity__c = [Select ID, Torc_Job_Opportunity__c from Torc_match__c LIMIT 1].Torc_Job_Opportunity__c;
        update opp;
        opp.StageName='Closed Won';
        update opp;
    }      
    @isTest
    private static void test1() 
    {        
        Test.startTest();
        Account act=testUtils.getNewAccount();
        Opportunity opp = testUtils.getNewOpportunity(act);
        opp.Job_Opportunity__c = [Select ID, Torc_Job_Opportunity__c from Torc_match__c LIMIT 1].Torc_Job_Opportunity__c;
        update opp;
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        olic.getJobOpportunityUSerList();
        olic.getShowDropDown();
        List<SelectOption> l= olic.getProducts();
        olic.newrowProductId = l[0].getvalue();
        olic.addnewRow();
        olic.getshowBudget();
        olic.getTotal();
        
        olic.Save();
        olic.lstLineItems[0].Oli.Customer_Hourly_Bill_Rate__c=100;
        olic.lstLineItems[0].Oli.Engagement_Start_Date__c=Date.today();
        olic.lstLineItems[0].Oli.Engagement_Duration_weeks__c=2;
        olic.lstLineItems[0].Oli.Hours_Week__c=40;
        olic.lstLineItems[0].Oli.Talent_UserName__c='sumitmishra';
        olic.lstLineItems[0].Oli.Talent_Hourly_Pay_Rate__c=10;
        olic.lstLineItems[0].Oli.Time_Commitment__c = 'FULLTIME';
        
        
        olic.lstLineItems[0].getisUserameError();
        olic.lstLineItems[0].getWeeklyPrice();
        olic.lstLineItems[0].getTalentWeeklyPrice();
        olic.dummyRefresh();
        olic.addnewRow();
        olic.lstLineItems[1].Oli.Customer_Hourly_Bill_Rate__c=100;
        olic.lstLineItems[1].Oli.Engagement_Start_Date__c=Date.today();
        olic.lstLineItems[1].Oli.Engagement_Duration_weeks__c=2;
        olic.lstLineItems[1].Oli.Hours_Week__c=40;
        olic.lstLineItems[1].Oli.Talent_UserName__c='';
        olic.lstLineItems[1].Oli.Time_Commitment__c = 'FULLTIME';
        olic.lstLineItems[1].Oli.Talent_Hourly_Pay_Rate__c=10;
        olic.addnewRow();
        olic.lstLineItems[2].Oli.Customer_Hourly_Bill_Rate__c=100;
        olic.lstLineItems[2].Oli.Engagement_Start_Date__c=Date.today();
        olic.lstLineItems[2].Oli.Engagement_Duration_weeks__c=2;
        olic.lstLineItems[2].Oli.Hours_Week__c=40;
        olic.lstLineItems[2].Oli.Talent_UserName__c='';
        olic.lstLineItems[2].Oli.Talent_Hourly_Pay_Rate__c=10;
        olic.lstLineItems[2].Oli.Time_Commitment__c = 'FULLTIME';
        olic.lstLineItems[2].workLoadChange();
        olic.getTotal();
        olic.AddDays =2;
        olic.deleteRowNumber=2;
        olic.removeRow();
        olic.getTotal();
        olic.workLoadChange();
        olic.Save();
        pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        olic = new OpportunityLineItemController();
    } 
    @isTest
    private static void test11() 
    {        
        Test.startTest();
        Account act=testUtils.getNewAccount();
        Opportunity opp = testUtils.getNewOpportunity(act);
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        List<SelectOption> l= olic.getProducts();
        olic.newrowProductId = l[0].getvalue();
        olic.addnewRow();
        olic.lstLineItems[0].Oli.Customer_Hourly_Bill_Rate__c=100;
        olic.lstLineItems[0].Oli.Engagement_Start_Date__c=Date.today();
        olic.lstLineItems[0].Oli.Engagement_Duration_weeks__c=2;
        olic.lstLineItems[0].Oli.Hours_Week__c=40;
        olic.lstLineItems[0].Oli.Talent_UserName__c='sumitmishra';
        olic.lstLineItems[0].Oli.Time_Commitment__c = 'FULLTIME';
        olic.lstLineItems[0].Oli.Talent_Hourly_Pay_Rate__c=10;
        olic.Save();
    } 
    @isTest
    private static void test111() 
    {        
        Test.startTest();
        Account act=testUtils.getNewAccount();
        Opportunity opp = testUtils.getNewOpportunity(act);
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        List<SelectOption> l= olic.getProducts();
        olic.newrowProductId = l[0].getvalue();
        olic.addnewRow();
        olic.lstLineItems[0].Oli.Customer_Hourly_Bill_Rate__c=100;
        olic.lstLineItems[0].Oli.Engagement_Start_Date__c=Date.today();
        olic.lstLineItems[0].Oli.Engagement_Duration_weeks__c=2.5;
        olic.lstLineItems[0].Oli.Hours_Week__c=40;
        olic.lstLineItems[0].Oli.Talent_UserName__c='sumitmishra';
        olic.lstLineItems[0].Oli.Time_Commitment__c = 'FULLTIME';
        olic.lstLineItems[0].Oli.Talent_Hourly_Pay_Rate__c=10;
        olic.lstLineItems[0].getTotalPrice();
        olic.Save();
    } 
    @isTest
    private static void test2() 
    {        
        Test.startTest();
        dfsle__Envelope__c rec=[Select ID from dfsle__Envelope__c Where dfsle__SourceId__c Like '006%' LIMIT 1];
        update rec;
        dfsle__EnvelopeStatus__c rec1=[Select ID,dfsle__SourceId__c from dfsle__EnvelopeStatus__c Where dfsle__SourceId__c Like '006%' LIMIT 1];
        dfsle__EnvelopeStatus__c rec2 = new dfsle__EnvelopeStatus__c(dfsle__DocuSignId__c='100', dfsle__SourceId__c=rec1.dfsle__SourceId__c, dfsle__Status__c ='Completed');
        insert rec2;
        
        Attachment att=[Select ID, ContentType,Body,IsPrivate,Name from Attachment LIMIT 1];
        Attachment att2 = new Attachment(
            ContentType = att.ContentType,
            Name=att.Name,
            IsPrivate=att.IsPrivate,
            Body=att.Body,
            ParentId = rec2.Id);
        insert att2;
        
    } 
    @isTest
    private static void test2P2() 
    {        
        Test.startTest();
        dfsle__Envelope__c rec=[Select ID,dfsle__DocuSignId__c,dfsle__EnvelopeConfiguration__c from dfsle__Envelope__c Where dfsle__SourceId__c Like '001%' 
                AND dfsle__EnvelopeConfiguration__c =:Torc_Constants__c.getInstance().MSA_Template_Id__c LIMIT 1];
        update rec;
        dfsle__EnvelopeStatus__c rec1=[Select ID,dfsle__DocuSignId__c,dfsle__Status__c from dfsle__EnvelopeStatus__c LIMIT 1];
        
        if(rec1.dfsle__Status__c=='Sent')
           rec1.dfsle__Status__c='Completed';
        else
           rec1.dfsle__Status__c='Sent';    
        //rec1.dfsle__DocuSignId__c = rec.dfsle__DocuSignId__c;
        update rec1;
    } 
    @isTest
    private static void test2P1() 
    {        
        Test.startTest();
        dfsle__EnvelopeStatus__c rec1=[Select ID,dfsle__SourceId__c from dfsle__EnvelopeStatus__c Where dfsle__SourceId__c Like '001%' LIMIT 1];
        dfsle__EnvelopeStatus__c rec2 = new dfsle__EnvelopeStatus__c(dfsle__DocuSignId__c='100', dfsle__SourceId__c=rec1.dfsle__SourceId__c, dfsle__Status__c ='Completed');
        insert rec2;
        
        Attachment att=[Select ID, ContentType,Body,IsPrivate,Name from Attachment LIMIT 1];
        Attachment att2 = new Attachment(
            ContentType = att.ContentType,
            Name=att.Name,
            IsPrivate=att.IsPrivate,
            Body=att.Body,
            ParentId = rec2.Id);
        insert att2;
        
    } 
    @isTest
    private static void test3() 
    {        
        Test.startTest();
        Opportunity Opp=[Select ID from Opportunity Order By CreatedDate DESC LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        PageReference pageRef = Page.OpportunityDocusigngenRedirect;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opp.id);
        OpportunityDocusigngenRedirect olic = new OpportunityDocusigngenRedirect(sc);
        olic.act.Agreement_date__c=Date.today();
        Olic.reDirectNow();
        
        
        
        
    }    
    @isTest
    private static void test4() 
    {        
        Test.startTest();
        Task t=new Task(WhoId=[Select ID from Contact Limit 1].Id, Subject='Email:1', ActivityDate =Date.today());
        insert t;
        Task t1=new Task(WhoId=[Select ID from Lead Limit 1].Id, Subject='Email:1', ActivityDate =Date.today());
        insert t1;
    }
    @isTest
    private static void test5() 
    {        
        Test.startTest();
        Opportunity opp = [Select ID,StageName from Opportunity Where IsWON=False Order By CreatedDATe DESC Limit 1];
        opp.StageName='Closed Won';
        try{update opp;}
        catch(exception ex){}
    } 
    @isTest
    private static void test7() 
    {        
        Test.startTest();
        Opportunity O=[Select ID, Stagename from Opportunity where IsWon=FALSE AND Stagename!='Closed Lost' order By CloseDate DESC LIMIT 1];
        o.StageName = 'Need Posted';
        update o;
        o.StageName = 'Interview(s) Scheduled';
        update o;
        o.StageName = 'Agreement in Principle';
        update o;
        o.StageName = 'Buyer/Member Matched';
        update o;
        o.StageName = 'Need Identified';
        update o;
        o.StageName = 'Closed Won';
        update o;
    } 
    private static void test7PointOne() 
    {        
        Test.startTest();
        Opportunity O=[Select ID, Stagename from Opportunity where IsWon=FALSE AND Stagename!='Closed Lost' order By CloseDate DESC LIMIT 1];
        o.StageName = 'Closed Lost';
        o.Reason_lost__c = 'Lost from third party';
        update o;
    } 
    @isTest
    private static void test112() 
    {        
        Test.startTest();
        Account act=testUtils.getNewAccount();
        Opportunity opp = testUtils.getNewOpportunity(act);
        opp.Job_Opportunity__c = [Select ID, Torc_Job_Opportunity__c from Torc_match__c LIMIT 1].Torc_Job_Opportunity__c;
        update opp;
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        olic.getJobOpportunityUSerList();
        olic.getShowDropDown();
        List<SelectOption> l= olic.getProducts();
        olic.newrowProductId = l[1].getvalue();
        olic.addnewRow();
        olic.getshowBudget();
        olic.getTotal();        
        olic.Save();

    }    
    @isTest
    private static void testAllInOne() 
    {        
        Test.startTest();
        Account act=testUtils.getNewAccount();
        Opportunity opp = testUtils.getNewBlankOpportunity(act);
        opp.Job_Opportunity__c = [Select ID, Torc_Job_Opportunity__c from Torc_match__c LIMIT 1].Torc_Job_Opportunity__c;
        update opp;
        PageReference pageRef = Page.OpportunityLineItem;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('oppId',opp.id);
        OpportunityLineItemController olic = new OpportunityLineItemController();
        olic.getJobOpportunityUSerList();
        olic.getShowDropDown();
        List<SelectOption> l= olic.getProducts();
        olic.newrowProductId = l[0].getvalue();
        olic.addnewRow();
        olic.getshowBudget();
        olic.getTotal();
        
        olic.lstLineItems[0].Oli.Customer_Hourly_Bill_Rate__c=100;
        olic.lstLineItems[0].Oli.Engagement_Start_Date__c=Date.today();
        olic.lstLineItems[0].Oli.Engagement_Duration_weeks__c=2;
        olic.lstLineItems[0].Oli.Hours_Week__c=40;
        olic.lstLineItems[0].Oli.Talent_UserName__c='sumitmishra';
        olic.lstLineItems[0].Oli.Talent_Hourly_Pay_Rate__c=10;
        olic.lstLineItems[0].Oli.Time_Commitment__c = 'FULLTIME';
        olic.lstLineItems[0].getisUserameError();
        olic.lstLineItems[0].getWeeklyPrice();
        olic.lstLineItems[0].getTalentWeeklyPrice();
        olic.dummyRefresh();
        olic.Save();
        OpportunityLineItemController.getNextWorkingDay(Date.today());
    } 
}