public without sharing class Questionnaire 
{
    public boolean isUSbased{get;set;}
    public string header{get;set;}
    public boolean showSelection{get;set;}
        
    public boolean isSuccess{get;set;}
    public Freelancer_Questionnaire__c rec{get;set;}
    public multipick marketServicelst{get;set;}
    public multipick investmentlst{get;set;}
    public multipick formOfBusinesslst{get;set;}
    public multipick clientCountlst{get;set;}
    
    public multipick employeeCountlst{get;set;}
    public multipick insuranceNeedlst{get;set;}
    
    
    public string fngett{get;set;}
    public string valgett{get;set;}
    public void setFormOfBusiness()
    {
        rec.put(fngett,valgett); 
    }
    public Questionnaire()
    {
        showSelection = false;
        if(ApexPages.currentPage().getParameters().get('type')!='US' && ApexPages.currentPage().getParameters().get('type')!='NONUS')
        {
            showSelection = true;
            return;
        }
        isUSbased = ApexPages.currentPage().getParameters().get('type')=='US'; 
        initialProcess();       
    }
    public void showUSBased()
    {
        showSelection = false;
        isUSbased = true;
        initialProcess();
    }
    public void showNonUSBased()
    {
        showSelection = false;
        isUSbased = false;
        initialProcess();
    }
    public void initialProcess()
    {
        errorFile1=errorFile2='';
        header = isUSbased?'Freelancer Questionnaire - US based Freelancers':'Freelancer Questionnaire - non-US based Freelancers';
        rec = new Freelancer_Questionnaire__c(Questionnaire_Type__c = (isUSbased?'US':'Non-US'));
        if(isUSbased)
            rec.Country__c='United States';
        
        marketServicelst = new multipick(Freelancer_Questionnaire__c.How_You_market__c.getDescribe(),'Other_Market_Your_Service__c',rec,true,'How_You_market__c',isUSbased);
        investmentlst = new multipick(Freelancer_Questionnaire__c.Investements__c.getDescribe(),'Other_Investment__c',rec,true,'Investements__c',isUSbased);
        formOfBusinesslst = new multipick(Freelancer_Questionnaire__c.Form_Of_Business__c.getDescribe(),'Other_Form_of_Business__c',rec,true,'Form_Of_Business__c',isUSbased);
        clientCountlst = new multipick(Freelancer_Questionnaire__c.Client_Count__c.getDescribe(),'',rec,true,'Client_Count__c',isUSbased);
        employeeCountlst = new multipick(Freelancer_Questionnaire__c.Employees_Contractor_Count__c.getDescribe(),'',rec,true,'Employees_Contractor_Count__c',isUSbased);
        insuranceNeedlst = new multipick(Freelancer_Questionnaire__c.Insurance_requirement__c.getDescribe(),'',rec,true,'Insurance_requirement__c',isUSbased);
        isSuccess = false;
        screen=1;
    }
    public integer screen{get;set;}
    public void next()
    {
        errorFile1=errorFile2='';
        boolean err=false;
        if(rec.Worked_As_employee__c=='Yes' && (rec.Employeement_Detail__c==NULL || rec.Employeement_Detail__c.length()<1))
        {
            rec.Employeement_Detail__c.addError('Please fill');
            err=true;
        }
        if(!marketServicelst.isRequiredok())
            err=true;
        if(!investmentlst.isRequiredok())
            err=true;
        if(!formOfBusinesslst.isRequiredokOpt())
            err=true;
        if(!clientCountlst.isRequiredokOpt())
            err=true;
        
        if(isUSBased)
        {
            if(!employeeCountlst.isRequiredokOpt())
                err=true;
            if(!insuranceNeedlst.isRequiredokOpt())
                err=true;
        }  
        if(!err)
            screen=2;      
    }
    public void previous()
    {
        errorFile1=errorFile2='';
        screen=1;
    }
    public void Save()
    {
        boolean err=false;
        boolean haveUp1=true;
        boolean haveUp2=true;
        if(rec.Agree_to_terms__c==false)
        {
            rec.Agree_to_terms__c.addError('Please check');
            err=true;
        }
        if(uploadedFile1==null)
        {
            errorFile1 = 'Please Upload document.';
            err=true;
            haveUp1=false;
        }
        if(uploadedFile2==null)
        {
            errorFile2 = 'Please Upload document.';
            err=true;
            haveUp2=false;
        }
       
        if(!err)
        {
            insert rec;
            uploadfile();
            isSuccess=true;
        }
        else
        {
            errorFile1 = haveUp1?'Please re-upload document.': 'Please Upload document.';
            errorFile2 = haveUp2?'Please re-upload document.': 'Please Upload document.';
        }    
    }
    
    public class multipick
    {
        public boolean isUSbased{get;set;}
        public string fieldName{get;set;}
        public boolean isCheckbox{get;set;}
        public string errorType{get;set;}
        public string otherValue{get;set;}
        public List<pickoption> options{get;set;}
        public Freelancer_Questionnaire__c record{get;set;}
        public string otherField{get;set;}
        public multipick(Schema.DescribeFieldResult fieldResult,string ofield,Freelancer_Questionnaire__c r,boolean icb,string feildnm,boolean isUS)
        {
            isUSBased = isUS;
            fieldname=feildnm;
            isCheckbox = icb;
            errorType = '';
            record =r;
            otherField = ofield;
            otherValue='';
            options = new List<pickoption>();
            if(fieldName=='Client_Count__c')
            {
                if(isUSbased)
                {
                    options.add(new pickOption('1',record,fieldname));
                    options.add(new pickOption('2',record,fieldname));
                    options.add(new pickOption('3',record,fieldname));
                    options.add(new pickOption('4 or more',record,fieldname));
                }
                else
                {
                    options.add(new pickOption('0 or 1 ',record,fieldname));
                    options.add(new pickOption('2-5',record,fieldname));
                    options.add(new pickOption('6 or more',record,fieldname));
                }
            }
            else
            {
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) 
                {
                    options.add(new pickOption(entry.getLabel(),record,fieldname));
                }
            }    
        }
        public boolean isRequiredok()
        {
            errorType ='';
            boolean atleast1=false;
            string res='';
            for(pickoption po:options)
            {
                if(po.chk)
                {
                    atleast1=true;
                    res = res+(res==''?po.label:('; '+po.Label));
                }    
                if(po.chk && po.label=='Other' && otherField!='' && (record.get(otherField)==NULL || record.get(otherField)==''))
                {
                    errorType= 'Add value in other';
                    return false;
                }    
            }
            record.put(fieldName,res);
            errorType = atleast1?'':'Select an option';
            return atleast1;
        }
        public boolean isRequiredokOpt()
        {
            errorType ='';
            if(record.get(fieldName)=='' || record.get(fieldName)==null)
            {
                errorType =  'Select an option';
                return false;
            }    
            if(record.get(fieldName)=='Other' && otherField!='' && (record.get(otherField)==NULL || record.get(otherField)==''))
            {
                errorType= 'Add value in other';
                return false;
            }
            
            return true;
        }
    }
    public transient Blob uploadedFile1 { get; set; }
    public String fileName1 { get; set; }
    public transient Blob uploadedFile2 { get; set; }
    public String fileName2 { get; set; }
    public string errorFile1{ get; set; }
    public string errorFile2{ get; set; }
    public void uploadFile()
    {
        uploadFile(uploadedFile1, fileName1);
        uploadFile(uploadedFile2, fileName2);
    }
    public void uploadFile(Blob uploadedFile, String fileName)
    {
        if (uploadedFile != null && fileName != null) 
        {
            String contentType;
            String extension = fileName.substringAfterLast('.').toLowerCase();
            switch on extension {
                when 'pdf'       { contentType = 'application/pdf'; }
                when 'png'       { contentType = 'image/png'; }
                when 'jpg', 'jpeg' { contentType = 'image/jpeg'; }
                when 'gif'       { contentType = 'image/gif'; }
                when 'doc'       { contentType = 'application/msword'; }
                when 'docx'      { contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; }
                when 'xls'       { contentType = 'application/vnd.ms-excel'; }
                when 'xlsx'      { contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'; }
                when 'txt'       { contentType = 'text/plain'; }
                when else        { contentType = 'application/octet-stream'; } // generic fallback
            }
        
        
        
            Attachment att = new Attachment();
            att.ParentId = rec.Id;
            att.Name = fileName;
            att.Body = uploadedFile;
            att.ContentType = contentType;
            insert att;
        }               
    }
    public class pickoption
    {
        public string namefld{get;set;}
        public boolean chk{get;set;}
        public string label{get;set;}
        public Freelancer_Questionnaire__c record{get;set;}
        public string getOptiontag()
        {
            string str='<input type="radio" name="'+namefld+'" onclick="setFormOfBusiness(\''+label +'\',\''+namefld +'\')"';
            str=str+(label == record.get(namefld)?' checked ':'');
            return str;
        }
        public pickoption(string lab,Freelancer_Questionnaire__c rec,string nmf)
        {
            record=rec;
            label=lab;
            chk=false;
            namefld = nmf;
        }
    }
}