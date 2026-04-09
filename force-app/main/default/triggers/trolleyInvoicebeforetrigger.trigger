trigger trolleyInvoicebeforetrigger on Trolley_Invoice__c (before insert, before update) 
{
    for(Trolley_Invoice__c rec:trigger.new)
    {
        rec.Ready_To_Process_Paypal_Fee__c = (rec.Paypal_Status__c == 'SUCCESS');
    }
}