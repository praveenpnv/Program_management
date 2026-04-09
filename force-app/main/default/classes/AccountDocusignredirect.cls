public class AccountDocusignredirect
{
    public Account act{get;set;}
    public AccountDocusignredirect(ApexPages.StandardController controller)
    {
        act=(Account) controller.getRecord();
        act = [Select ID, Name, MSA_Signer__c from Account where ID=:act.id];
    }
    public Pagereference saveAndreturn()
    {
        update act;
        return new pagereference('/'+act.id);   
    }
    public Pagereference reDirect()
    {
        if(act.MSA_Signer__c==NULL)
        {
           act.MSA_Signer__c.addError('Please Select');
           return NULL; 
        }
        update act;
        Docusign_Defaults__c dd =[Select DocuSign_Envelope_Template_MSA__c,DocuSign_Envelope_Template_MSA__r.Name FROM Docusign_Defaults__c LIMIT 1];
        string redirectUrl=site.getPathPrefix() =='/s'?'/apex/dfsle__sending':site.getPathPrefix()+'/apex/dfsle__sending';
        redirectUrl = redirectUrl +'?sId='+act.Id
              + '&templateId=' + dd.DocuSign_Envelope_Template_MSA__c
              + '&recordId='+act.Id
              + '&title='+ EncodingUtil.urlEncode(dd.DocuSign_Envelope_Template_MSA__r.Name,'UTF-8');    
        return new pagereference(redirectUrl)  ;      
    }
}