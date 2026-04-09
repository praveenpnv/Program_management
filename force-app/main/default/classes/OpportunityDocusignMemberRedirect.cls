Public without sharing Class OpportunityDocusignMemberRedirect
{
    public integer step{get;set;}
    public Opportunity Opp{get;set;}
    public OpportunityLineItem oli{get;set;}
    public Contact engagementSigner{get;set;}
    public Map<string,OpportunityLineItem> mapOli;
    public integer loiCount{get;set;}
    public List<OpportunityLineItem> getOliList()
    {
        List<OpportunityLineItem> l=new List<OpportunityLineItem>();
        for(OpportunityLineItem oli:opp.OpportunityLineItems)
        {
            if(oli.Talent_userName__c ==selectedoli)
                l.add(oli);
        }
        return l;
    }
    public Decimal gethalfTimeVal()
    {
        List<OpportunityLineItem> l=new List<OpportunityLineItem>();
        decimal hval=20;
        for(OpportunityLineItem oli:opp.OpportunityLineItems)
        {
            if(oli.Talent_userName__c ==selectedoli && oli.Time_Commitment_Text__c=='Half-Time')
                hVal = oli.Hours_Week__c;
        }
        return hval;
    }
    Public List<Selectoption> getUserList()
    {
        List<SelectOption> options = new List<SelectOption>();
        for(string handle:mapOli.keyset())
        {   
            OpportunityLineItem ol = mapOli.get(handle);
            string nm = ol.Talent_Username__c+' - '+ol.Torc_user__r.Full_Name__c +'('+ol.Torc_user__r.Email__c+')';
            options.add(new SelectOption(handle,nm));     
        }
        return options;
    }
    public boolean forSpecialAccount{get;set;}
    public Map<id,Id>specialAccounts{get;set;}
    public void specialAccountSetup()
    {
        forSpecialAccount = false;
        specialAccounts = new Map<id,Id>();
        for(Docusign_Defaults__c dd:[Select id,Special_Accounts_Member__c ,DocuSign_Gen_Template_Talent__c
                                     FROM Docusign_Defaults__c LIMIT 1])
        {
            if(dd.Special_Accounts_Member__c!=NULL)
            {
                for(string s:dd.Special_Accounts_Member__c.split(','))
                {
                    s=s.trim();
                    List<string> spl = s.split('/');
                    specialAccounts.put(spl[0].trim(),spl[1].trim());
                }
            }
            id genTemplateId = specialAccounts.keyset().contains(opp.accountId)?specialAccounts.get(opp.AccountId):dd.Docusign_Gen_Template_Talent__c;
            forSpecialAccount= specialAccounts.keyset().contains(opp.accountId);
            dfsle__GenTemplate__c genTemplate =[Select id,Name from dfsle__GenTemplate__c where id=:genTemplateId];
            
            redirectUrl=site.getPathPrefix() =='/s'?'/apex/dfsle__gendocumentgenerator':site.getPathPrefix()+'/apex/dfsle__gendocumentgenerator';
            redirectUrl = redirectUrl +'?sId='+opp.Id
                  + '&templateId=' + genTemplate.id
                  + '&recordId='+opp.Id
                  + '&title='+ EncodingUtil.urlEncode(genTemplate.Name,'UTF-8');   
        }
    }
    public OpportunityDocusignMemberRedirect(ApexPages.StandardController controller)
    {        
        step = 1;
        mapOli = new Map<string,OpportunityLineItem>();
        opp=(opportunity) controller.getRecord();
        opp=[SELECT Account.Name,Account.Default_termination_Notice_Formula__c,AccountId,Half_Time_Value__c , Account.Docusign_Talent_Agreement_Instruction__c,  Engagement_Description_Talent__c,Docusign_Additional_Assumptions_Talent__c,Current_LineItem__c, Current_LineItem_Contact__c,
                (Select ID, Product_Category__c, Name, Total_Payment__c, Talent_Terms__c,Time_Commitment__c,Time_Commitment_Text__c, 
                Torc_User_Contact__c, Total_Hours__c , Talent_Hourly_Pay_Rate__c , TotalPrice ,Engagement_Start_Date__c, Hours_Week__c, Engagement_Duration_weeks__c, Product_Type__c, Weekly_Talent_Rate__c
                ,Torc_User_Contact__r.email,Torc_User__c, Talent_Username__c, Torc_User__r.given_name__c,Torc_User__r.Family_Name__c, Torc_User__r.email__c,Torc_user__r.Full_Name__c,
                Talent_terms_new2__c,Talent_terms_formula__c
                , Talent_Name_Formula__c
                FROM OPPORTUNITYLINEITEMS Where Torc_User__c!=NULL Order By Engagement_Start_Date__c)                
             FROM Opportunity Where ID=:opp.id];
        specialAccountSetup();
        for(OpportunityLineitem oline:opp.OpportunityLineItems)
        {
            mapOli.put(oline.Talent_username__c,oline);
        }     
        loiCount =  opp.OpportunityLineItems.size();   
        if(loiCount ==1)
        {
            selectedoli = opp.OpportunityLineItems[0].Talent_username__c;
        }   
        if(loiCount ==0)
            step = 0;
    }
    public string selectedoli{get;set;}
    public void movePrev()
    {
        Step=1;
    }
    public void chkMovenext()
    {
        if(step==1 && loiCount==1)
        {
            moveNext();
        }
    }
    public void moveNext()
    {
        oli=mapOli.get(selectedoli);
        opp.Current_LineItem__c = oli.id;
        update opp;
        
        string s='';
        for(OpportunityLineItem ol:opp.OpportunityLineItems)
        {
            if(ol.Talent_userName__c ==selectedoli)
                s+= ((s==''?'' :'\n')+ol.talent_terms_formula__c);
        }
        oli.Talent_terms_new2__c = s;
        update oli;
        
        setupDocusign();  
        Step=2;          
    }
    public string getterms()
    {
        return oli.Talent_terms_new2__c==null?'':oli.Talent_terms_new2__c.replace('\n','<br/>');
        
    }
    public string redirectUrl{get;set;}
    Public void setupDocusign()
    {
        if( opp.Docusign_Additional_Assumptions_Talent__c==NULL ||  opp.Docusign_Additional_Assumptions_Talent__c.trim()=='')
            opp.Docusign_Additional_Assumptions_Talent__c = opp.Account.Docusign_Talent_Agreement_Instruction__c;
        setupSignerContact();
    }
    public void setupSignerContact()
    {
        engagementSigner = null;
        if(oli.Torc_User_Contact__c!=NULL && oli.Torc_User_Contact__r.email==oli.torc_User__r.email__c)
        {
            for(Contact c:[Select ID, Name, FirstName,LastName, Email,Torc_user__c from Contact where (ID=:oli.Torc_User_Contact__c)])  
            {
                engagementSigner = c;    
            }
        }
        if(engagementSigner==NULL)
        {
            for(Contact c:[Select ID, Name, FirstName,LastName, Email,Torc_user__c from Contact where (Email=:oli.torc_User__r.email__c)])  
            {
                engagementSigner = c;    
            }
        }
        if(engagementSigner==NULL)
        {
            engagementSigner = new Contact(FirstName = oli.Torc_User__r.given_name__c
                                          ,LastName = oli.Torc_User__r.Family_name__c        
                                          ,Email = oli.Torc_User__r.Email__c,
                                          AccountId = Torc_Constants__c.getInstance().Members_Account__c
                                          ,Torc_user__c = oli.Talent_Username__c);               
        }                                  
    }
    Public static void CreateMemberContact(SET<ID> torcUserIds)
    {
    
        MAP<ID,Torc_User__c> mapTu = new MAP<ID,Torc_User__c>([Select ID, Email__c,given_name__c,Family_name__c,Name,SFDC_Contact__c from Torc_User__c where Id in :torcUserIds]);
        MAP<String,Contact> mapContacts=new map<String,Contact>();
        system.debug('CONTACTCREATION:');
        system.debug(Torc_Constants__c.getInstance().Members_Account__c);
        
        set<string> emailSet=new set<string>();
        for(Torc_User__c tu:mapTu.Values())
        {
            if(tu.SFDC_Contact__c==NULL && tu.email__c!=NULL && tu.email__c!='')
            {
                emailset.add(tu.email__c.toLowercase());
                Contact con = new Contact(FirstName = tu.given_name__c
                                          ,LastName = tu.Family_name__c        
                                          ,Email = tu.Email__c
                                          ,AccountId = Torc_Constants__c.getInstance().Members_Account__c
                                          ,Torc_user__c = tu.Name
                                          , recordTypeId=Torc_Constants__c.getInstance().Default_Contact_Recordtype__c);  
                system.debug(con);                          
                mapContacts.put(tu.email__c.toLowerCase(),con);                           
            }
        }
        if(emailSet.size()>0)
        {
            for(contact con:[select Firstname,LastName,email,AccountId,Torc_User__c from contact where email in:emailSet])
            {
                con.Torc_User__c = mapContacts.get(con.email.toLowerCase()).Torc_user__c;
                mapContacts.put(con.email.toLowerCase(),con);
            }
        }
        if(mapContacts.keyset().size()>0)
        {
            torcRD1Integration.runningtorcCodeToUpdateData = true;
            upsert mapContacts.values();
            torcRD1Integration.runningtorcCodeToUpdateData = false;
        }
        for(Torc_User__c tu:mapTu.Values())
            if(tu.SFDC_Contact__c==NULL && tu.email__c!=NULL && tu.email__c!='')
                tu.SFDC_Contact__c = mapContacts.get(tu.email__c.toLowerCase()).id;
        update mapTu.values();        
    }
    public Pagereference SaveAndBack()
    {
        torcRD1Integration.runningtorcCodeToUpdateData = true;
        upsert engagementSigner; 
        oli.Torc_User_Contact__c = engagementSigner.id;
        update oli;
        opp.Current_LineItem_Contact__c =engagementSigner.id;
        update opp;
        torcRD1Integration.runningtorcCodeToUpdateData = false;
        return new Pagereference('/'+opp.id);
    }
    public Pagereference reDirectNow()
    {
        if(opp.Engagement_Description_Talent__c==NULL || opp.Engagement_Description_Talent__c.length()<10)
        {
            Opp.Engagement_Description__c.addError('Engagement Description: Enter a clear and concise description for the talent engagement. This will be seen by anyone viewing the talent agreement.');
            return null;
        }
        if(SaveAndBack()==NULL)
            return Null;
        return new pagereference(redirectUrl)  ;
    }
    
}