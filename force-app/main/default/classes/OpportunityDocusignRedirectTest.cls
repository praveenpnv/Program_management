@isTest //(SeeallData=True)
private class OpportunityDocusignRedirectTest 
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData();
    }
    @isTest
    private static void test0() 
    {
        dfsle__Envelope__c  a = [select id, dfsle__SourceId__c from dfsle__Envelope__c LIMIT 1];
        a.dfsle__SourceId__c = [Select id from Opportunity limit 1].id;
        update a;
        a.dfsle__SourceId__c = [Select id from Non_Torc_user__c limit 1].id;
        update a;
    }
    @isTest
    private static void test1() 
    {        
        OpportunityDocusigngenRedirect.testIncrease();
        Test.startTest();
        Opportunity Opp=[Select ID from Opportunity Order By CreatedDate DESC LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        PageReference pageRef = Page.OpportunityDocusigngenRedirect;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opp.id);
        OpportunityDocusigngenRedirect olic = new OpportunityDocusigngenRedirect(sc);
        olic.opp.Engagement_Description__c='';
        olic.SaveAndBack();
        olic.opp.Engagement_Description__c='ahs s d sdf s df sdfsdfsdfsdf sd f sdf s dfsdf';
        olic.opp.Engagement_Signatory__c=null;
        olic.SaveAndBack();
        olic.opp.Engagement_Signatory__c=[Select ID from Contact LIMIt 1].id;
        olic.SaveAndBack();
        olic.act.Agreement_date__c=Date.today();
        Olic.reDirectNow();
        olic.clearInvoicingContact();
        olic.clearSignerContact();
        olic.sendChatter();
    }  
    @isTest
    private static void test3() 
    {        
        Test.startTest();
        Opportunity Opp=[Select ID from Opportunity Order By CreatedDate DESC LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        PageReference pageRef = Page.OpportunityRedirectDocusignCO;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opp.id);
        System.currentPageReference().getParameters().put('ext','1');
        OpportunityDocusigngenRedirect olic = new OpportunityDocusigngenRedirect(sc);
        olic.act.Agreement_date__c=Date.today();
        olic.opp.Change_Order_Type__c='ABBBA';
        olic.opp.Change_Order_Description__c='CCDD';
        Olic.reDirectChangeOrderNow();
    }  
    @isTest
    private static void test2() 
    {        
        Test.startTest();
        OpportunityLineItem opl=[Select ID,OpportunityId,Talent_UserName__c from OpportunityLineItem Where Opportunity.Job_Opportunity__c!=NULL AND Torc_user__c!=NULL LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(new Opportunity(id=opl.OpportunityId));
        PageReference pageRef = Page.OpportunityDocusignMemberRedirect;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opl.OpportunityId);
        OpportunityDocusignMemberRedirect olic = new OpportunityDocusignMemberRedirect(sc);
        olic.opp.Engagement_Description_Talent__c ='1223471626126176212 12 1 21 2 1 2 12121';
        olic.getUserList();
        olic.Selectedoli=opl.Talent_UserName__c;
        olic.moveNext();
        olic.SaveAndBack();
        Olic.reDirectNow();
        olic.getOliList();
        olic.chkMovenext();
        sc = new ApexPages.StandardController(new Opportunity(id=opl.OpportunityId));
        pageRef = Page.OpportunityDocusignMemberRedirect;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',opl.OpportunityId);
        olic = new OpportunityDocusignMemberRedirect(sc);
    }  
    @isTest
    private static void testMSA() 
    {        
        Test.startTest();
        Contact Con=[Select ID,AccountId from Contact Where Account.MSA_Signer__c=NULL AND AccountId!=NULL LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(new Account(id=con.AccountId));
        PageReference pageRef = Page.AccountDocusignredirect;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',con.AccountId);
        AccountDocusignredirect olic = new AccountDocusignredirect(sc);
        olic.reDirect();
        olic.act.MSA_Signer__c = con.id;
        olic.reDirect();
        olic.saveAndreturn();
    } 
    @isTest
    private static void testO1() 
    {
        Set<id> tuIds=new set<id>();
        for(Torc_User__c tu:[Select ID from Torc_user__c where SFDC_Contact__c=NULL AND Email__c!=NULL AND Email__c !='' LIMIT 3])
            tuIds.add(tu.id);
        OpportunityDocusignMemberRedirect.CreateMemberContact(tuIds);       
    }
    
    @isTest
    private static void testO3() 
    {
        dfsle__Envelope__c r = [SELECT  dfsle__SourceId__c,dfsle__DocuSignId__c from dfsle__Envelope__c
                                    WHERE 
                                        dfsle__EnvelopeConfiguration__c = :Torc_Constants__c.getInstance().MSA_Template_Id__c
                                        AND dfsle__SourceId__c!=NULL AND dfsle__DocuSignId__c!=NULL LIMIT 1];

        dfsle__EnvelopeStatus__c ds=[Select Id, dfsle__SourceId__c,dfsle__DocuSignId__c,dfsle__Status__c
                                    from dfsle__EnvelopeStatus__c where 
                                    dfsle__DocuSignId__c =:r.dfsle__DocuSignId__c  LIMIT 1];
                                    
        ds.dfsle__Status__c='abc';
        update ds;
    }    
                                                  
                                        
                                        
    @isTest
    private static void testO2() 
    {
        Set<id> tuIds=new set<id>();
        for(Non_Torc_User__c tu:[Select ID from Non_Torc_user__c LIMIT 1])
        {
            dfsle__EnvelopeStatus__c ds=[Select Id, dfsle__SourceId__c from dfsle__EnvelopeStatus__c where Non_Torc_User__c=NULL LIMIT 1];
            ds.dfsle__SourceId__c = tu.id;
            update ds;
        }
        for(Opportunity tu:[Select ID from Opportunity LIMIT 1])
        {
            dfsle__EnvelopeStatus__c ds=[Select Id, dfsle__SourceId__c from dfsle__EnvelopeStatus__c where Opportunity__c=NULL LIMIT 1];
            ds.dfsle__SourceId__c = tu.id;
            update ds;
        }
        for(Account tu:[Select ID from Account LIMIT 1])
        {
            dfsle__EnvelopeStatus__c ds=[Select Id, dfsle__SourceId__c from dfsle__EnvelopeStatus__c where Account__c=NULL LIMIT 1];
            ds.dfsle__SourceId__c = tu.id;
            update ds;
        }
        


    }     
    
}