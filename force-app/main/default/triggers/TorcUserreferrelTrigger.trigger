trigger TorcUserreferrelTrigger on Torc_User__c (after update) 
{
    set<id>useridDirect=new set<id>();
    set<id>useridIndirect=new set<id>();
    for(Torc_User__c tu:trigger.new)
    {
        if(tu.Referrer__c!=trigger.oldmap.get(tu.id).Referrer__c || tu.Exclude_Referral_Bonus__c !=trigger.oldmap.get(tu.id).Exclude_Referral_Bonus__c)
            useridDirect.add(tu.id);
        if(tu.Exclude_referrer_Bonus__c !=trigger.oldmap.get(tu.id).Exclude_referrer_Bonus__c)
            useridIndirect.add(tu.id);
    }
    if(useridIndirect.size()>0)
    {
        for(Torc_user__c tu:[select ID from Torc_user__c Where Referrer__c in:useridIndirect])
            useridDirect.add(tu.id);
    }
    if(useridDirect.size()>0)
        ReferralBonus.setupreferralBonus(useridDirect);

}