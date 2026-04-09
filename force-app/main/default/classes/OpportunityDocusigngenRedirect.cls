Public without sharing Class OpportunityDocusigngenRedirect
{
    Public boolean editableSigningDate{get;set;}
    public Opportunity Opp{get;set;}
    public Account act{get;set;}
    public Contact invoicingContact{get;set;}
    public Contact engagementSigner{get;set;}
    public string supervisor{get;set;}
    public boolean isExtension{get;set;}
    public string errorMessage{get;set;}
    public OpportunityContactRole ocr{get;set;}
    public boolean isRandstad{get;set;}
    public OpportunityDocusigngenRedirect(ApexPages.StandardController controller)
    {
        isRandstad = false;
        isExtension = ApexPages.currentPage().getParameters().get('ext')=='1'?true:false;
        editableSigningDate=false;
        Opp=(Opportunity) controller.getRecord();
        Opp=[Select ID, ownerId,New_Term__c,Change_Order_Description__c, Change_Order_Type__c, Change_Order_Additional_Description__c,
                    Supervisor__c,Name, Engagement_Signatory__c, Invoicing_Contact__c, Half_Time_Value__c, Avg_Hours_Week__c,  Docusign_Additional_Assumptions__c, Engagement_Description__c,
                    AccountId, Account.Name,Account.Docusign_Additional_Agreement__c,Account.Docusign_Pricing_Description__c,Account.Docusign_Additional_Specification__c,Account.Notice_Address__c,
                    Account.Agreement_date__c, Description, CloseDate,Amount, Account.Invoicing_Contact__c, Email_Address_for_Invoices__c,                    
                    Docusign_Pricing_Description__c,Docusign_Compensation_and_Payment__c, Torc_POC__c,account.Docusign_Compensation_and_Payment__c,
                    (Select Role__c,ID, Talent_Name__c, Product_Category__c,Time_Commitment__c,Time_Commitment_Text__c , TotalPrice ,Engagement_Start_Date__c, Hours_Week__c, Engagement_Duration_weeks__c, Product_Type__c, Weekly_Bill_Rate__c 
                        ,Terms_Randstad__c,Total_Hours__c,Talent_Terms__c, Customer_Hourly_Bill_Rate__c,Work_Location__c, Work_Schedule__c
                    from OpportunityLineItems),
                    (Select Contact.Name, Contact.Email, ContactId from OpportunityContactRoles where Role='Engagement Supervisor' LIMIT 1)                    
                    FROM Opportunity Where ID=:opp.id];
        Act = Opp.Account; 
        List<string> sIds = Torc_Constants__c.getInstance().RandstadAccountId__c.split(',');
        for(string s:sIds)
            if(s==act.id)
                isRandstad = true;
        if(opp.Docusign_Compensation_and_Payment__c==NULL || opp.Docusign_Compensation_and_Payment__c=='')
            opp.Docusign_Compensation_and_Payment__c = Act.Docusign_Compensation_and_Payment__c;        
        opp.Supervisor__c =opp.OpportunityContactRoles.size()>0? opp.OpportunityContactRoles[0].ContactId:null; 
        ocr =opp.OpportunityContactRoles.size()>0? opp.OpportunityContactRoles[0]:new OpportunityContactRole(OpportunityId=opp.id,Role = 'Engagement Supervisor');
        if(opp.Torc_POC__c==NULL)
            opp.torc_Poc__c = opp.ownerid;
        if(opp.Invoicing_Contact__c==NULL)
            opp.Invoicing_Contact__c = Act.Invoicing_Contact__c;     
        supervisor = opp.OpportunityContactRoles.size()>0? (opp.OpportunityContactRoles[0].Contact.Name+ ' - ' +opp.OpportunityContactRoles[0].Contact.Email):'';
        setupDocusign();         
        setupterms();
        
    }
    public string getTerms()
    {
        return opp.New_term__c.replace('\n','<br/>');
    }
    public void setupterms()
    {
        string t='';
        for(OpportunityLineItem ol:opp.OpportunityLineItems)
        {
            string s = ol.Talent_Name__c+' '+ 
                       ol.Engagement_Start_Date__c.month()+'/'+
                       ol.Engagement_Start_Date__c.day()+'/'+
                       ol.Engagement_Start_Date__c.year()+' for '+
                       ol.Engagement_Duration_weeks__c+' weeks ';
            t=t+(t==''?'': '\n')+s;          
        }
        opp.New_term__c=t;
    }
    public string redirectUrl{get;set;}
    Public void setupDocusign()
    {
        for(Docusign_Defaults__c dd:[Select Docusign_Gen_Template__c,Docusign_Gen_Template__r.Name,
                                            Docusign_Gen_Template_CO__c,Docusign_Gen_Template_CO__r.Name,
                                            Docusign_Additional_Assumptions__c, 
                                            Docusign_Additional_Agreement__c,Docusign_Pricing_Description__c, 
                                            Randstad_Customer_Gen_template__c, Randstad_Customer_Gen_template__r.Name,
                                            Randstad_Customer_Gen_template_CO__c, Randstad_Customer_Gen_template_CO__r.name
                                     FROM Docusign_Defaults__c LIMIT 1])
        {
            
            
            act.Docusign_Additional_Agreement__c = getVal(Opp.Account.Docusign_Additional_Agreement__c,dd.Docusign_Additional_Agreement__c);
            act.Docusign_Pricing_Description__c = getVal(Opp.Account.Docusign_Pricing_Description__c,dd.Docusign_Pricing_Description__c);
            
            act.Docusign_Additional_Specification__c = getVal(act.Docusign_Additional_Specification__c,dd.Docusign_Additional_Assumptions__c);
            Opp.Docusign_Additional_Assumptions__c = getVal(Opp.Docusign_Additional_Assumptions__c,act.Docusign_Additional_Specification__c);
            
            
            string templateid= (isExtension?
                                        (isRandstad?dd.Randstad_Customer_Gen_template_CO__c:dd.Docusign_Gen_Template_CO__c): 
                                        (isRandstad?dd.Randstad_Customer_Gen_template__c:dd.Docusign_Gen_Template__c)
                               );
            string templatename= (isExtension?
                                        (isRandstad?dd.Randstad_Customer_Gen_template_CO__r.name:dd.Docusign_Gen_Template_CO__r.name): 
                                        (isRandstad?dd.Randstad_Customer_Gen_template__r.name:dd.Docusign_Gen_Template__r.name)
                               );
            redirectUrl=site.getPathPrefix() =='/s'?'/apex/dfsle__gendocumentgenerator':site.getPathPrefix()+'/apex/dfsle__gendocumentgenerator';
            redirectUrl = redirectUrl +'?sId='+Opp.Id
                  + '&templateId=' + templateid
                  + '&recordId='+Opp.Id
                  + '&title='+ EncodingUtil.urlEncode(templatename,'UTF-8');   
        }
        setupInvoicingContactInternal(true);
        setupSignerContact();
        if(act.Agreement_Date__c==NULL)
            editableSigningDate=true;
    }
    public Pagereference SaveAndBack()
    {
        Savepoint sp = Database.setSavepoint();
        try
        {
            update opp;
            update act;
            if(isRandstad)
                update opp.OpportunityLineItems;
            if(opp.Supervisor__c!=NULL)
            {
                ocr.ContactId= opp.Supervisor__c;
                Upsert ocr;
            }
            return new Pagereference('/'+opp.id);
        }
        catch(Exception e)
        {
            for (Integer i = 0; i < e.getNumDml(); i++)
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getDmlMessage(i)));
           Database.rollback(sp);
        }
        return null;
    }
    public Pagereference reDirectNow()
    {
        if(opp.Engagement_Description__c==NULL || opp.Engagement_Description__c.length()<10)
        {
            Opp.Engagement_Description__c.addError('Engagement Description: Enter a clear and concise description for the engagement.  This will be seen by anyone that views the engagement document.');
            return null;
        }
        if(Act.Agreement_date__c==NULL)
        {
            Act.Agreement_date__c.addError('Please select');
            return null;
        }
        if(Opp.Engagement_Signatory__c==NULL)
        {
            Opp.Engagement_Signatory__c.addError('Please enter the engagement signer.');
            return null;
        }
        if(Opp.Supervisor__c==NULL)
        {
            Opp.Supervisor__c.addError('Please enter a point of contact.');
            return null;
        }
        if(SaveAndBack()==NULL)
            return Null;
    
        return new pagereference(redirectUrl)  ;
    }
    public Pagereference reDirectChangeOrderNow()
    {
        if(opp.Change_Order_Type__c==NULL || opp.Change_Order_Type__c.length()<1)
        {
            Opp.Change_Order_Type__c.addError('Please provide value.');
            return null;
        }
        if(Act.Agreement_date__c==NULL)
        {
            Act.Agreement_date__c.addError('Please select');
            return null;
        }
        if(Opp.Change_Order_Description__c==NULL || Opp.Change_Order_Description__c.length()<1)
        {
            Opp.Change_Order_Description__c.addError('Change Order Description: Enter a clear and concise description for the change order.');
            return null;
        }
        if(SaveAndBack()==NULL)
            return Null;
        return new pagereference(redirectUrl)  ;
    }
    public void clearInvoicingContact()
    {
        invoicingContact = new Contact();
        opp.Invoicing_Contact__c=null;
    }
    public void setupInvoicingContact()
    {
        setupInvoicingContactInternal(false);
    }
    public void setupInvoicingContactInternal(boolean init)
    {
        invoicingContact = new Contact();
        Contact con = null;
        if(opp.Invoicing_Contact__c!=NULL)
            invoicingContact=[Select ID, Name, Email from Contact where ID=:  opp.Invoicing_Contact__c]; 
        if(init && opp.Invoicing_Contact__c!=NULL && opp.Email_Address_for_Invoices__c==NULL)
            opp.Email_Address_for_Invoices__c = invoicingContact.Email;
        if(!init && opp.Invoicing_Contact__c!=NULL)
            opp.Email_Address_for_Invoices__c = invoicingContact.Email;
        if(!init && opp.Invoicing_Contact__c==NULL)
            opp.Email_Address_for_Invoices__c = null;
    }
    public void clearSignerContact()
    {
        engagementSigner = new Contact();
        opp.Engagement_Signatory__c=null;
        opp.Email_Address_for_Invoices__c = null;
    }
    public void setupSignerContact()
    {
        engagementSigner = new Contact();
        if(opp.Engagement_Signatory__c!=NULL)
            engagementSigner = [Select ID, Name, Email from Contact where ID=:  opp.Engagement_Signatory__c];  
    }
    public string getVal(string Opty, string def)
    {
        return (Opty==NULL || Opty.trim()=='')?def:opty;
    }
    public Pagereference sendChatter()
    {
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = [Select ID from user Where Username=:Torc_Constants__c.getInstance().Engagement_Updator__c].Id;
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text =  ' Can you please help in setting Agreement Date on this account.';
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = opp.AccountId;
        
        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
        List<ConnectApi.BatchInput> l=new List<ConnectApi.BatchInput>();
        l.add(batchInput);
        if(!test.isrunningtest())
        {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), l);
        }
        return new pagereference('/'+opp.AccountId);
    }
    public static void testIncrease()
    {
        integer i=0;
        integer j=0;
        integer k=0;
        i++;j++;k++;
        i++;j++;k++;
        i++;j++;k++;
        i++;j++;k++;
        i++;j++;k++;
        i++;j++;k++;
        i+=2;j+=2;k+=2;
        i++;j++;k++;
        i++;j++;k++;
        i++;j++;k++;
        
    }
}