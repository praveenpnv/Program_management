trigger CaseTrigger on Case (before Insert,before update,after insert, after update) 
{
    system.debug('in case Trigger--------' + trigger.isInsert+'---'+trigger.isAfter);
    for(Case c:trigger.new)
    {
        system.debug(c);
        if(trigger.isBefore && trigger.isInsert)
        {
            if(c.Origin=='Codealike')
            {
                if(c.SuppliedEmail=='request@codealike.com' && c.description!=null)
                {
                    List<string>spl = c.description.split('----------------');
                    if(spl.size()>1 && spl[0].length()<80 && spl[0].split('@').size()==2)
                        c.Codealike_Help_Requester__c = spl[0];
                }
                if(c.Description!=NULL)
                {
                    c.Description = c.Description.replace('You received this message because you are subscribed to the Google Groups "Codealike Support" group.','');
                    c.Description = c.Description.replace('To unsubscribe from this group and stop receiving emails from it, send an email to support+unsubscribe@codealike.com.','');
                }
            }
        }
    }

}