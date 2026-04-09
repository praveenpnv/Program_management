trigger torcSkillsUpdateJob on TR1__Skills__c (after insert, after update) 
{
    Map<id,tr1__Job__c> mapJobss = new map<id,tr1__Job__c>();
    for(TR1__Skills__c rec:trigger.new)
    {
        if(rec.TR1__Job__c!=NULL)
            mapJobss.put(rec.TR1__Job__c,null);
    }
    for(id id:mapJobss.keyset())
    {
        mapJobss.put(id,new TR1__Job__c(id=id,SkillUpdateTime__c = Datetime.now()));
    }
    if(mapJobss.keyset().size()>0)
    {
        torcRD1Integration.runningtorcCodeToUpdateData = true;
        update mapJobss.values();
    }    

}