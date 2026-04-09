/*************************************
* All tests related to AWS is provided 
**************************************/
@isTest //(SeeallData=True)
private class AWS_Test 
{
    @testSetup
    public static void T()
    {
        testUtils.setupAllTestData();
    }

    @isTest
    private static void Test_Params() 
    {
        For(List<AWS_Sync__c>l:[Select id, Use_Query__c from AWS_Sync__c where Name in('User','Match')])
        {
            for(AWS_Sync__c a:l)
                a.Use_Query__c=true;
            update l;    
        }
        AWSDataLoaderQueue.isTestRunStatic = true;
        AWSDataLoaderQueue.runProcess(true);
        AWS_Query.cls_LastEvaluatedKey a= new AWS_Query.cls_LastEvaluatedKey('aa');
    } 
    @isTest
    private static void Test_Params2() 
    {
        try
        {
            For(List<AWS_Sync__c>l:[Select id, Use_Query__c from AWS_Sync__c where Name in('User','Match')])
            {
                for(AWS_Sync__c a:l)
                    a.Use_Query__c=true;
                update l;    
            }
            AWSDataLoaderQueue.isTestRunStatic = true;
            AWSScheduler a=new AWSScheduler();
            a.execute(null);
        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params3() 
    {
        try
        {
            For(List<AWS_Sync__c>l:[Select id, Use_Query__c from AWS_Sync__c where Name in('User','Match')])
            {
                for(AWS_Sync__c a:l)
                    a.Use_Query__c=true;
                update l;    
            }
            AWSDataLoaderQueue.isTestRunStatic = true;
            adminPanel.isTest=true;
            adminPanel.rerunAWS();
            

        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params311() 
    {
        try
        {
            adminPanel ad=new adminPanel();
            ad.json='aaaaaaa';
            ad.runJsonTrolley();
        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params31123() 
    {
        try
        {
            adminPanel ad=new adminPanel();
            ad.json='aaaaaaa';
            ad.runJsonTrolleyPaypalWebhook();
        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params3111() 
    {
        adminPanel ad=new adminPanel();
        
        //try{adminPanel.rerunAWS();}
        //catch(exception ex){}
        
        try{ad.runJsonTrolleyPaypalWebhook();}
        catch(exception ex){}
        
        try{ad.runJsonTrolley();}
        catch(exception ex){}
        
        //try{ad.RunMonthlyAward();}
        //catch(exception ex){}
        
        //try{ad.RunMonthlyESTAward();}
        //catch(exception ex){}
        
        //try{ad.RunQTRAward();}
        //catch(exception ex){}
        
        //try{ad.RerunFullCycle();}
        //catch(exception ex){}
        

                
    } 
    @isTest
    private static void Test_Params4() 
    {
        try
        {
            Torc_History__c t1 = [Select ID from Torc_History__c Where Torc_Job_Opportunity__c!=NULL AND NewValue__c = 'ACTIVE' and Attribute__c='status' LIMIT 1];
            update t1;
            Torc_History__c t2 = [Select ID from Torc_History__c Where Torc_Match__c!=NULL AND NewValue__c = 'MATCHED' and Attribute__c='status' LIMIT 1];
            update t2;
            Torc_History__c t3 = [Select ID from Torc_History__c Where Torc_Match__c!=NULL AND NewValue__c = 'APPLIED' and Attribute__c='status' LIMIT 1];
            update t3;
            

        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params5() 
    {
        try
        {
            test.starttest();
            Dynamo_Stream__e d=new Dynamo_Stream__e();
            d.Json__c = '[{"eventID":"5e3d0798fee9dd67c8499e968fbf54f5","eventName":"MODIFY","eventVersion":"1.1","eventSource":"aws:dynamodb","awsRegion":"us-east-1","dynamodb":{"ApproximateCreationDateTime":1672832618,"Keys":{"id":{"S":"95c84bcc-cb7c-4861-a738-64d3268d4758"}},"NewImage":{"__typename":{"S":"User"},"referrerCode":{"S":""},"githubAccessToken":{"S":""},"updater":{"S":"com.opentorc.id.post_confirmation"},"systemModTimestamp":{"S":"2023-01-04T11:43:38.191Z"},"createdAt":{"S":"2023-01-04T11:43:22.016Z"},"identity_username":{"S":"sumitmishra041979"},"agreedToMarketing":{"BOOL":true},"lastActivityDate":{"S":"2023-01-04T11:43:38.191Z"},"referralCode":{"S":"ccub4su"},"company":{"S":""},"id":{"S":"95c84bcc-cb7c-4861-a738-64d3268d4758"},"agreedToTerms":{"BOOL":true},"email":{"S":"sumitmishra041979+1@gmail.com"},"updatedAt":{"S":"2023-01-04T11:43:22.016Z"},"creator":{"S":"com.opentorc.id.post_confirmation"},"additionalMarkup":{"N":"1"},"visibility":{"S":"FULL"},"given_name":{"S":"SumitD"},"systemProcessName":{"S":"com.opentorc.id.user_activity"},"location":{"M":{"wikiDataId":{"S":"Q1134781"},"cityName":{"S":"Jaipur"},"stateName":{"S":"Rajasthan"},"locationId":{"N":"132201"},"countryCode":{"S":"IN"},"stateId":{"N":"4014"},"latitude":{"S":"27.00000000"},"stateCode":{"S":"RJ"},"countryName":{"S":"India"},"countryId":{"N":"101"},"longitude":{"S":"76.00000000"}}},"userType":{"S":"FREELANCER"},"family_name":{"S":"MishraD"},"status":{"S":"ACTIVE"},"username":{"S":"sumitmishra041979"}},"OldImage":{"creator":{"S":"com.opentorc.id.post_confirmation"},"additionalMarkup":{"N":"1"},"visibility":{"S":"FULL"},"__typename":{"S":"User"},"referrerCode":{"S":""},"githubAccessToken":{"S":""},"given_name":{"S":"SumitD"},"updater":{"S":"com.opentorc.id.post_confirmation"},"systemModTimestamp":{"S":"2023-01-04T11:43:25.672Z"},"createdAt":{"S":"2023-01-04T11:43:22.016Z"},"identity_username":{"S":"sumitmishra041979"},"agreedToMarketing":{"BOOL":true},"systemProcessName":{"S":"com.opentorc.id.referral_processor"},"referralCode":{"S":"ccub4su"},"company":{"S":""},"location":{"M":{"wikiDataId":{"S":"Q1134781"},"cityName":{"S":"Jaipur"},"stateName":{"S":"Rajasthan"},"locationId":{"N":"132201"},"countryCode":{"S":"IN"},"stateId":{"N":"4014"},"latitude":{"S":"27.00000000"},"stateCode":{"S":"RJ"},"countryName":{"S":"India"},"countryId":{"N":"101"},"longitude":{"S":"76.00000000"}}},"id":{"S":"95c84bcc-cb7c-4861-a738-64d3268d4758"},"userType":{"S":"FREELANCER"},"family_name":{"S":"MishraD"},"agreedToTerms":{"BOOL":true},"email":{"S":"sumitmishra041979+1@gmail.com"},"status":{"S":"ACTIVE"},"updatedAt":{"S":"2023-01-04T11:43:22.016Z"},"username":{"S":"sumitmishra041979"}},"SequenceNumber":"1627413100000000026531478956","SizeBytes":1581,"StreamViewType":"NEW_AND_OLD_IMAGES"},"eventSourceARN":"arn:aws:dynamodb:us-east-1:741363590887:table/User-ahssmy3yy5dg3gwujmtemowjbm-develop/stream/2022-01-27T14:39:39.026"}]';
            EventBus.publish(d); 
            test.stoptest();

        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params6() 
    {
            test.starttest();
            OpportunityLineItem oLine= [Select ID, OpportunityId,Torc_user__c from OpportunityLineItem where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
            Torc_match__c tm=[Select id, Torc_User_ref__r.name,Torc_job_opportunity__c, Torc_User_ref__c from Torc_match__c LIMIT 1];
            Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified',job_Opportunity__c = tm.Torc_job_opportunity__c);
            update opp;
            oLine.Torc_user__c = tm.Torc_User_ref__c;
            oLine.Talent_UserName__c = tm.Torc_User_ref__r.name;
            update oLine;
            opp.StageName = 'Closed Lost';
            opp.Reason_lost__c = 'Lost from third party';
            update opp;
            Set<id>oppIds=new set<id>();
            Set<id>JobIds=new set<id>();
            oppIds.add(opp.id);
            JobIds.add(opp.Job_Opportunity__c);
            base_HttpService.OpportunityStatucChange(oppids,JobIds);
            test.Stoptest();
    } 
    @isTest
    private static void Test_Params6Ext() 
    {
            test.starttest();
            OpportunityLineItem oLine= [Select ID, OpportunityId,Torc_user__c from OpportunityLineItem where opportunity.Parent_Opportunity__c=NULL AND Opportunity.Amount > 0 AND opportunity.IsWon=FALSE AND opportunity.Stagename!='Closed Lost' And Torc_User__C!=NULL Order By Opportunity.CloseDate DESC LIMIT 1];
            Torc_match__c tm=[Select id, Torc_User_ref__r.name, Torc_job_opportunity__c, Torc_User_ref__c from Torc_match__c LIMIT 1];
            Opportunity Opp=new Opportunity(Id=oLine.OpportunityId, StageName = 'Need Identified',job_Opportunity__c = tm.Torc_job_opportunity__c);
            update opp;
            oLine.Torc_user__c = tm.Torc_User_ref__c;
            oLine.Talent_UserName__c = tm.Torc_User_ref__r.name;
            update oLine;
            opp.StageName = 'Closed Won';
            update opp;
            Set<id>oppIds=new set<id>();
            Set<id>JobIds=new set<id>();
            oppIds.add(opp.id);
            JobIds.add(opp.Job_Opportunity__c);
            base_HttpService.OpportunityStatucChange(oppids,JobIds);
            test.Stoptest();
    } 
    @isTest
    private static void Test_Params7() 
    {
        try
        {
            test.starttest();
            
            OpportunityLineItem oppL=[SELECT OpportunityId, Opportunity.Job_Opportunity__c,Opportunity.StageName from OpportunityLineItem
                                     Where Opportunity.IsWon=TRUE AND Opportunity.Job_Opportunity__c!=NULL AND Torc_User__c!=NULL Order by CreatedDate DESC Limit 1];
            Opportunity opp=OppL.Opportunity;
            opp.StageName = 'Need Identified';
            update opp;
            opp.StageName = 'Closed Won';
            update opp;
            Set<id>oppIds=new set<id>();
            Set<id>JobIds=new set<id>();
            oppIds.add(opp.id);
            JobIds.add(opp.Job_Opportunity__c);
            base_HttpService.OpportunityStatucChange(oppids,JobIds);
            test.Stoptest();
        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params8() 
    {
        try
        {
            test.starttest();            
            Torc_History__c a=[SELECT ID,Attribute__c, Newvalue__c FROM Torc_History__c WHERE Torc_Match__c!=NULL AND Attribute__c='status' LIMIT 1];
            a.NewValue__c = 'APPLIED';UPDATE a;
            a.NewValue__c = 'MATCHED';UPDATE a;
            a.NewValue__c = 'ACCEPTED';UPDATE a;
            a.NewValue__c = 'MOREINFO';UPDATE a;
            a.NewValue__c = 'SHORTLISTED';UPDATE a;
            a.NewValue__c = 'SKIPPED';UPDATE a;
            a.NewValue__c = 'REJECTEDBYCUSTOMER';UPDATE a;
            test.Stoptest();
        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void Test_Params9() 
    {
        List<Torc_user__c> l=[Select ID, referrerCode__c, referralCode__c from Torc_user__c Order By CreatedDate DESC LIMIT 2];
        l[0].referralCode__c = 'xSumiTestMan2022';
        update l[0];
        l[1].referrerCode__c = 'xSumiTestMan2022';
        update l[1];
        l[1].referrerCode__c = '';
        update l[1];
        
        
    }
    @isTest
    private static void Test_Params10() 
    {
        List<Torc_user__c> l=[Select ID, CountryName__c from Torc_user__c Order By CreatedDate DESC LIMIT 1];
        l[0].CountryName__c = 'India';
        update l[0];
        l[0].CountryName__c = 'Pakistan';
        update l[0];
        
        
        
    }

    @isTest
    private static void Test_Params11() 
    {
        List<Torc_user__c> l=[Select ID, External_Id__c from Torc_user__c Order By CreatedDate DESC LIMIT 1];
        PageReference pageRef = Page.torcUserRedirect;
        pageRef.getParameters().put('id',l[0].External_Id__c);
        Test.setCurrentPage(pageRef);
        torcUserRedirect rec = new torcUserRedirect();
        rec.redirect();
    }
    @isTest
    private static void Test_Params12() 
    {
        PageReference pageRef = Page.torcUserRedirect;
        pageRef.getParameters().put('id','aaa');
        Test.setCurrentPage(pageRef);
        torcUserRedirect rec = new torcUserRedirect();
        rec.redirect();
    }
    @isTest
    private static void Test_Params13() 
    {
        PageReference pageRef = Page.torcrecordUpdate;
        List<Torc_user__c> l=[Select ID, External_Id__c from Torc_user__c Order By CreatedDate DESC LIMIT 1];
        pageRef.getParameters().put('id',l[0].External_Id__c);
        pageRef.getParameters().put('recid',l[0].id);
        Test.setCurrentPage(pageRef);
        torcrecordUpdate rec = new torcrecordUpdate();
        rec.actioncall();
        rec.incrementCounter();
        rec.getCount();
    }
    @isTest
    private static void Test_zapier() 
    {
        try
        {
            //zapier a=new zapier();
            //a.execute(null);
        }
        catch(exception ex)
        {}
    } 
       @isTest
    private static void Test_Cleanup() 
    {
        try
        {
            awsCleanUpScheduler a=new awsCleanUpScheduler();
            
            a.execute(null);
        }
        catch(exception ex)
        {}
    } 
    @isTest
    private static void testeverythingelse()
    {
        awsdataLoad.stringtoDate('2025-01-01T10:10:10z');
        string body = '[{"eventType":"resumeUpdated","resumeLocation":"dev/resume/sumitmishra041979ss_resume","uploadedByRD":false,"userId":"111-fc01-428e-9eea-cb6d0d2b80a1"}]';
        List< Dynamo_Stream_Shadow__c> lstDynamo = new List< Dynamo_Stream_Shadow__c>();
        lstDynamo.add(new Dynamo_Stream_Shadow__c(JSON__c = body));
        awsdataLoad.realTimeProcess(lstDynamo);
        new AWS_Query.cls_ExpressionAttributeValuesWithNm2('1','2','3');
        new AWS_Query.cls_ExpressionAttributeValues2('1','2');
        new AWS_Query.cls_ExpressionAttributeValues();
        new AWS_Query.cls_ExpressionAttributeValues2();
    }   
    @isTest
    private static void testNotes()
    {
        string body = '[{"eventID":"53cec3a87deb1cee70dabbed5e3aa13b","eventName":"INSERT","eventVersion":"1.1","eventSource":"aws:dynamodb","awsRegion":"us-east-1","dynamodb":{"ApproximateCreationDateTime":1757579677,"Keys":{"id":{"S":"3a6f4725-e370-4ab0-854e-eec75134c09d"}},"NewImage":{"creator":{"S":"ritesh_stage_admin1"},"generateAnalysis":{"BOOL":false},"type_name_sfdc":{"S":"Note"},"updatedById":{"S":"1f2f0659-8fea-48d9-9965-f8fbfdb8f0e0"},"userId":{"S":"ffa07aeb-4a20-4b7f-acc2-8255d3c9b8e2"},"content":{"S":"notesttest3"},"updater":{"S":"ritesh_stage_admin1"},"systemModTimestamp":{"S":"2025-09-11T08:34:37.469Z"},"createdAt":{"S":"2025-09-11T08:34:37.469Z"},"noteType":{"S":"GENERAL"},"isPublic":{"BOOL":false},"id":{"S":"3a6f4725-e370-4ab0-854e-eec75134c09d"},"createdById":{"S":"1f2f0659-8fea-48d9-9965-f8fbfdb8f0e0"},"updatedAt":{"S":"2025-09-11T08:34:37.469Z"}},"SequenceNumber":"4957666700001474360175484593","SizeBytes":445,"StreamViewType":"NEW_AND_OLD_IMAGES"},"eventSourceARN":"arn:aws:dynamodb:us-east-1:100137284626:table/Note-i4udqlmn45hhlarlt3wwfcmwii-staging/stream/2022-10-31T09:15:48.965"}]';
        List< Dynamo_Stream_Shadow__c> lstDynamo = new List< Dynamo_Stream_Shadow__c>();
        lstDynamo.add(new Dynamo_Stream_Shadow__c(JSON__c = body));
        awsdataLoad.realTimeProcess(lstDynamo);
    }
    
    
    @isTest
    private static void Test_MatchChanger() 
    {
        List<Torc_user__c> l=[Select ID,name, External_Id__c from Torc_user__c Order By CreatedDate DESC LIMIT 1];
        Torc_match__c tm=[Select id,creator__c,matcher__c from Torc_match__c limit 1];
        tm.creator__c=tm.matcher__c=null;
        update tm;
        tm.creator__c=tm.matcher__c=l[0].Name;
        update tm;
    }
    @isTest
    private static void Test_JobMatchLoad() 
    {
        try{
        AWSDataLoad.updatematchesByJobId('test');
        }
        catch(exception ex){}
        try
        {
            AWSMatch15MinScheduler a=new AWSMatch15MinScheduler();
            a.execute(null);
        }
        catch(exception ex)
        {}
        
    }    
    
}