Public class googleAPI
{
    public class paymentCls
    {
        public paymentCls()
        {
            error='';
            user=null;
            trollyR = null;
            isPaypal = chk=false;
        }
        public void setUser(Non_Torc_user__c tu)
        {
            user = tu;
            trollyR = tu.Trolley_Recipient__r;
        }
        public void editData(Opportunity opp, opportunityLineItem ol)
        {
            date dt = Date.newInstance(ol.Engagement_Start_Date__c.year(),ol.Engagement_Start_Date__c.Month()+1,1)-1;
            payRec = new Non_Torc_payment__c(Opportunity__c =opp.id,Account__c=opp.AccountId, Opportunity_Product__c=ol.id, For_Month__c =dt);
            if(user==NULL)
                error = 'Invalid User';
            else 
            {
                payRec.Non_Torc_User__c = user.id;
                if(user.Trolley_Status__c !='active' || user.Docusign_Status__c!='Completed')
                {
                   error = 'Profile Incomplete';
                }
                else    
                {
                    chk=true;    
                    
                    payRec.Monthly_Expense__c =  Expense;                     
                    payRec.Monthly_Amount__c =Fee;
                    payRec.Total_Amount__c = Total==NULL?0:Total;//(payRec.Monthly_Expense__c==NULL?0:payRec.Monthly_Expense__c)+(payRec.Monthly_Amount__c==NULL?0:payRec.Monthly_Amount__c);
                    payRec.Torc_Fee__c = payRec.Total_Amount__c * 0.07;
                    payRec.Bank_fee__c = trollyR.Estimated_fee__c;
                    isPaypal = trollyR.Payout_Method__c=='paypal';
                } 
            }   
        }
        public boolean getIsError()
        {
            return error!=NULL && error !='';
        }
        
        public string error{get;set;}
        public boolean chk{get;set;}
        public boolean isPaypal{get;set;}
        public string OfficialEmail{get;set;}
        public Decimal Fee{get;set;}
        public Decimal Expense{get;set;}
        public Decimal Total{get;set;}
        Public Non_Torc_user__c user{get;set;}  
        Public Non_Torc_payment__c payRec{get;set;}        
        public Trolley_recipient__c trollyR{get;set;}
        public string getQubikaUserName(){return user==NULL?'': user.Name;}
        public string getTrolleyStatus(){return user==NULL?'':user.Trolley_Status__c;}
        public string getDocusignStatus(){return user==NULL?'':user.Docusign_Status__c;}
        
        public Decimal getBankFee(){return payRec==NULL?NULL:payRec.Bank_Fee__c;}
        public Decimal getTorcFee(){return payRec==NULL?NULL:payRec.Torc_Fee__c;}
        
        
        public string getTrolleyPayoutMethod(){return user==NULL?'': user.Trolley_recipient__r.Payout_Method__c;}
        
        
        
    }


    public class responseCls
    {
        Public List<object> lst=null;
        public string error='';
    }
    public class rowCls
    {
        public rowCls()
        {
            user=NULL;
            chk = true;
        }
        public void editData()
        {
            user.Name = Name;   
            user.Given_Name__c = Name.split(' ')[0]; 
            user.Family_Name__c = Name.substringAfter(' ');   
            user.Email__c = Email;
            user.Official_Email__c=OfficialEmail;
            user.Payment_Start_Date__c =  Payment_Start_Date;                     
            user.Monthly_USD_Expense__c =  Monthly_Expense;                     
            user.Default_Monthly_Rate__c =USD_Monthly;
            user.First_Month__c = Start_Date ;
            user.Engagement_Months__c=12;
            user.Termination_Date__c=terminate; 
            user.Country__c = Country;
            user.Position__c = Role;
        }
        public boolean chk{get;set;}
        public string Name{get;set;}
        public string Email{get;set;}
        public string OfficialEmail{get;set;}
        public Date Start_Date{get;set;}
        public Date Payment_Start_Date{get;set;}
        public string Role{get;set;}
        public string Country{get;set;}
        public Decimal USD_Monthly{get;set;}
        public Decimal Monthly_Expense{get;set;}
        public Date terminate{get;set;}
        Public Non_Torc_user__c user{get;set;}
        
        public Decimal getMonthlyUSD(){return user==NULL?NULL:user.Default_Monthly_Rate__c;}
        public Decimal getMonthlyExpense(){return user==NULL?NULL:user.Monthly_USD_Expense__c;}
        
    }
    public static Date getDate(object ob)
    {
        if(ob==NULL)
            return null;
        List<String> s= ((string)ob).split('/');
        if(s.size()!=3)
            return null;
        return Date.NewInstance (Integer.valueOf(s[2]),Integer.valueOf(s[0]),Integer.valueOf(s[1]));
    }
    public static Decimal getDecimal(object ob)
    {
        if(ob==NULL)
            return null;
        string s=(string)ob;
        s=s.trim();
        if(s=='')
            return null;
        s=s.replace('$','').replace(',','');
        return Decimal.valueOf(s);
    }
    public static string missingHeaders(List<object> headers, string type)
    {
        Map<string,Boolean> myMap=new Map<string,Boolean>();
        if(type=='PAYMENT')
        {
            myMap.put('qubika email',FALSE);
            myMap.put('total amount',FALSE);
        }
        if(type=='CONTACT')
        {
            myMap.put('name',FALSE);
            myMap.put('email',FALSE);
            myMap.put('qubika email',FALSE);
            myMap.put('start date',FALSE);
            myMap.put('role',FALSE);
            myMap.put('usd monthly',FALSE);
            myMap.put('monthly expense',FALSE);
            myMap.put('role',FALSE);   
        }
        for(object s:headers)
        {
            string s1=(string)s;
            s1=s1.trim().toLowercase();
            if(myMap.get(s1)!=NULL)
                myMap.put(s1,TRUE);
        }
        system.debug(myMap);
        string res='';
        for(string s:myMap.keyset())
            if(myMap.get(s)==FALSE)
                res= res + (res==''?'':' ,')+s;
        return res;        
    }
    public static void getPaymentRow(paymentCls row,List<object> vals,List<object> headers)
    {
        for(integer j=0;j<vals.size();j++)
        {
            string hdr = ((string)headers[j]).Trim();
            system.debug(hdr);
            system.debug(vals[j]);
            if(hdr == 'Qubika Email')
            {
                row.OfficialEmail = (string)vals[j];
            }
            if(hdr == 'Fee')
            {
                row.Fee = getDecimal(vals[j]);
            }
            if(hdr == 'Expense')
            {
                row.Expense = getDecimal(vals[j]);
            }
            if(hdr == 'Total Amount')
            {
                row.Total = getDecimal(vals[j]);
            }
        }
    }
    public static void getContactRow(rowCls row,List<object> vals,List<object> headers)
    {
        for(integer j=0;j<vals.size();j++)
            {
                string hdr = ((string)headers[j]).Trim();
                
                system.debug(hdr);
                system.debug(vals[j]);
                
                
                if(hdr == 'Name')
                {
                    row.Name = (string)vals[j];
                }
                if(hdr == 'Email')
                {
                    row.Email = (string)vals[j];
                }
                if(hdr == 'Qubika Email')
                {
                    row.OfficialEmail = (string)vals[j];
                }
                if(hdr == 'Start Date')
                {
                    row.Start_Date = getDate(vals[j]);
                }
                if(hdr == 'Role')
                {
                    row.Role = (string)vals[j];
                }
                if(hdr == 'Country')
                {
                    row.Country = (string)vals[j];
                }
                if(hdr == 'USD Monthly')
                {
                    row.USD_Monthly = getDecimal(vals[j]);
                }
                if(hdr == 'Monthly Expense')
                {
                    row.Monthly_Expense = getDecimal(vals[j]);
                }
                if(hdr == 'Terminated  (Last day/Month)')
                {
                    row.terminate = getDate(vals[j]);
                }
                if(hdr == 'Payment Start Date')
                {
                    row.Payment_Start_Date = getDate(vals[j]);
                }
            }
            system.debug(row);
    }
    public static string GetQubikaPaymentFromSpreadsheet(string spreadsheetid,string sheetName,string sheetRange,List<paymentCls> lstRes)
    {
        lstRes.clear();
        responseCls resp = readSpreadsheetAsjson(spreadsheetid,sheetName,sheetRange);
        if(resp.lst==NULL)
            return resp.error;
        List<object> headers = (List<object>)resp.lst[0];
           
        for(integer i=1;i<resp.lst.size();i++)
        {
            List<object> vals = (List<object>)resp.lst[i]; 
            paymentCls row = new paymentCls();
            getPaymentRow(row,vals,headers);
            lstRes.add(row);
        } 
        return resp.error;    
    }
    public static string GetQubikaDataFromSpreadsheet(string spreadsheetid,string sheetName,string sheetRange,List<rowCls> lstRes)
    {
        lstRes.clear();
        responseCls resp = readSpreadsheetAsjson(spreadsheetid,sheetName,sheetRange);
        if(resp.lst==NULL)
            return resp.error;
        List<object> headers = (List<object>)resp.lst[0];
        System.debug('Headers: ' + headers);
        
        for(integer i=1;i<resp.lst.size();i++)
        {
            List<object> vals = (List<object>)resp.lst[i]; 
            rowCls row = new rowCls();
            getContactRow(row,vals,headers);
            system.debug(row);
            lstRes.add(row);
        } 
        return resp.error;   
            
    }
    public static responseCls readSpreadsheetAsjson(string spreadsheetid,string sheetName,string sheetRange)
    {
        string apiKey = Torc_Constants__c.getInstance().Google_key__c;
        String url = 'https://sheets.googleapis.com/v4/spreadsheets/'+spreadsheetid+'/values/'+sheetName+'!'+sheetRange+'?key='+apiKey;        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        HttpResponse response;
        if(test.isRunningTest())
        {
            response = new HttpResponse();
            response.setStatusCode(200);
            string b;
            if(GoogleAPITest.qooglLoadType=='USER')
                b='{"values": [["Name","Qubika Email","Start Date","Role","Country","USD Monthly","Monthly Expense","Terminated  (Last day/Month)"], ["Facundo Verdugo","devdevdev@dev.dev","11/1/2023","Mobile developer","Argentina","$2,800.00","$120.00","12/20/2023"]]}';
            ELSE if(GoogleAPITest.qooglLoadType=='PAYMENT')
                b='{"values": [["Qubika Email","Fee","Expense","Total Amount"], ["devdevdev@dev.dev","$2,800.00","$120.00","3000"]]}';                
            response.setBody(b);
        }
        else 
            response = http.send(request);
        responseCls resp=new responseCls();
        if (response.getStatusCode() == 200) 
        {
            system.debug(response.getBody());
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            resp.lst = (List<object>)responseData.get('values');
        } 
        else 
        {
            resp.error = 'Error from Google Sheets API: ' + response.getBody();
        }
        return resp;
    }
}