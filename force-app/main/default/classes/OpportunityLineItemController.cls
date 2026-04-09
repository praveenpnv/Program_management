public class OpportunityLineItemController
{
    public boolean isAdmin{get;set;}
    public Integer AddDays{get;set;}
    public Integer AddLineItemCount{get;set;}
    public class lineItem
    {   
        public boolean isDisable{get;set;}
        public lineItem(OpportunityLineItem it, PricebookEntry pbe)
        {
           Oli=it;
           oli.Product_Code_text__c = pbe.Product2.ProductCode;
           initialSetup(pbe); 
        }
        public boolean getisUserameError()
        {
            return oli.hasErrors() && (oli.Talent_userName__c==NULL || oli.Talent_userName__c=='');
            
        }
        public void workLoadChange()
        {
            if(oli.Time_Commitment__c=='FULLTIME')
                oli.Hours_Week__c = 40;
            else
                oli.Hours_Week__c = 20;    
        }
        public Date getEngagementEndDate()
        {
            
            if(oli.Engagement_Start_Date__c!=NULL && oli.Engagement_Duration_weeks__c!=NULL)
            {
                integer i=(Integer)oli.Engagement_Duration_weeks__c;
                oli.Engagement_End_Date__c = oli.Engagement_Start_Date__c.adddays(Integer.valueOf(i*7)-1);
                if(i<oli.Engagement_Duration_weeks__c)
                    oli.Engagement_End_Date__c = placement.addWorkingDays(oli.Engagement_End_Date__c,(Integer)((oli.Engagement_Duration_weeks__c-i)/0.2));
            }
            else
                oli.Engagement_End_Date__c =null;
            return oli.Engagement_End_Date__c;
        }
        public boolean setupForHiringProduct()
        {
            if(productName==Torc_Constants__c.getInstance().Hiring_Product__c)
            {
                if(oli.margin__c==0 || oli.margin__c==null || oli.Direct_revenue__c==NULL || oli.Direct_revenue__c==null)
                {
                    oli.Customer_Hourly_Bill_Rate__c = 0;
                }
                else
                {
                    oli.Customer_Hourly_Bill_Rate__c  =  (oli.Direct_revenue__c/(oli.margin__c/100));
                } 
                return true;   
            }
            return false;
        }
        public boolean setupForTransactionFee()
        {
            /*if(productName=='Transaction Fee')
            {
                if(oli.margin__c==0 || oli.margin__c==null || oli.Direct_revenue__c==NULL || oli.Direct_revenue__c==null)
                {
                    oli.Customer_Hourly_Bill_Rate__c = 0;
                }
                else
                {
                    oli.Customer_Hourly_Bill_Rate__c  =  (oli.Direct_revenue__c/(oli.margin__c/100));
                } 
                return true;   
            }*/
            return false;
        }
        public decimal getTotalPrice()
        {
            setupForHiringProduct();
            setupForTransactionFee();
            getEngagementEndDate();
            if(oli.Engagement_Duration_weeks__c!=null && oli.Hours_Week__c !=NULL)
                oli.Quantity = oli.Engagement_Duration_weeks__c*oli.Hours_Week__c;
            else
                oli.Quantity = NULL;
            oli.UnitPrice = oli.Customer_Hourly_Bill_Rate__c;
            return ((oli.Quantity!=NULL && oli.UnitPrice!=NULL)?oli.Quantity*oli.UnitPrice:0);
        }
        public decimal getWeeklyPrice()
        {
            setupForHiringProduct();
            setupForTransactionFee();
            if(oli.Hours_Week__c !=NULL && oli.Customer_Hourly_Bill_Rate__c!=NULL)
               return oli.Hours_Week__c * oli.Customer_Hourly_Bill_Rate__c;
            return 0;
        }
        public decimal getTalentWeeklyPrice()
        {
            if(oli.Hours_Week__c !=NULL && oli.Talent_Hourly_Pay_Rate__c!=NULL)
               return oli.Hours_Week__c * oli.Talent_Hourly_Pay_Rate__c;
            return 0;
        }
        public void initialSetup(PricebookEntry pbe)
        {
            pbentry = pbe;
            isSelected = false;
            productId = pbe.product2Id;
            productName =pbe.product2.name;
            productCode = pbe.product2.productCode;
            productDescription = pbe.product2.Description;
        }
        public integer rowNumber{get;set;}
        public boolean showsubProductError{get;set;}
        public PricebookEntry pbentry;
        public OpportunityLineItem Oli{get;set;}
        public boolean isSelected{get;set;}
        public string productId{get;set;}
        public string productName{get;set;}
        public string productCode{get;set;}
        public string productDescription{get;set;}
    }
    public integer MaxrowNumber=1;
    public string userType{get;set;}    
    Public Opportunity opty{get;set;}
    public string SubTitle{get;set;}
    public string Title{get;set;}
    
    public string newrowProductId{get;set;}
    public integer deleteRowNumber{get;set;}
    public Map<id,PricebookEntry> priceBookEntrymap;
    List<SObject> lstDeleteListAll=new list<SObject>();
    public list<lineItem> lstLineItems{get;set;}
    
    public list<lineItem> getlstLineItemsTAAS()
    {
        list<lineItem> lst=new list<lineItem>();
        for(lineItem l:lstLineItems)
        {
            if(l.productName!= HiringProduct && l.productName!= TransactionFeeProduct)
                lst.add(l);
        }
        return lst;
    }
    public boolean getshowTalentTab()
    {
        for(lineItem l:lstLineItems)
        {
            if(l.productName!= HiringProduct && l.productName!= TransactionFeeProduct)
                return true;
        }
        return false;
    }
    public boolean getshowHiringTab()
    {
        for(lineItem l:lstLineItems)
        {
            if(l.productName== HiringProduct)
                return true;
        }
        return false;
    }
    public boolean getshowTransactionFeeTab()
    {
        for(lineItem l:lstLineItems)
        {
            if(l.productName== TransactionFeeProduct)
                return true;
        }
        return false;
    }
    public list<lineItem> getlstLineItemsHIRING()
    {
        list<lineItem> lst=new list<lineItem>();
        for(lineItem l:lstLineItems)
        {
            if(l.productName== HiringProduct)
                lst.add(l);
        }
        return lst;
    }
    public list<lineItem> getlstLineItemsTransactionFee()
    {
        list<lineItem> lst=new list<lineItem>();
        for(lineItem l:lstLineItems)
        {
            if(l.productName== TransactionFeeProduct)
                lst.add(l);
        }
        return lst;
    }
    public decimal getTotal()
    {
        Decimal amt=0;
        for(lineItem a: lstLineItems)
        {
            amt += a.getTotalprice();
        }
        return amt;
    }
    public void dummyRefresh()
    {
    }
    
    public boolean getshowBudget()
    {
        return lstLineitems==null || lstlineitems.size()==0?true:false;
    }
    public void workLoadChange()
    {
        for(lineitem l:lstLineItems)
            if(l.rowNumber==deleteRowNumber)
                l.workLoadChange();
    }
    public void removeRow()
    {
        List<lineItem> lst=new list<lineItem>();
        for(lineitem l:lstLineItems)
        {
            l.showsubProductError = false;
            if(l.rowNumber!=deleteRowNumber)
                lst.add(l);
            else 
            {
                if(l.oli.ID!=NULL)
                    lstDeleteListAll.add(l.oli);
            }
        }
        lstLineItems = lst;
    }
    public void addnewRow()
    {
        for(lineitem l:lstLineItems)
        {
            l.showsubProductError = false;
        }
        if(AddLineItemCount==null || AddLineItemCount<1)
            AddLineItemCount=1;
        for(integer i=0;i<AddLineItemCount;i++)
        {
            PricebookEntry pre = priceBookEntrymap.get(newrowProductId);
            lineItem lit;
            OpportunityLineItem opl=new OpportunityLineItem(Product_Type__c = pre.product2.Name, priceBookEntryID = pre.Id, Product2Id =pre.Product2id, Quantity=1, OpportunityID=opty.Id);
            if(opty.Job_Time_Commitment__c!=NULL && opl.Time_Commitment__c==NULL)
                opl.Time_Commitment__c = opty.Job_Time_Commitment__c=='FULLTIME'?'FULLTIME':'HALFTIME';
            opl.Product_Category__c =  opty.Job_category__c;
            if(Opty.Job_Time_Commitment__c!=NULL)
                opl.Hours_Week__c = opty.Job_Time_Commitment__c=='FULLTIME'?40:20;
            if(pre.UnitPrice!=null && pre.UnitPrice!=0)
                opl.Unitprice = pre.UnitPrice;
                
            lit = new lineItem(opl,pre);
            lit.rowNumber = MaxrowNumber++;
            lstLineItems.add(lit);  
            lit.isSelected=true;
            if(opl.Product_Type__c==HiringProduct || opl.Product_Type__c==TransactionFeeProduct)
            {
                if(opl.Product_Type__c==HiringProduct)
                    opl.margin__c = 100;    
                opl.Time_Commitment__c = 'HALFTIME';
                opl.Hours_Week__c = 1;
                opl.Engagement_Duration_weeks__c=1;
                opl.Talent_Hourly_Pay_Rate__c=0;
            }
        }    
    }
    
    public List<SelectOption> getProducts() 
    {
        List<SelectOption> options = new List<SelectOption>();
        for(id id:priceBookEntrymap.keyset())
        {   
            if(priceBookEntrymap.get(id).isActive && priceBookEntrymap.get(id).Product2.Torc_Visible__c)
                options.add(new SelectOption(Id,priceBookEntrymap.get(id).Product2.Name));     
        }
        return options;
    }
    private void setupContent()
    {
        lstLineItems = new list<lineItem>();
        Map<id,List<lineItem>>productMap=new Map<id,List<lineItem>>();
        priceBookEntrymap = new Map<id,PricebookEntry>();
        id priceBookID =null;
        priceBookID = opty.Pricebook2ID;
        if(priceBookID == null)
            priceBookID = [Select ID from priceBook2 where Name='Standard Price Book'].Id;

        for(PricebookEntry pbe: [Select Id, IsActive,Product2Id, Product2.Torc_Visible__c,Product2.Name, Product2.ProductCode,Product2.Description, UnitPrice
                                from PricebookEntry
                                where Pricebook2Id=:priceBookID
                                Order By Product2.Order__c, Product2.Name])
        {
            priceBookEntrymap.put(pbe.product2Id,pbe);
        }                        
     
        for(OpportunityLineItem opl:[Select ID, Original_Rate__c ,Torc_User__c ,Time_Commitment__c, Product_Category__c,Product_Type__c,OpportunityID,Product2ID,Product2.ProductCode,Product_Code_text__c,Talent_Name__c,Talent_Username__c,
                                        UnitPrice, Quantity, Totalprice, Direct_revenue__c,Margin__c,
                                        Engagement_Start_Date__c,Engagement_End_Date__c, Engagement_Duration_weeks__c,
                                        Talent_Hourly_Pay_Rate__c, Hours_Week__c, Bank_Fee__c, Customer_Hourly_Bill_Rate__c,Background_Check_Done__c
                                        from OpportunityLineItem 
                                        Where OpportunityID=:opty.Id AND Product2.Name <>'Payrole'])
        {

            addInList(opl,productMap);
            if(opty.Job_Time_Commitment__c!=NULL && opl.Time_Commitment__c==NULL)
                opl.Time_Commitment__c = opty.Job_Time_Commitment__c=='FULLTIME'?'FULLTIME':'HALFTIME';
                
        }
    }
    
    public void addInList(OpportunityLineItem Oli,Map<id,List<lineItem>>productMap)
    {
        PricebookEntry pre;
        lineItem lit;
        pre = priceBookEntrymap.get(oli.Product2ID);
        lit = new lineItem(oli,pre);
        lit.rowNumber = MaxrowNumber++;
        lit.isSelected = true;
        lstLineItems.add(lit);
        if(productMap.get(pre.Product2Id)==null)
            productMap.put(pre.Product2Id, new List<lineItem>());    
        productMap.get(pre.Product2Id).add(lit);
    }
    public void basicSetup()
    {
        id id1 = userinfo.getProfileId();
        string profileName = [select Name from profile where id = :id1].Name;
        user user = [select id,Torc_Admin__c from User where id = :userInfo.getuserId()];
        isAdmin = (profileName == 'System Administrator' || user.Torc_Admin__c==TRUE) ;
        AddLineItemCount=1;
        FirsterrorMessage ='';
        stillShowForm = true;
        showSaveButton = true;
    }
    public boolean stillShowForm{get;set;}
    public boolean showSaveButton{get;set;}
    public string FirsterrorMessage{get;set;}
    public string returnID{get;set;}
    Public Map<String,String> JobOpportunityUSers{get;set;}
    public List<SelectOption> getJobOpportunityUSerList() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-None-'));     
        for(string id:JobOpportunityUSers.keyset())
        {   
            options.add(new SelectOption(Id,JobOpportunityUSers.get(id)));     
        }
        return options;
    }
    public boolean getShowDropDown()
    {
        return JobOpportunityUSers.keyset().size()>0?true:false;
    }
    public void OpportunityProjectLineItemControllerForOpty()
    {
        JobOpportunityUSers = new Map<String,string>();
        title = 'Opportunity Line Item';
        basicSetup();
        string OppID = ApexPages.currentPage().getParameters().get('oppId');
        Opty = [Select Use_Pay_Rate_To_Invoice__c, AccountId, ID,name,Pricebook2ID,CloseDate,StageName,IsClosed,Job_Opportunity__c, Parent_opportunity__c
                    , Job_category__c, Job_Time_Commitment__c,Background_Check_Needed__c
               from Opportunity where ID=:OppID];
        if(opty.Job_Opportunity__c!=NULL)
        {
            for(Torc_Match__c match:[Select ID, status__c, Torc_User__c, User_Full_Name__c
                                     from Torc_Match__c
                                     WHERE Torc_Job_Opportunity__c=:opty.Job_Opportunity__c AND DELETE_From_Platform__c = FALSE
                                         AND Torc_User__c!=NULL AND Torc_User__c!='' AND 
                                         (
                                             Status__C!='SHORTLISTED' 
                                             AND Status__C!='SKIPPED'
                                             AND Status__C!='REJECTEDBYMEMBER'
                                             AND Status__C!='REJECTEDBYCUSTOMER'
                                             AND Status__C!='INTERESTED'
                                             AND Status__C!='REJECTEDBYMATCHER'
                                         )])
            {
                string un = match.Torc_User__c +' - '+ match.User_Full_Name__c;
                //string un = match.Torc_Application__r.Torc_User__r.Name;
                JobOpportunityUSers.put(match.Torc_User__c,un);
            }                         
        }
        SubTitle=Opty.Name;
        setupContent();
        returnID = Opty.ID;
    }
    public string extensionMismatches{get;set;}
    public string validateExistingPlacement()
    {
        extensionMismatches = '';
        newParentOpportunity=null;
        if(opty.isClosed)
            return '';
        set<id> setUsers=new set<id>();
        Map<id,Placement__c> finalsetUsers=new Map<id,Placement__c>();
        map<string,Torc_user__c> mapUserName=new map<string,Torc_user__c>();
        for(lineItem li:lstLineItems)    
        {
            if(li.oli.Torc_User__c!=NULL)
                setUsers.add(li.oli.Torc_User__c);
            if(li.oli.Talent_Username__c!=NULL && li.oli.Talent_Username__c.trim()!='')
                mapUserName.put(li.oli.Talent_Username__c.toLowerCase(),null);    
        }
        if(mapUserName.keyset().size()>0)
        {
            for(Torc_user__c tu:[Select Id,Name from Torc_user__c where name in:mapUserName.keyset()])
                mapUserName.put(tu.name.tolowercase(),tu);
        }
        for(lineItem li:lstLineItems)    
        {
            id userId=null;
            if(li.oli.Torc_User__c!=NULL)
                userId = li.oli.Torc_User__c;
            else if(li.oli.Talent_Username__c!=NULL && li.oli.Talent_Username__c.trim()!='' && mapUserName.get(li.oli.Talent_Username__c.toLowerCase())!=NULL)
            {
                userId = mapUserName.get(li.oli.Talent_Username__c.toLowerCase()).id;
                li.oli.Torc_User__c = userId;
            }
            if(userId!=null)
            {
                finalsetUsers.put(userId,null);
            }    
        }
        for(Placement__c pm:[Select Id, Torc_user__r.Name,Torc_user__c,Last_Working_Day__c,Latest_Opportunity__c,Latest_Opportunity__r.Name from Placement__c where Torc_user__c in :finalsetUsers.keyset() AND Account__c=:Opty.AccountId AND Last_Working_Day__c!=NULL Order By CreatedDate])
        {
            finalsetUsers.put(pm.Torc_user__c,pm);
        } 
        for(lineItem li:lstLineItems)    
        {
            if(li.oli.Torc_User__c !=NULL && finalsetUsers.get(li.oli.Torc_User__c)!=NULL && li.oli.Customer_Hourly_Bill_Rate__c>0)
            {
                Placement__c placement=finalsetUsers.get(li.oli.Torc_User__c);
                Date nextEStartDate = getNextWorkingDay(placement.Last_Working_Day__c);
                if(opty.Parent_Opportunity__c == NULL)
                {
                    newParentOpportunity = placement.Latest_Opportunity__c;
                    extensionMismatches += '<font style="color:red">Alert:</font> This opportunity looks to be an extension of parent <font style="color:blue">'+placement.Latest_Opportunity__r.Name +'</font>.   If true, please click the the Link Parent Opty button below.<br/>';
                
                }
                if(li.oli.Engagement_Start_Date__c<nextEStartDate)
                {
                    extensionMismatches +='<font style="color:red">Alert</font>: User <font style="color:blue">'+placement.Torc_user__r.Name+'</font> is an existing placement and the extension start date should be <font style="color:blue">'+nextEStartDate.format()+'</font>.   Please update below and save.<br/>';
                }
                
            }
        }        
        
        return '';
        
    }
    public static Date getNextWorkingDay(Date dt)
    {
        string wday = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('EEE');
        integer addday =(wDay=='Sat'?2:(wDay=='Fri'?3:1));
        return dt.adddays(addday);
    }
    public string hiringProduct{get;set;}
    public string transactionFeeProduct{get;set;}
    public OpportunityLineItemController()
    {
        isAdmin=false;
        extensionMismatches='';
        newParentOpportunity=null;
        newParentOpportunity=null;
        hiringProduct = Torc_Constants__c.getinstance().Hiring_Product__c;
        transactionFeeProduct = 'Transaction Fee';
        basicSetup();
        string OppID = ApexPages.currentPage().getParameters().get('oppId');
        if(OppID!=NULL && OppID!='')
        {
            OpportunityProjectLineItemControllerForOpty();
            return;
        } 
    }

    public boolean addError(sObject sobj)
    {
        boolean error=false;
        OpportunityLineItem li= (OpportunityLineItem) sObj;
        if(li.product_Type__c==HiringProduct)
        {
            if(li.Direct_revenue__c ==NULL || li.Direct_revenue__c ==0)
            {
                li.Direct_revenue__c.addError('Please add');
                error = true;    
            }
            if(li.margin__c ==NULL || li.margin__c ==0)
            {
                li.margin__c.addError('Please Add');
                error = true;    
            }
        }
        if(li.Customer_Hourly_Bill_Rate__c ==null || (li.Customer_Hourly_Bill_Rate__c ==0 && isAdmin==FALSE))
        {
            li.Customer_Hourly_Bill_Rate__c.addError('Add Rate');
            error = true;
        }
        if(li.Time_Commitment__c ==null || li.Time_Commitment__c =='')
        {
            li.Time_Commitment__c.addError('Add Workload');
            error = true;
        }
        if((li.Talent_UserName__c ==null || li.Talent_UserName__c =='') && isAdmin==FALSE)
        {
            li.Talent_UserName__c.addError('Add User');
            error = true;
        }
        if((li.Talent_Hourly_Pay_Rate__c ==null || li.Talent_Hourly_Pay_Rate__c ==0) && li.Product_Code_text__c!='Hiring Fee' && isAdmin==FALSE)
        {
            li.Talent_Hourly_Pay_Rate__c.addError('Add Rate');
            error = true;
        }
        if(li.Hours_Week__c !=null && li.Hours_Week__c !=40 && li.Time_Commitment__c=='FULLTIME')
        {
            li.Hours_Week__c.addError('Should be 40');
            error = true;
        }
        if(li.Hours_Week__c ==40 && li.Time_Commitment__c=='HALFTIME')
        {
            li.Hours_Week__c.addError('Should not be 40');
            error = true;
        }
        
        if(li.Engagement_Start_Date__c ==null)
        {
            li.Engagement_Start_Date__c.addError('Add Start Date');
            error = true;
        }
        if( li.product_Type__c==TransactionFeeProduct && li.Engagement_Start_Date__c !=null && li.Engagement_Start_Date__c.Day() !=1)
        {
            li.Engagement_Start_Date__c.addError('Select First Day Of Month');
            error = true;
        }
        if(li.Engagement_Duration_weeks__c ==null || li.Engagement_Duration_weeks__c<=0)
        {
            li.Engagement_Duration_weeks__c.addError('Add Weeks');
            error = true;
        }
        if(li.Hours_Week__c ==null || li.Hours_Week__c <=0)
        {
            li.Hours_Week__c.addError('Add Hours/Week');
            error = true;
        }
        if(li.Engagement_Duration_weeks__c !=null)
        {
            decimal diff=(li.Engagement_Duration_weeks__c-(li.Engagement_Duration_weeks__c.intValue()));
            if(diff!=0 && diff!=0.2 && diff!=0.4 && diff!=0.6 && diff!=0.8)
            {
                li.Engagement_Duration_weeks__c.addError('Invalid');
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Engagement Duration week should be something like X.0, X.2, X.4, X.6 or X.8'));
                error = true;
            }    
        }
        
        return Error;
    }
    public pagereference Save()
    {
        return Save(false,true);
    }
    /*public static decimal getWeeksBetween(date sd,date ed)
    {
        decimal num=1;
        num =  ((sd.daysbetween(ed)+1)/7.0).round(System.RoundingMode.DOWN);
        system.debug(num);
        sd = sd.adddays(7*Integer.valueOf(num));
        system.debug(sd);
        integer daysNow=0;
        while(sd<=ed)
        {
            string wday = DateTime.newInstance(sd.year(),sd.month(),sd.day()).format('EEE');
            if(wDay!='Sun' && wDay!='Sat')
                daysNow++;
            sd=sd.adddays(1);
            system.debug(daysNow);
        }
        system.debug(num+(daysNow*2/10.0));
        return num+(daysNow*2/10.0);
    }*/
    
    public pagereference saveWithoutPlacementCheck()
    {
        return Save(false,false);
    }
    public id newParentOpportunity{get;set;}
    public void updateParentOpportunityonly()
    {
        if(newParentOpportunity!=NULL)
        {
            opty.Parent_Opportunity__c = newParentOpportunity;
            update opty;
        }
        LetMeDoIt();    
    }
    public void LetMeDoIt()
    {
        extensionMismatches='';
        newParentOpportunity=null;
    }
    private pagereference Save(boolean onlyErrorCheck,boolean checkPlacement)
    {        
        id firstlineItem=null;
        List<sObject> lst = new List<sObject>();
        List<sObject> lstDel = new List<sObject>();
        boolean error =false;
        boolean atleastOne=false;
        integer numberOfProcessingFeeItems=0;
        for(lineItem li:lstLineItems)
        {
            if(li.isSelected)
            {
                if(opty.Job_category__c!=NULL && opty.Job_category__c!='')
                    li.oli.Product_Category__c =  opty.Job_category__c;
                atleastOne = true;
                //if(li.oli.UnitPrice==0 && li.oli.Talent_Hourly_Pay_Rate__c ==0 && li.oli.id!=null)
                //    lstDel.add(li.oli);
                //if(li.oli.UnitPrice!=0)
                lst.add(li.oli);
                if(addError(li.oli))
                    error = true;
                li.setupForHiringProduct();  
                li.setupForTransactionFee();  
                if(li.oli.Engagement_Start_Date__c!=NULL && li.oli.Engagement_Duration_weeks__c!=NULL)
                    li.getEngagementEndDate();
                else
                    li.oli.Engagement_End_Date__c =null;    
                if(li.oli.Engagement_Duration_weeks__c!=null && li.oli.Hours_Week__c !=NULL)
                    li.oli.Quantity = li.oli.Engagement_Duration_weeks__c*li.oli.Hours_Week__c;
                else
                    li.oli.Quantity = NULL;
                li.oli.UnitPrice = li.oli.Customer_Hourly_Bill_Rate__c;
            }
        }
        if(error)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:Please solve these errors.'));
            return null;
        }
        if(onlyErrorCheck)
            return new Pagereference('www.salesforce.com');
        
        extensionMismatches='';
        newParentOpportunity=null;
        if(checkPlacement && Torc_Constants__c.getinstance().Run_Extension_Check__c)
        {
            validateExistingPlacement();
            if(extensionMismatches!='')
                return null;
        }
        
        Savepoint sp = Database.setSavepoint();
        try
        {
                List<OpportunityLineItem> lst1 = new List<OpportunityLineItem>();
                Date forecastStartDate = null;
                for(sObject rec: lst)
                {
                    OpportunityLineItem ol = (OpportunityLineItem)rec;
                    if((forecastStartDate == null && ol.Engagement_Start_Date__c!=null) || ( forecastStartDate != null && ol.Engagement_Start_Date__c!=null && forecastStartDate>ol.Engagement_Start_Date__c))
                        forecastStartDate = ol.Engagement_Start_Date__c;    
                    lst1.add(ol);
                }
                Upsert lst1;
                firstlineItem = lst1.size()>0?lst1[0].id:NULL;
                lstDel.addall(lstDeleteListAll);
                if(lstDel.size()>0)
                    delete lstDel;
                if(firstlineItem!=NULL)
                    update new Opportunity(id=Opty.Id, Current_Lineitem__c = firstlineItem);  
        }
        catch(System.DmlException e)
        {
           for (Integer i = 0; i < e.getNumDml(); i++)
           {
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getDmlMessage(i)));
           }
           Database.rollback(sp);
           return null;
        }
        catch(exception ex)
        {
            ApexPages.addmessage(new ApexPages.message( ApexPages.severity.Error,ex.getMessage()));
            Database.rollback(sp);
            return null;
        }
            return new pagereference('/'+ opty.id);
    }
    public pagereference cancel()
    {
        if(returnID!=null && returnID!='')
            return new Pagereference('/'+returnID);
        return new Pagereference('/home/home.jsp');
    }
}