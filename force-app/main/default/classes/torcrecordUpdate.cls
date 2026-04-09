Public class torcrecordUpdate
{
    public string id{get;set;}
    public string redirectId{get;set;}    
    public string objectName{get;set;}    
    public torcrecordUpdate()
    {
        id=ApexPages.currentPage().getParameters().get('id');
        redirectId=ApexPages.currentPage().getParameters().get('recid');
        objectName=ApexPages.currentPage().getParameters().get('obj');
    }
    public void actioncall()
    {
        system.debug('in Action Call');
        AWSDataLoaderQueue.runProcessForSingleId(id,objectName);
    }
    
    Integer count = 0;
    public PageReference incrementCounter() 
    {
        if(count==0) actioncall();
        count++;
        if(count==2)
            return new pagereference('/'+redirectId);
        return null;
    }    
    public Integer getCount() 
    {
        return count;
    }
}