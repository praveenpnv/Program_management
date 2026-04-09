public class torcUserRedirect
{
    public Pagereference redirect()
    {
        for(Torc_User__c tu:[Select ID from Torc_User__c where External_Id__c = :id])
            return new Pagereference('/'+tu.id);
        error = 'Invalid Id';    
        return null; 
    }
    public string id{get;set;}
    public string error{get;set;}
    public torcUserRedirect()
    {
        error = 'Redirecting........';
        id= ApexPages.currentPage().getParameters().get('id');
        
    }
}