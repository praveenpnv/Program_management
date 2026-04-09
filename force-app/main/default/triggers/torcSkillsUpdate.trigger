trigger torcSkillsUpdate on ATSExtractedCandidateSkill__c (after insert, after update) 
{
    
    Map<id,Contact> mapContacts = new map<id,Contact>();
    for(ATSExtractedCandidateSkill__c rec:trigger.new)
    {
        mapContacts.put(rec.Contact_Candidate__c,null);
    }
    for(id id:mapContacts.keyset())
    {
        mapContacts.put(id,new Contact(id=id,SkillUpdateTime__c = Datetime.now()));
    }
    if(mapContacts.keyset().size()>0)
    {
    torcRD1Integration.runningtorcCodeToUpdateData = true;
    update mapContacts.values();
    }

}