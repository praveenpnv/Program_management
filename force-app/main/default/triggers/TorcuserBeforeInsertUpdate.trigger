trigger TorcuserBeforeInsertUpdate on Torc_User__c (before insert, before update) 
{
    set<string> setrCodes = new set<string>();
    set<string> setCountry = new set<string>();
    for(Torc_User__c rec:Trigger.New)
    {
        if(rec.referrerCode__c =='' || rec.referrerCode__c==null)
        {
            rec.Referrer__c = null;
        }
        else if(trigger.IsInsert || (trigger.isUpdate && rec.referrerCode__c!=trigger.oldMap.get(rec.id).referrerCode__c) || rec.Referrer__c==NULL)
        {
            setrCodes.add(rec.referrerCode__c.toLowercase());
        }
        if(trigger.IsInsert || (trigger.isUpdate && rec.CountryName__c!=trigger.oldMap.get(rec.id).CountryName__c || rec.Country__c==NULL))
        {
            rec.Country__c=null;
            if(rec.CountryName__c!=NULL && rec.CountryName__c!='')
                setCountry.add(rec.CountryName__c.toLowercase());
        }    
    }
    if(setrCodes.size()>0)
    {
        Map<string,Torc_User__c> maprCodes = new Map<string,Torc_User__c>();
        for(Torc_User__c tu:[Select Id, referralCode__c from Torc_User__c where referralCode__c in :setrCodes])
            maprCodes.put(tu.referralCode__c.toLowerCase(),tu);
        for(Torc_User__c rec:Trigger.New)
        {
            if(rec.referrerCode__c !='' && rec.referrerCode__c!=null && maprCodes.get(rec.referrerCode__c.toLowerCase())!=NULL)
            {
                rec.Referrer__c = maprCodes.get(rec.referrerCode__c.toLowerCase()).Id;
            }
        }    
    }
    if(setCountry.size()>0)
    {
        Map<string,id>mapS=new map<String,Id>();
        for(Torc_Country__c c:[Select Id,name from Torc_Country__c where Name in:setCountry])
            mapS.put(c.name.toLowercase(),c.id);
        for(Torc_User__c rec:Trigger.New)
        {
            if(trigger.IsInsert || (trigger.isUpdate && rec.CountryName__c!=trigger.oldMap.get(rec.id).CountryName__c || rec.Country__c==NULL))
            {
                if(rec.CountryName__c!=NULL && rec.CountryName__c!='' && mapS.get(rec.CountryName__c.toLowerCase())!=NULL)
                    rec.Country__c = mapS.get(rec.CountryName__c.toLowercase());
            }    
        }
    }
}