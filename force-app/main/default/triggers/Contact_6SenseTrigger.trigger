trigger Contact_6SenseTrigger on Contact (before insert, before update) 
{
    map<string,id> mapemail=new map<string,id>();
    for(Contact l:trigger.new)
    {
        if(l.X6sense_Created_By__c!=NULL && l.X6sense_Created_By__c!='')
            if(trigger.isInsert || (l.X6sense_Created_By__c!=trigger.oldmap.get(l.id).X6sense_Created_By__c))
                mapemail.put(l.X6sense_Created_By__c.toLowercase(),null);
    }
    system.debug(mapemail);
    if(mapemail.keyset().size()>0)
    {
        for(user u:[Select id,email from user where email in:mapemail.keyset()  AND Isactive=True])
            mapemail.put(u.email.tolowercase(),u.id);
        system.debug(mapemail);    
        for(Contact l:trigger.new)
        {
            if(l.X6sense_Created_By__c!=NULL && l.X6sense_Created_By__c!='')
                if(trigger.isInsert || (l.X6sense_Created_By__c!=trigger.oldmap.get(l.id).X6sense_Created_By__c))
                    if(mapemail.get(l.X6sense_Created_By__c.toLowercase())!=NULL)
                    {
                        system.debug(l);
                        l.OwnerId=mapemail.get(l.X6sense_Created_By__c.toLowercase());
                    }
        }    
            
    }
}