trigger updateContactOnResumeUploadLink on ContentDocumentLink (after insert) 
{
    if(!Torc_Rd1_Integration__c.getinstance().Sync_Enabled__c) return;
    Map<id,Contact> lstContacts=new Map<id,Contact>();
    Map<id,Set<id>>contactIds=new Map<id,Set<id>>();
    Map<id,id>contentVersionIds=new Map<id,id>();
    for(ContentDocumentLink con:trigger.new)
    {
        string s=con.LinkedEntityId;
        if(s!=NULL && s.left(3)=='003')
        {
            if(contactIds.get(s)==NULL)
                contactIds.put(s,new set<id>());
            contactIds.get(s).add(con.ContentDocumentId);
            contentVersionIds.put(con.ContentDocumentId,s);
        }     
    }
    if(contactIds.keyset().size()>0)
    {
        for(ContentVersion cv:[SELECT Id, ContentDocumentId from ContentVersion 
                                        where FirstPublishLocationId not IN :contactIds.keyset()
                                        and is_Resume__c= TRUE AND Resume_From_Torc__c=FALSE AND ContentDocumentId in :contentVersionIds.keyset()])
        {
            lstContacts.put(contentVersionIds.get(cv.ContentDocumentId),new Contact(id=contentVersionIds.get(cv.ContentDocumentId), Last_Resume_Update__c =dateTime.now()));
        }
    }
    if(lstContacts.keyset().size()>0)
    {
        torcRD1Integration.runningtorcCodeToUpdateData = true;
        try{
        database.update(lstContacts.values(),false);
        }
        catch(exception ex)
        {
        }
    }    

}