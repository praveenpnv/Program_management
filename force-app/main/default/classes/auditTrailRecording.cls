global class auditTrailRecording implements Schedulable 
{
    global void execute(SchedulableContext SC) 
    {
        DateTime dt = DateTime.Now().adddays(-45);
        for(Audit_Trail__c rec:[Select Id, Performed_On__c from Audit_Trail__c Order by Performed_On__c DESC LIMIT 1])
        {
            system.debug(rec.Performed_On__c);
            dt=rec.Performed_On__c.addhours(-1);
        }    
        system.debug(dt);   
        integer maxLimit = 4000;
        
        if (Test.isRunningTest()) {
            maxLimit = 5;
        }
         
        for(List<SetupAuditTrail> lst:[SELECT Id, Action, CreatedById, CreatedDate, Display, Section 
                                            FROM SetupAuditTrail 
                                            WHERE Action in 
                                            (   'deletedCF','changedCFType','createdCF',
                                                'deletedCFCustom','changedCFTypeCustom','createdCFCustom',
                                                'createdCFLookup','changedCFLookup','deletedCFLookup',
                                                'createdCFLookupCustom','changedCFLookupCustom','deletedCFLookupCustom',
                                                'changedCFDefaultFormula', 'createdCFFormula', 'deletedCFDefaultFormula', 
                                                'changedCFFormulaCustom', 'createdCFFormulaCustom', 
                                                'deletedCFFormulaCustom' ,'changedCFFormula'
                                            )
                                            AND CreatedDate>=:dt
                                            Order by CreatedDate
                                            LIMIT :maxLimit])
        {
            List< Audit_Trail__c> lstnew=new List< Audit_Trail__c>();
            for(SetupAuditTrail rec:lst)
            {
                Audit_Trail__c recNew=new Audit_Trail__c(Audit_ID__c = rec.id, 
                                                      Action__c = rec.Action, 
                                                      Developer__c = rec.CreatedbyId,
                                                      Handled__c = false,
                                                      Operation__c = (rec.Display==NULL?NULL:rec.Display.left(255)),
                                                      Performed_On__c = rec.CreatedDate,
                                                      Section__c = rec.Section);
                 lstnew.add(recNew);  
            } 
            upsert lstnew  Audit_ID__c;                                                     
        }                                                        
    }
}