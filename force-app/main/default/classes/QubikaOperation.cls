Public Without Sharing Class QubikaOperation
{
    public string loadType{get;set;}
    public Dummy_Object__c dummyDate{get;set;}
    public List<googleAPI.paymentCls> lstPayments{get;set;}
    public List<googleAPI.rowCls> lstContacts{get;set;}
    public Account account{get;set;}
    public Opportunity opp{get;set;}
    public opportunityLineItem oppLineItem{get;set;}
    public string warningMessage{get;set;}
    Public List<String>ErrorList{get;set;}
    public QubikaOperation()
    {    
        ErrorList=new List<String>();
        //emailaddress='sumit@torc.dev';
        emailaddress='';
        LoggedInUserName = 'Guest';
        dateTime dt = Datetime.newInstance(date.Today().year(),date.Today().Month(),5);
        selectedDate = dt.month()+'-'+dt.year();
        id currentUser = UserInfo.getuserId();
        user u=[Select Id, Profile.Name,Name,Torc_Admin__c from User where id=:currentUser];
        if(u.Profile.Name=='System Administrator' || u.Torc_Admin__c==true)
        {
            usertype = 'SuperAdmin';
            LoggedInUserName = u.Name;
        }
        ELSE if(u.Profile.Name=='Torc Employee' || u.Profile.Name=='Torc Executive')    
        {
            usertype = 'Internal';
            LoggedInUserName = u.Name;
        }
        ELSE
            usertype = 'EXTERNAL';    
        
        //usertype = 'Admin';
        dummyDate= new Dummy_Object__c();
        dummyDate.Date__c = Date.newInstance(Date.today().year(),Date.today().month(),1);
        lstPayments = new List<googleAPI.paymentCls>();
        lstContacts = new List<googleAPI.rowCls>();
        account = [Select ID from Account Where id=:Torc_Constants__c.getInstance().Qubika_Account__c];
        if(userType=='EXTERNAL')
            screen = 'LOGIN';
        else
            screen = 'DATA';    
    }
    public static string getOpportunityName(Date dt)
    {
        return 'Qubika ' + dt.month().toString().leftpad(2,'0')+'/'+dt.year();
    }
    Public boolean loadOpportunityAndLineItem()
    {
        ErrorList.clear();
        Date dt1 = Date.newInstance(dummyDate.Date__c.year(),dummyDate.Date__c.month(),10).addmonths(1);
        dt1 = Date.newInstance(dt1.year(),dt1.month(),1).adddays(-1);
        opp=NULL;
        for(Opportunity op:[SELECT Id, Name, Closedate,StageName, AccountId,Account.Name,
                                (Select ID ,Engagement_Start_Date__c, Customer_Hourly_Bill_Rate__c ,Unitprice,TotalPrice,OpportunityId
                                    FROM OpportunityLineItems where Product2.name='Transaction Fee'),
                                (Select ID from Non_Torc_payments__r where Payment_Created__c=TRUE LIMIT 1)                                    
                            FROM Opportunity 
                            WHERE AccountId=:account.id and CloseDate=:dt1 order by createddate desc LIMIT 1])
        {
            opp=op;
        }
        if(opp==NULL)
        {
            opp=new Opportunity(AccountId=account.id,Name=getOpportunityName(dt1),CloseDate = dt1,StageName='Need Posted');
        }
        if(opp.Non_Torc_payments__r.size()>0)
        {
             ErrorList.add('There are already some payments marked paid. Please contact torc support.');
             return true;
        }
        
        if([Select Id from Non_Torc_payment__c where Opportunity__c=:opp.id LIMIT 1].size()>0)
        {
            warningMessage = 'There are already payments created for this month. Nothing is marked paid yet. So this process will delete existing records.';
        }
        if(opp.OpportunityLineItems.size()==0)
        {
            id priceBookID = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            PricebookEntry pbe = [Select Id, IsActive,Product2Id, Product2.Name, Product2.ProductCode,Product2.Description, UnitPrice
                                from PricebookEntry
                                where Pricebook2Id=:priceBookID
                                AND Product2.Name='Transaction Fee'];
            Date dt = Date.newInstance(Opp.Closedate.year(),Opp.Closedate.Month(),1);
            oppLineItem=new opportunityLineItem(Engagement_Start_Date__c=dt,
                                                Quantity=1,
                                                Product2Id = pbe.Product2Id,priceBookEntryID= pbe.id,
                                                Product_Type__c = 'Transaction Fee',
                                                Hours_Week__c=1,
                                                Engagement_End_Date__c = dt.adddays(7),
                                                Engagement_Duration_weeks__c=1,
                                                Time_Commitment__c = 'HALFTIME',
                                                Talent_Hourly_Pay_Rate__c=0
                                                );
                                        
        }   
        else
            oppLineItem = opp.OpportunityLineItems[0];
        return false;    
    }
    public void back()
    {
        ErrorList.clear();
        loadType='';
        showRowsType='All';
        fileName='';
        file=null;
    }
    public void updateContacts()
    {
        ErrorList.clear();
        List<Non_Torc_user__c> l=new List<Non_Torc_user__c>();
        for(googleAPI.rowCls r:lstContacts)
        {
            l.add(r.user);
        }
        if(l.size()>0)
            Upsert l;
        lstContacts.clear(); 
        loadType='';   
    }
    public void updatePayments()
    {
        ErrorList.clear();
        If(opp.Id==NULL)
            upsert opp;
        if(oppLineItem.OpportunityId==NULL)    
            oppLineItem.OpportunityId = opp.id;
            
        decimal tf=0;
        for(List< Non_Torc_payment__c >l:[Select id from Non_Torc_payment__c where Opportunity__c=:opp.id])
            delete l;
        List< Non_Torc_payment__c >newList=new List< Non_Torc_payment__c >();    
        for(googleAPI.paymentCls r:lstPayments)
        {
            if(r.chk)
            {
                tf +=r.payRec.Torc_fee__c;
                newList.add(r.payRec);
            }    
        }
        oppLineItem.UnitPrice = tf;
        oppLineItem.Bank_fee__c = getTotalbankFee();
        oppLineItem.Customer_Hourly_Bill_Rate__c = tf;
        upsert oppLineItem;
        for(Non_Torc_payment__c a:newlist)
        {
            a.Opportunity_Product__c = oppLineItem.id;
            a.Opportunity__c = opp.id;
            a.Account__c = opp.AccountId;
            a.For_Month__c = oppLineItem.Engagement_Start_Date__c;
        }
        insert newList;
        lstPayments.clear();
        loadType='';
    }
    public decimal getTotalbankFee()
    {
        Decimal paypalAmount = 0;
        Decimal amt=0;
        for(googleAPI.paymentCls r:lstPayments)
        {
            if(r.chk)
            {
                amt +=r.payRec.Bank_fee__c;
                if(r.isPaypal)
                {
                    paypalAmount += r.total;
                }    
            }    
        }
        if(paypalAmount >=1000)
            amt +=20;
        else
            amt +=(paypalAmount*0.02);    
        return amt;
    }
    
    public decimal getTotalTorcFee()
    {
        Decimal amt=0;
        for(googleAPI.paymentCls r:lstPayments)
        {
            if(r.chk)
                amt +=r.payRec.Torc_fee__c;
        }
        return amt;
    }
    public decimal getTotalEmployeePayment()
    {
        Decimal amt=0;
        for(googleAPI.paymentCls r:lstPayments)
        {
            if(r.chk)
                amt +=r.payRec.Total_Amount__c;
        }
        return amt;
    }
    public void dummyCall(){}
    public string showRowsType{get;set;}
    public List<SelectOption> getShowTypes()
    {
        List<SelectOption> ifPicklist = new List<SelectOption> ();
        ifPicklist.add(new SelectOption('All','All'));
        ifPicklist.add(new SelectOption('Error','Error'));
        ifPicklist.add(new SelectOption('Non-Error','Non-Error'));
        return ifPickList;
    }
    
    public string selectedDate{get;set;}
    public List<SelectOption> getDates()
    {
        List<SelectOption> ifPicklist = new List<SelectOption> ();
        Datetime dt = Datetime.newInstance(date.Today().year(),date.Today().Month(),5);
        ifPicklist.add(new SelectOption(dt.month()+'-'+dt.year(),dt.format('MMMM-yyyy')));
        dt = Datetime.newInstance(datetime.now().year(),datetime.now().month()-1,5);
        ifPicklist.add(new SelectOption(dt.month()+'-'+dt.year(),dt.format('MMMM-yyyy')));
        return ifPickList;
    }
    public List<googleAPI.paymentCls> getshowableRows()
    {
        List<googleAPI.paymentCls> l=new List<googleAPI.paymentCls>();
        for(googleAPI.paymentCls dr:lstPayments)
        {
            if(showRowsType=='All' 
                || (showRowsType=='Error' && dr.getIsError()) 
                || (showRowsType=='Non-Error' && dr.getIsError()==FALSE))
            {
                l.add(dr);
            } 
        }
        return l;
    } 
    
    
    
    
    
    
//------------------------------------------------------------------------------------------------------------------------------------    
    public Blob file {get; set;}
    public String fileName {get; set;}
    public void loadpaymemntData() 
    {
        ErrorList.clear();
        loadType='PAYMENT';
        showRowsType='All';

        if(loadOpportunityAndLineItem())
        {
            return;
        }
        if(loadDataData('PAYMENT'))
        {
            loadType='';
            return;
        }
        map<string,googleAPI.paymentCls> emails=new map<string,googleAPI.paymentCls>();
        for(googleAPI.paymentCls r:lstPayments)
        {
            emails.put(r.OfficialEmail.toLowerCase().trim(),r);
        }
        for(Non_Torc_user__c ntr:[Select Id, Name, Monthly_USD_Expense__c, Default_Monthly_Rate__c, Official_Email__c, 
                                        Given_Name__c ,Family_Name__c, 
                                        Trolley_recipient__r.Estimated_fee__c,Trolley_Status__c,Docusign_Status__c, Trolley_recipient__r.Payout_Method__c
                                        FROM Non_Torc_user__c where Official_Email__c in:emails.keyset() AND account__c =: account.id])
        {
            emails.get(ntr.Official_Email__c.toLowercase()).setUser(ntr);
        }
        for(googleAPI.paymentCls r:lstPayments)
        {
            r.editData(opp,oppLineItem);
        }               
    }
    public void loadcontactData() 
    {
        ErrorList.clear();
        loadType='CONTACT';
        if(loadDataData('CONTACT'))
        {
            loadType='';
            return;    
        }
        map<string,googleAPI.rowCls> emails=new map<string,googleAPI.rowCls>();
        for(googleAPI.rowCls r:lstContacts)
        {
            emails.put(r.OfficialEmail.toLowerCase().trim(),r);
        }
        for(Non_Torc_user__c ntr:[Select Id, Name,  Payment_Start_Date__c, Given_Name__c, Family_Name__c, Email__c, Monthly_USD_Expense__c, 
                                        Account__c, Default_Monthly_Rate__c, 
                                        First_Month__c, Engagement_Months__c, 
                                        Contact__c, Official_Email__c, 
                                        Termination_Date__c, Country__c, Position__c 
                                        FROM Non_Torc_user__c where Official_Email__c in:emails.keyset()])
        {
            emails.get(ntr.Official_Email__c.toLowercase()).user = ntr;
        }
        for(googleAPI.rowCls r:lstContacts)
        {
            if(r.user==NULL)
            {
               r.user=new  Non_Torc_user__c(Account__c = account.id);
            }
            r.editData();
        }           
    }
    public boolean loadDataData(string type) 
    {
        ErrorList.clear();
        if(type=='PAYMENT')
            lstPayments.clear();
        if(type=='CONTACT')
            lstContacts.clear(); 
        if(fileName=='' || fileName==null)
        {
            ErrorList.add('Please click on browse button and select a valid csv file.');
            return true;
        }   
        String fileContent;    
        String[] lines;
        system.debug(file);
        try
        {
            fileContent = file.toString();
            lines = parseCsvLines(fileContent);
        }
        catch(Exception ex)
        {
            ErrorList.add('Looks Like you selecte a wrong file. This file is not a CSV...'+ex.getMessage());
            return true;
        }
        system.debug(fileContent);
        List<Map<String, String>> records = new List<Map<String, String>>();
        String[] headers = parseCsvLine(lines[0]);
        system.debug(headers);
        string missed = googleAPI.missingHeaders(headers,type);
        system.debug(missed);
        if(missed!='')
        {
            ErrorList.add('Few Important Fields are missing :' +missed);
            return true;
        }
        system.debug(lines.size());
        for (Integer i = 1; i < lines.size(); i++) 
        {
            String[] values = parseCsvLine(lines[i]);
            system.debug(values);
            if(type=='PAYMENT')
            {
                googleAPI.paymentCls row = new googleAPI.paymentCls();
                googleAPI.getPaymentRow(row,values,headers);
                lstPayments.add(row);
            }
            if(type=='CONTACT')
            {
                googleAPI.rowCls row = new googleAPI.rowCls();
                googleAPI.getContactRow(row,values,headers);
                lstContacts.add(row);
            }
        }
        system.debug(lstPayments);
        system.debug(lstContacts);
        return false;
    }
    private List<String> parseCsvLines(String csvContent) 
    {
        return csvContent.split('\n');
    }
    
    private String[] parseCsvLine(String line) 
    {
        List<String> values = new List<String>();
        String value = '';
        Boolean inQuotes = false;
        
        for (Integer i = 0; i < line.length(); i++) 
        {
            String c = line.substring(i, i + 1);
            if (c == '\"') 
            {
                inQuotes = !inQuotes; // Toggle the inQuotes flag
            } 
            else if (c == ',' && !inQuotes) 
            {
                values.add(value);
                value = '';
            } 
            else 
            {
                value += c;
            }
        }
        values.add(value); // Add the last value
        
        return values;
    }
    //--------------- Portal Implementation--------------------------------
    public string emailAddress{get;set;}
    public string usertype{get;set;}
    public string screen{get;set;}
    public string LoggedInUserName{get;set;}
    public string verificationID{get;set;}
    public boolean enteredinvalidCode{get;set;}
    private Qubika_Employee__c qEmployee{get;set;}
    
    public void backToLogin()
    {
        ErrorList.clear();
        screen='LOGIN';
    }
    public void VerifyEmailAddress()
    {
        ErrorList.clear();
        if(emailAddress==null || emailAddress.trim()=='')
        {
            ErrorList.add('Please provide your email address.');
            return;
        }
        
        List< Qubika_Employee__c> lst=[Select ID, Name, Email__c,Profile__c from Qubika_Employee__c where email__c=:emailAddress AND Account__c=:account.id];
        if(lst.size()>0)
        {
            qEmployee = lst[0];
            SendToverify();
        }
        else
        {
            ErrorList.add('You Are Not Authorised. Please contact Torc Support');
        }
    }
    public void SendToverify()
    {
        ErrorList.clear();
        enteredinvalidCode = false;
        verificationID='';
        verificationID = String.valueOf(Integer.valueOf(Math.random()*10));
        verificationID += String.valueOf(Integer.valueOf(Math.random()*10));
        verificationID += String.valueOf(Integer.valueOf(Math.random()*10));
        verificationID += String.valueOf(Integer.valueOf(Math.random()*10));
        qEmployee.Verification_Code__c = verificationID;
        Qubika_Verification__c tsv=new Qubika_Verification__c(Code__c=verificationID,Email__c = qEmployee.Email__c,User_Name__c = qEmployee.Name);
        insert tsv;        
        screen = 'VERIFY';
        verifycode1 = verifycode2 = verifycode3 =verifycode4 ='';
    }
    public string verifycode1{get;set;}
    public string verifycode2{get;set;}
    public string verifycode3{get;set;}
    public string verifycode4{get;set;}
    public void verifyCode()
    {
        ErrorList.clear();
        string verif = verifycode1+verifycode2+verifycode3+verifycode4;
        if(verif == qEmployee.Verification_Code__c)
        {   
            usertype = qEmployee.Profile__c;
            LoggedInUserName = qEmployee.Name; 
            screen = 'DATA';
        }
        else
        {
            ErrorList.add('You entered a wrong code. Please click on "resend new code" or change login email address.');
            enteredinvalidCode = true;
        }    
    }
}