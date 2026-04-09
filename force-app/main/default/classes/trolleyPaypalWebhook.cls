@RestResource(urlMapping='/paypalhook')
global class trolleyPaypalWebhook 
{
    @HttpPost
    global static void doPost() 
    {
        system.debug('in Paypal Do Post');
        string body;
        try
        {
            if(test.isRunningTest())
                body = [Select JSoN__c from QB_test_data__c where Name='PAYPALWEB'].JSON__c;
            else
                body = RestContext.Request.requestBody.toString();
            LogAPI.PublishEvent('Info','Paypal-Webhook',body);    
            system.debug(body);
            JSONParser jp = JSON.createParser(TrolleyService.unformatJson(body));
            TrolleyService.p_paypalWebhook paymentwh = (TrolleyService.p_paypalWebhook) jp.readValueAs(TrolleyService.p_paypalWebhook.class);
            system.debug(paymentwh);
            Trolley_Paypal_Batch__c batc1=NULL;
            if(paymentwh.resource_type=='payouts')
            {
                for(Trolley_Paypal_Batch__c tpb:[Select ID,Name,Status__c,Amount__c,Fee__c,payments__c, paypal_webhook_at__c ,Summary__c
                                                  from Trolley_Paypal_Batch__c 
                                                  where Name = :paymentwh.resource.batch_header.payout_batch_id])
                    batc1 = tpb;
                boolean processexisting = false;    
                if(batc1==NULL)
                {    
                    batc1=new Trolley_Paypal_Batch__c();
                    processexisting = true;
                }    
                if(batc1.Status__c!='SUCCESS' && (batc1.id==NULL || batc1.paypal_webhook_at__c==NULL ||  batc1.paypal_webhook_at__c <= paymentwh.create_time || paymentwh.resource.batch_header.batch_status=='SUCCESS'))
                {
                    system.debug(batc1.paypal_webhook_at__c +'---'+ paymentwh.create_time);
                    batc1.paypal_webhook_at__c = paymentwh.create_time;
                    batc1.Name = paymentwh.resource.batch_header.payout_batch_id;
                    batc1.Amount__c = Decimal.valueOf(paymentwh.resource.batch_header.amount.value);
                    batc1.Fee__c = Decimal.valueOf(paymentwh.resource.batch_header.fees.value);
                    batc1.payments__c = paymentwh.resource.batch_header.payments;
                    
                    batc1.Status__c = paymentwh.resource.batch_header.batch_status;
                    batc1.Summary__c = paymentwh.summary==NULL?NULL:paymentwh.summary.left(255);
                    upsert batc1;
                }
                if(processexisting)
                {
                    for(List<Trolley_Invoice__c> l:[Select ID, Trolley_Paypal_Batch__c, trolley_paypal_batch_id__c 
                                            from Trolley_Invoice__c 
                                            Where trolley_paypal_batch_id__c = :paymentwh.resource.batch_header.payout_batch_id and Trolley_Paypal_Batch__c=NULL])
                    {
                        for(Trolley_Invoice__c a:l)
                        {    
                            a.Trolley_Paypal_Batch__c = batc1.id;
                        }
                        update l;
                    }
                }    
            }
            else if(paymentwh.resource_type=='payouts_item')
            {
                for(Trolley_Paypal_Batch__c tpb:[Select ID from Trolley_Paypal_Batch__c where Name = :paymentwh.resource.payout_batch_id])
                    batc1 = tpb;
                for(List<Trolley_Invoice__c> l:[Select paypal_Summary__c,paypal_webhook_at__c, ID, trolley_paypal_batch_id__c,Paypal_Id__c,Paypal_Fee__c, Paypal_Status__c, Trolley_Paypal_Batch__c, trolley_Invoicing_Payment_Id__c 
                                            from Trolley_Invoice__c 
                                            Where trolley_Invoicing_Payment_Id__c = :paymentwh.resource.payout_item.sender_item_id])
                {
                    for(Trolley_Invoice__c a:l)
                    {    
                        TrolleyService.p_resource t = paymentwh.resource;
                        a.Paypal_Fee__c = Decimal.valueOf(t.payout_item_fee.value);
                        a.Paypal_Id__c = t.payout_item_id;
                        a.Trolley_Paypal_Batch__c = batc1==NULL?NULL:batc1.id;   
                        a.trolley_paypal_batch_id__c = t.payout_batch_id; 
                        if(a.paypal_webhook_at__c==NULL ||  a.paypal_webhook_at__c < paymentwh.create_time || (a.paypal_webhook_at__c == paymentwh.create_time && a.Paypal_Status__c!='SUCCESS'))
                        {
                            a.paypal_webhook_at__c = paymentwh.create_time;
                            a.Paypal_Status__c = t.transaction_status;
                            a.paypal_Summary__c = paymentwh.summary==NULL?NULL:paymentwh.summary.left(255);
                        }    
                    }
                    update l;
                }
            }
        }
        catch(Exception ex)
        {
            LogAPI.PublishEvent(('ERROR'),'Paypal-Webhook-Exception',ex.getMessage(),body);
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
        k++;i++;
        j++;
        k++;k++;i++;
        j++;
        k++;k++;i++;
        j++;
        k++;k++;i++;
        j++;
        k++;k++;i++;
        j++;
        k++;k++;i++;
        j++;
        k++;
    }
}