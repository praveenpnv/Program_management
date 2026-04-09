trigger updateContactOnResumeUpload on ContentVersion (after insert, after update) 
{
    if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
    Map<id,Contact> lstContacts=new Map<id,Contact>();
    set<id>ContentDocumentIds=new set<id>();
    for(ContentVersion con:trigger.new)
    {
        string s=con.FirstPublishLocationId;
        if(con.is_Resume__c && con.Resume_From_Torc__c==false)
        {
            if(trigger.isInsert || trigger.oldMap.get(con.id).is_Resume__c==false)
            {
                if(s!=NULL && s.left(3)=='003')
                     lstContacts.put(con.FirstPublishLocationId,new Contact(id=con.FirstPublishLocationId, Last_Resume_Update__c =dateTime.now()));
                else
                    ContentDocumentIds.add(con.ContentDocumentId);
            }        
        }
    }
    if(ContentDocumentIds.size()>0)
    {
        for(ContentDocumentLink cd:[SELECT Id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where ContentDocumentId in :ContentDocumentIds])
        {
            string s=cd.LinkedEntityId;
            if(s!=NULL && s.left(3)=='003')
                lstContacts.put(cd.LinkedEntityId,new Contact(id=cd.LinkedEntityId, Last_Resume_Update__c =dateTime.now()));
        }
    }
    if(lstContacts.keyset().size()>0)
    {
        torcRD1Integration.runningtorcCodeToUpdateData = true;
        update lstContacts.values();
    }    
}