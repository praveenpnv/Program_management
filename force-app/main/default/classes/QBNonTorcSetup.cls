Public class QBNonTorcSetup
{
    public class ntcClass
    {
        public Non_Torc_User__c usr{get;set;}
        public Trolley_Recipient__c tRec{get;set;}
        public ntcClass(Non_Torc_User__c u)
        {
            usr = u;
            tRec = null;
        }
    }
    public integer masterCRMIDFieldNumber{get;set;}
    Public Account act{get;set;}
    Public List<ntcClass> nontorcuserList{get;set;}
    public string fnSearch{get;set;}
    public string lnSearch{get;set;}  
    public string QBvendoridToUpdate{get;set;}    
    public string TorcmemberidToUpdate{get;set;} 
    Public String searchText{get;set;}
    Public Boolean SearchDone{get;set;}
    public List<QBAccountingService.QBVendor> vendors{get;set;}
    public QBContstantsSetup ContstantsSetup{get;set;}
    Public Map<id, Trolley_Recipient__c > ntcTrollyMap{get;set;}
    Public QBNonTorcSetup(ApexPages.StandardController controller)
    {
        showRowsType = 'All';
        vendors = new List<QBAccountingService.QBVendor>();
        ContstantsSetup = NEW QBContstantsSetup();
        act=(Account) controller.getRecord(); 
        act=[Select ID, Name from Account Where id=:act.id];
        resetup();
    }    
    public void resetup()
    {
        nontorcuserList = new List<ntcClass>();
        for(non_torc_user__c u:[Select ID, Official_Email__c,Email__c,External_Id__c, given_name__c, family_Name__c, Name, 
                                Quick_Books_vendor_Id__c, Quickbooks_Vendor__c , Trolley_Creation_Requested__c,
                                (Select Id,Full_Name__c,  Non_Torc_User__c, referenceId__c, external_Id__c 
                                        from   Trolley_Recipients__r)
                                from non_Torc_user__c 
                                where Account__c =:act.id
                                Order By Official_Email__c])
        {
            ntcClass n=new ntcClass(u);
            if(u.Trolley_Recipients__r.size()>0)
                n.tRec=u.Trolley_Recipients__r[0];
            nontorcuserList.add(n);   
        }                                 
    }
    public string createTrolleyId{get;set;}
    public void createTrolleyUser()
    {
        for(ntcClass ntu: nontorcUserList)
        {
            non_Torc_User__c tu=ntu.usr;
            if(tu.id==createTrolleyId)
            {
                TrolleyService.T_recipient tRec = getTrolleyVendorFromUser(tu);
                TrolleyService.createRecipient(tRec);
                tu.Trolley_Creation_Requested__c = true;
                update tu;
                resetup();
                return;
            }
        }
    }
    Public void SearchVendor()
    {
        try
        {
            QBvendoridToUpdate=null;
            SearchDone = false;    
            string query= 'SELECT * FROM Vendor Where DisplayName != \'_\' ';
            if(fnSearch!='' && fnSearch!=NULL)
                query += ' AND GivenName Like \'%'+fnSearch +'%\'';
            if(lnSearch!='' && lnSearch!=NULL)
                query += ' AND FamilyName Like \'%'+lnSearch +'%\'';    
                
            JSONParser jp = QBAccountingService.runQuery(query);
            vendors = new List<QBAccountingService.QBVendor>();
            QBAccountingService.QBResponseVendor res=(QBAccountingService.QBResponseVendor)jp.readValueAs(QBAccountingService.QBResponseVendor.class);
            if(res.QueryResponse!=NULL && res.QueryResponse.vendor!=NULL)
            {
                vendors = res.QueryResponse.vendor;
                if(vendors.size()>0)
                    SearchDone = true;    
            }    
        }
        catch(exception e)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));
        }
    }
    public void cleanupVandors()
    {
        vendors.clear();
        QBvendoridToUpdate = null;
        TorcmemberidToUpdate = null;
    }
    Public void CreateQBVendor()
    {
        if(TorcmemberidToUpdate==NULL || TorcmemberidToUpdate=='')
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select Member.'));
            return;
        }
        for(ntcClass ntu: nontorcUserList)
        {
            non_Torc_User__c tu=ntu.usr;
            if(tu.id==TorcmemberidToUpdate)
            {
                QBAccountingService.QBVendor qb = getQBVendorFromUser(tu);
                qb = QBAccountingService.createVendorinQb(qb);
                if(qb!=NULL)
                {
                    tu.Quick_Books_vendor_Id__c = qb.Id;
                    tu.Quickbooks_Vendor__c = qb.DisplayName;
                }
                update tu;
                cleanupVandors();
                resetup();
                return;
            }
        }
    }
    Public void MapMemberToExtsingQBVendor()
    {
        if(QBvendoridToUpdate==null || QBvendoridToUpdate=='' || TorcmemberidToUpdate==NULL || TorcmemberidToUpdate=='')
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please select vendor/Member to map.'));
            return;
        }
        for(ntcClass ntu: nontorcUserList)
        {
            non_Torc_User__c tu=ntu.usr;
            if(tu.id==TorcmemberidToUpdate)
            {
                system.debug(tu.id);
                for(QBAccountingService.QBVendor customer : vendors)
                {
                    system.debug(customer.id);
                    if(customer.Id==QBvendoridToUpdate)
                    {
                        system.debug(customer.DisplayName);
                        tu.Quick_Books_vendor_Id__c = customer.Id;
                        tu.Quickbooks_Vendor__c = customer.DisplayName;
                        update tu;
                        cleanupVandors();
                        resetup();
                        return;
                    }
                }
            }
        }
    }
    public void pageToken()
    {
        QB_Authentication authentication = new QB_Authentication();
        authentication.initializeToken();
        authentication.persistTokenInDb();
    }
    public string showRowsType{get;set;}
    public List<SelectOption> getShowTypes()
    {
        List<SelectOption> ifPicklist = new List<SelectOption> ();
        ifPicklist.add(new SelectOption('All','All'));
        ifPicklist.add(new SelectOption('WaitingQB','Waiting For QB Setup'));
        ifPicklist.add(new SelectOption('WaitingTrolley','Waiting For Trolley Setup'));
        ifPicklist.add(new SelectOption('Waiting','All Incomplete'));
        ifPicklist.add(new SelectOption('AlreadySetup','Setup Done'));
        return ifPickList;
    }
    public void dummyCall1()
    {
    }
    Public List<ntcClass> getfilterednontorcuserList()
    {
        List<ntcClass> lst = new List<ntcClass>();
        for(ntcClass rec: nontorcuserList)
        {
            if(showRowsType=='All' || 
                ((showRowsType=='WaitingQB' || showRowsType=='Waiting') && rec.usr.Quick_Books_vendor_Id__c==NULL) ||
                ((showRowsType=='WaitingTrolley' || showRowsType=='Waiting') && (rec.tRec==NULL && rec.usr.Trolley_Creation_Requested__c==FALSE))||
                ((showRowsType=='AlreadySetup') && rec.usr.Quick_Books_vendor_Id__c!=NULL && rec.tRec!=NULL))
            {
                lst.add(rec);
            }    
        }
        return lst;
    }
    public static QBAccountingService.QBVendor getQBVendorFromUser(Non_Torc_User__c tu)
    {
        QBAccountingService.QBVendor qb = new QBAccountingService.QBVendor();
        qb.PrimaryEmailAddr = new QBAccountingService.QBEmailAddress();
        qb.PrimaryEmailAddr.address = tu.Email__c;
        qb.CompanyName = 'Qubika Talent Member';
        qb.GivenName = tu.given_name__c;
        qb.FamilyName = tu.family_Name__c;
        //qb.DisplayName = tu.Official_Email__c;                
        qb.Active = true;
        qb.PrintOnCheckName = tu.name;
        qb.AcctNum = tu.External_Id__c;
        return qb;
    }
    public static TrolleyService.T_recipient getTrolleyVendorFromUser(Non_Torc_user__c tu)
    {
        TrolleyService.T_recipient tRec = new TrolleyService.T_recipient();
        tRec.referenceId = tu.External_Id__c;
        tRec.email = tu.Email__c;
        tRec.lastName = tu.Family_Name__c;
        tRec.firstName = tu.given_Name__c;
        tRec.type = 'individual';
        return tRec;
    }
}