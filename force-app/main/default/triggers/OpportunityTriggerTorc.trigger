trigger OpportunityTriggerTorc on Opportunity (before insert, before update, after insert, after update) 
{
    if(Torc_Constants__c.getInstance().Disable_Opportunity_Trigger__c) return;
    set<id> oppForSuperVisorCheck=new Set<Id>();
    List<Account> lstAct=new List<Account>();
    for(Opportunity rec:Trigger.New)
    {
        if(trigger.isInsert && trigger.isBefore)
            rec.Torc_External_Id__c = null;
        if(rec.Torc_Opportunity__c)
        {
            if(trigger.isBefore && rec.Stagename=='New')
                rec.Stagename = 'Need Identified';
            if(trigger.isUpdate && trigger.isBefore && rec.Isclosed && trigger.oldmap.get(rec.id).Isclosed==FALSE)
                rec.CloseDate=date.today();
            if(trigger.isBefore && trigger.isInsert)
            {
                rec.Invoices_Created__c = false;
                rec.Bills_Created__c = false;
            }
            if(trigger.isbefore)
            {
                if(rec.Amount<0 && rec.isClosed)
                    rec.Possible_to_Extend__c = false;
                rec.DBD__C = rec.Debooking_Description__c==NULL?NULL:rec.Debooking_Description__c.left(255);
                rec.Master_Opportunity__c = rec.Parent_s_main_Opportunity_Id__c ==NULL?rec.Parent_Opportunity__c:rec.Parent_s_main_Opportunity_Id__c;
                rec.talent_User_Name__c = rec.Current_talent_user_Name_Formula__c;
                 if(rec.Job_Opportunity__c!=NULL && (Trigger.isInsert || rec.Job_Opportunity__c!=Trigger.oldmap.get(rec.Id).Job_Opportunity__c || rec.Job_Talent_Owner_ID__c!=Trigger.oldmap.get(rec.Id).Job_Talent_Owner_ID__c))
                {
                    rec.Talent_Owner__c = rec.Job_Talent_Owner_ID__c;
                }
            }    
            if(Trigger.isBefore && rec.isClosed==FALSE)
            {
                rec.PO_Required__c = (rec.PO_Required__c==NULL && rec.Account_PO_Required__C!=NULL)?rec.Account_PO_Required__C:rec.PO_Required__c;            
            }
            else if(trigger.isUpdate && trigger.isBefore && rec.isWon && trigger.oldMap.get(rec.Id).IsWon==FALSE && rec.Amount>0)
            {
                oppForSuperVisorCheck.add(rec.id);
                lstAct.add(new Account(Id=rec.AccountId,Type='Customer'));
            }
        }    
    }
    if(lstAct.size()>0)
        update lstAct;

}