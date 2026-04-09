trigger nonTorcAfter on Non_Torc_User__c (after insert) 
{
    if(Torc_Constants__c.getInstance().Auto_Create_Qubika_Process__c==TRUE)
    {
        List<QB_API_Call__c> lst=new List<QB_API_Call__c>();
        for(Non_Torc_user__c tu:trigger.new)
        {
            QBAccountingService.QBVendor rec= QBNonTorcSetup.getQBVendorFromUser(tu);
            QB_API_Call__c qb = new  QB_API_Call__c(Name='NonTorc-VendorQB',Input__c = JSON.serialize(rec),Non_Torc_User__c = tu.id);
            lst.add(qb);
            
            TrolleyService.T_recipient rec1 = QBNonTorcSetup.getTrolleyVendorFromUser(tu);
            qb = new  QB_API_Call__c(Name='NonTorc-VendorTrolley',Input__c = JSON.serialize(rec1),Non_Torc_User__c = tu.id);
            lst.add(qb);
        }
        if(lst.size()>0)
        {
            QBOpportunitySetup.CallQBAPI(lst);
        }
    }
}