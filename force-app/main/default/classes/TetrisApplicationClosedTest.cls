/**
* Test Class
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* TetrisApplicationClosedTest
* @description     This Class has been deprecated  tag: salesforce.application.closed is deprecated and 
	won’t be used anymore in the new RDOne setup,the functionality will be replaced by the new tag:salesforce.closing_report.submitted
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @version        1.0
* @created        
* @modified       26-06-2024
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
**/
@isTest
public with sharing class TetrisApplicationClosedTest {
    /*@isTest()
    static void test_ESBSFSubmitApplication (){

        TR1__Job__c job = new TR1__Job__c();
        job.RecordTypeId = '0127S000000Tmi4QAC';
        job.Business_unit__c = '5000 Imported - to be reviewed';

        insert job;
        
        TR1__Application_V2__c app = new TR1__Application_V2__c();
        app.TR1__Job__c = job.id;
        app.TR1__Stage__c = 'Closing Report';
        app.RecordTypeId = '0127S000000TmiHQAS';
        
        insert app;
        //System.AssertEquals(objOpportunity.Name, 'Test Opportunity');
       
        
        List<TR1__Application_V2__c> result = [select id from TR1__Application_V2__c where id=: app.id];
        
        List<AusyApplicationESBCallable> apps = new List<AusyApplicationESBCallable>();
        AusyApplicationESBCallable a1 = new AusyApplicationESBCallable();
        a1.appId = result[0].id;
      
        
        apps.add(a1);
        List<ID> jobIDs = TetrisApplicationClosed.ESBSFSubmitApplication(apps);
        system.assertEquals(1, jobIDs.size());

    }*/
}