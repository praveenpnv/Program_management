trigger nonTorcpaymentTrigger on Non_Torc_Payment__c (before insert, before Update) 
{
    for(Non_Torc_Payment__c rec:trigger.new)
    {
        rec.Name = rec.Friendly_Name__c.left(80);
    }

}