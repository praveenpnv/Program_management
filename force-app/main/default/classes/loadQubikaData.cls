Public class loadQubikaData
{
    
    Public List<googleAPI.rowCls> lstData{get;set;}
    Public string spreadsheetId{get;set;}
    Public string sheetName{get;set;}
    Public string sheetRange{get;set;}
    Public Account act{get;set;}
    public loadQubikaData(ApexPages.StandardController controller)
    {
        act=(Account) controller.getRecord();
        spreadsheetId = '1TyrA8PGFB4cANIZBFVd39qMIpEbvrg64cYIZQF_EZ-Q';
        sheetName = 'Sheet1';
        sheetRange = 'A1:J';
        lstData = new List<googleAPI.rowCls>();
    }
    public void loaddata()
    {
        lstData.clear();
        string error = googleAPI.GetQubikaDataFromSpreadsheet(spreadsheetId,sheetName,sheetRange,lstData);
        if(error!='' && error!=null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,error));
            return;
        }
        map<string,googleAPI.rowCls> emails=new map<string,googleAPI.rowCls>();
        for(googleAPI.rowCls r:lstData)
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
        for(googleAPI.rowCls r:lstData)
        {
            if(r.user==NULL)
            {
               r.user=new  Non_Torc_user__c(Account__c = act.id);
            }
            r.editData();
        }                                        
        
    }
    public void updateData()
    {
        List<Non_Torc_user__c> l=new List<Non_Torc_user__c>();
        for(googleAPI.rowCls r:lstData)
        {
            if(r.chk)
                l.add(r.user);
        }
        if(l.size()>0)
            Upsert l;
    }
}