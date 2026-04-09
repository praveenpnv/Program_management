trigger trolleyrecipientAfterTrigger on Trolley_Recipient__c (after insert,after update) 
{
    List<non_Torc_user__c> l=new List<non_Torc_user__c>();
    for(Trolley_Recipient__c rec:trigger.new)
    {
        if(rec.non_Torc_user__c!= null && (trigger.isInsert || rec.non_Torc_user__c!=trigger.oldMap.get(rec.id).non_Torc_user__c))
        {
               l.add(new non_Torc_user__c(id= rec.non_Torc_user__c, Trolley_Recipient__c = rec.id));
        }
    }
    if(l.size()>0)
        update l;
}