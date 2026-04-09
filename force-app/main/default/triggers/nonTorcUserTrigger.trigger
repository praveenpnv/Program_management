trigger nonTorcUserTrigger on Non_Torc_User__c (before insert,before update) 
{
    map<string,contact> mapC=new map<string,contact>();
    for(Non_Torc_User__c rec:trigger.new)
    {
        if(rec.email__c==NULL ||rec.email__c=='')
           rec.email__c = rec.Official_Email__c; 
        rec.Name = (rec.Given_Name__c+' '+rec.family_Name__c).left(80);
        mapC.put(rec.Email__c.toLowercase(),null);
    }       
    for(Contact c:[Select Id,Email,Firstname,lastName from Contact where email in:mapC.keyset()])
        mapC.put(c.email.toLowercase(),c);
    for(Non_Torc_User__c rec:trigger.new)
    {
        if(mapC.get(rec.Email__c.toLowercase())==NULL)
        {
            Contact c=new Contact(email=rec.Email__c);
            mapC.put(c.email.toLowercase(),c);
        }
    }
    List<Contact> lstC=new List<Contact>();
    for(Non_Torc_User__c rec:trigger.new)
    {
        Contact c= mapc.get(rec.Email__c.toLowercase());
        if(c.id==NULL || (trigger.isUpdate && (
                                                    rec.Given_Name__c!=trigger.oldMap.get(rec.id).Given_Name__c
                                                    ||  rec.Family_Name__c!=trigger.oldMap.get(rec.id).Family_Name__c
                                               )))
        {
            c.FirstName = rec.Given_Name__c;
            c.LastName= rec.Family_Name__c;
            lstC.add(c);
        }
    }
    if(lstC.size()>0)
        upsert lstC;
    for(Non_Torc_User__c rec:trigger.new)
    {
        if(trigger.isinsert || rec.Contact__c==NULL)
        {
            rec.Contact__c = mapC.get(rec.Email__c.toLowerCase()).id;
        }
    }    
        
}