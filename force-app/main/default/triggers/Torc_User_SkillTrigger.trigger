trigger Torc_User_SkillTrigger on Torc_User_Skill__c (before insert, before update) 
{
    for(Torc_User_Skill__c rec:trigger.new)
        rec.Skil_Name__c = rec.Skil_Name_For__c;

}