trigger torcRD1Integration_Torc_Note_Trigger on Torc_Note__c (after insert) 
{
     if(Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c)
        torcRD1Integration.UpdateToRD1_Notes(trigger.New);
}