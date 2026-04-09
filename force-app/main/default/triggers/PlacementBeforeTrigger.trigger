trigger PlacementBeforeTrigger on Placement__c (before Insert, before Update) 
{
    for(Placement__c rec:trigger.new)
    {
        rec.Name = rec.Friendly_Name__c.left(80);
        rec.Account__c = rec.Account_Id__c;
        rec.Torc_User_Contact__c = rec.Torc_User_Contact_Id__c;
        rec.Churn_Notes__C = (rec.Churn_Notes__C==NULL || rec.Churn_Notes__C=='')?rec.DBD__c:rec.Churn_Notes__C;
        //rec.Latest_CSM__c = rec.CSM_ID__c;
        //rec.Latest_Talent_Specialist__c = rec.Talent_Specialist_ID__c;
        //rec.Latest_AE__c = rec.AE_ID__c;
    }

}