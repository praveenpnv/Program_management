trigger TorcApplicationtrigger on Torc_Application__c (before insert, before update) 
{
    for(Torc_Application__c rec:trigger.new)
        rec.name=rec.Friendly_Name__c;

}