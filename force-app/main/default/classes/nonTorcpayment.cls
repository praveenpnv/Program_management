Public class nonTorcpayment
{
    public opportunity opp{get;set;}
    public opportunityLineItem oppLineItem{get;set;}
    Public List<googleAPI.paymentCls> lstData{get;set;}
    Public string spreadsheetId{get;set;}
    Public string sheetName{get;set;}
    Public string sheetRange{get;set;}
    Public Account act{get;set;}
    public boolean isError{get;set;}
    public string warningMessage{get;set;}
    public decimal getTotalbankFee()
    {
        Decimal paypalAmount = 0;
        Decimal amt=0;
        for(googleAPI.paymentCls r:lstData)
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
        for(googleAPI.paymentCls r:lstData)
        {
            if(r.chk)
                amt +=r.payRec.Torc_fee__c;
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
    public List<googleAPI.paymentCls> getshowableRows()
    {
        List<googleAPI.paymentCls> l=new List<googleAPI.paymentCls>();
        for(googleAPI.paymentCls dr:lstData)
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
    public nonTorcpayment(ApexPages.StandardController controller)
    {
        showRowsType='All';
        warningMessage='';
        isError=false;
        opp = (Opportunity)controller.getRecord();
        opp = [Select Id, Name, Closedate,StageName, AccountId,Account.Name,
                (Select ID ,Engagement_Start_Date__c, Customer_Hourly_Bill_Rate__c ,Unitprice,TotalPrice
                                    FROM OpportunityLineItems where Product2.name='Transaction Fee'),
                (Select ID from Non_Torc_payments__r where Payment_Created__c=TRUE LIMIT 1)                                    
               FROM Opportunity Where id=:opp.id];
        act = opp.Account;
        spreadsheetId = '1wPEmQR-YjIeh2Jqkj4Nx7rsWO2qn8ASSFg9Ri6SDNAI';
        sheetName = 'Sheet2';
        sheetRange = 'A1:D';
        lstData = new List<googleAPI.paymentCls>();       
        /*if(opp.OpportunityLineItems.size()!=1)
        {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:There should be one and only one lineitem with product "Transaction fee" on this opportunity.'));
             isError = true;
             return;
        }*/
        if(opp.Non_Torc_payments__r.size()>0)
        {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Error:There are already some payments marked paid. Please create a new opportunity now.'));
             isError = true;
             return;
        }
        if([Select Id from Non_Torc_payment__c where Opportunity__c=:opp.id LIMIT 1].size()>0)
        {
            warningMessage = 'There are already payments created for this month. Nothing is marked paid yet. So this process will delete existing records.';
        }
        if(opp.OpportunityLineItems.size()==0)
        {
            id priceBookID = [Select ID from priceBook2 where Name='Standard Price Book'].Id;
            PricebookEntry pbe = [Select Id, IsActive,Product2Id, Product2.Name, Product2.ProductCode,Product2.Description, UnitPrice
                                from PricebookEntry
                                where Pricebook2Id=:priceBookID
                                AND Product2.Name='Transaction Fee'];
            Date dt = Date.newInstance(Opp.Closedate.year(),Opp.Closedate.Month(),1);
            oppLineItem=new opportunityLineItem(OpportunityId=opp.id,
                                                Engagement_Start_Date__c=dt,
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
    }
    public void loaddata()
    {
        lstData.clear();
        string error = googleAPI.GetQubikaPaymentFromSpreadsheet(spreadsheetId,sheetName,sheetRange,lstData);
        if(error!='' && error!=null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,error));
            return;
        }
        map<string,googleAPI.paymentCls> emails=new map<string,googleAPI.paymentCls>();
        for(googleAPI.paymentCls r:lstData)
        {
            emails.put(r.OfficialEmail.toLowerCase().trim(),r);
        }
        for(Non_Torc_user__c ntr:[Select Id, Name, Monthly_USD_Expense__c, Default_Monthly_Rate__c, Official_Email__c, 
                                        Trolley_recipient__r.Estimated_fee__c,Trolley_Status__c,Docusign_Status__c, Trolley_recipient__r.Payout_Method__c
                                        FROM Non_Torc_user__c where Official_Email__c in:emails.keyset() AND account__c =: opp.AccountId])
        {
            emails.get(ntr.Official_Email__c.toLowercase()).setUser(ntr);
        }
        for(googleAPI.paymentCls r:lstData)
        {
            r.editData(opp,oppLineItem);
        }                                        
    }
    public Pagereference updateData()
    {
        decimal tf=0;
        for(List< Non_Torc_payment__c >l:[Select id from Non_Torc_payment__c where Opportunity__c=:opp.id])
            delete l;
        List< Non_Torc_payment__c >newList=new List< Non_Torc_payment__c >();    
        for(googleAPI.paymentCls r:lstData)
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
        return new Pagereference('/'+opp.id);
    }
}