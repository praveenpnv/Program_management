trigger PlacementReferralTrigger on Placement__c (after update, before Delete) 
{
    set<id> userSet=new set<id>();
    for(Placement__c rec: (trigger.isDelete?trigger.old:trigger.new))
    {
        if(trigger.isDelete ||(
            trigger.isUpdate && 
            (rec.First_Working_Day__c!=trigger.oldMap.get(rec.id).First_Working_Day__c 
                || rec.Last_Working_Day__c!=trigger.oldMap.get(rec.id).Last_Working_Day__c 
                || rec.Total_To_Pay__c!=trigger.oldMap.get(rec.id).Total_To_Pay__c 
                || rec.Exclude__c!=trigger.oldMap.get(rec.id).Exclude__c)))
        {
            userSet.add(rec.torc_User__c);
        }        
    }
    if(userSet.size()>0)
        ReferralBonus.setupreferralBonus(userSet);

}