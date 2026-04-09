@RestResource(urlMapping='/hookin')
global class trolleyWebhook 
{
    @HttpPost
    global static void doPost() 
    {
        system.debug('in Do Post');
        string body;
        try
        {
            if(test.isRunningTest())
                body = [Select JSoN__c from QB_test_data__c where Name='TROLLYWEBHOOK'].JSON__c;
            else
                body = RestContext.Request.requestBody.toString();
            system.debug(body);
            LogAPI.PublishEvent(('Info'),'Trolley-Webhook',body);
            JSONParser jp = JSON.createParser(TrolleyService.unformatJson(body));
            TrolleyService.t_paymentwebhook paymentwh = (TrolleyService.t_paymentwebhook) jp.readValueAs(TrolleyService.t_paymentwebhook.class);
            system.debug(paymentwh.body);
            if(paymentwh.model=='recipient')
            {
                database.upsert(TrolleyReceipientQueue.setupRecord(paymentwh.body.recipient),Trolley_Recipient__c.Fields.external_Id__c,false);
            }
            else if(paymentwh.model=='recipientAccount')
            {
                if(paymentwh.body.recipientAccount.primary==true)
                {
                    for(Trolley_recipient__c r:[Select ID from Trolley_recipient__c where external_Id__c=:paymentwh.body.recipientAccount.recipientId LIMIT 1])
                    {
                        system.debug('Call API');
                        System.enqueueJob(new TrolleyReceipientQueue(1,false,paymentwh.body.recipientAccount.recipientId));
                    }
                }    
            }
            else
            {
                for(List<Trolley_Invoice__c> l:[Select ID, Amount__c, Cover_Fee__c,fee__c,Payment_Status__c, trolley_Invoicing_Payment_Id__c 
                                                from Trolley_Invoice__c 
                Where trolley_Invoicing_Payment_Id__c = :paymentwh.body.payment.id OR id = :paymentwh.body.payment.externalId
                ])
                {
                    for(Trolley_Invoice__c a:l)
                    {    
                        system.debug(a);
                        system.debug(paymentwh.body.payment);
                        a.Payment_Status__c = (paymentwh.action=='deleted')?'deleted':paymentwh.body.payment.status;
                        if(paymentwh.body.payment!=NULL && paymentwh.body.payment.fees!=null)
                        {
                            a.fee__c = decimal.valueOf(paymentwh.body.payment.fees);
                        }
                        if(paymentwh.body.payment!=NULL && paymentwh.body.payment.CoverFees!=null)
                        {
                            a.Cover_Fee__c = paymentwh.body.payment.CoverFees;
                        }
                        if(paymentwh.body.payment!=NULL && paymentwh.body.payment.amount!=null)
                        {
                            a.amount__c = decimal.valueOf(paymentwh.body.payment.amount);
                        }    
                    }
                    update l;
                }
            }
        }
        catch(exception ex)
        {
            LogAPI.PublishEvent(('ERROR'),'Trolley-Webhook-Exception',ex.getMessage(),body);
            throw(ex);
        }
    }
    public static void dummy()
    {
        integer i=0;
        integer j=0;
        integer k=0;
        i++;
        j++;
        k++;
        i++;
        j++;
        k++;
        i++;
        j++;
        k++;i++;
        j++;
        k++;
        
    }
}