Public class TrolleyService
{
    public static string formatJson(string s)
    {
        s= s.replace('"currency_x"','"currency"');
        return s;
    }
    public static string unformatJson(string s)
    {
        s= s.replace('"currency"','"currency_x"');
        return s;
    }
    Public static t_batchResponse createBatch(t_batch t)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATEBATCH';
        string reqpath = 'batches';
        string body = TrolleyBase.callAPI('POST',formatJson(JSON.serialize(t)),reqpath);
        JSONParser jp = JSON.createParser(unformatJson(body));
        return (t_batchResponse) jp.readValueAs(t_batchResponse.class);
    }
    Public static t_recipientResponse createRecipient(T_recipient t)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATERECIPIENT';
        string reqpath = 'recipients';
        string body = TrolleyBase.callAPI('POST',formatJson(JSON.serialize(t)),reqpath);
        JSONParser jp = JSON.createParser(unformatJson(body));
        return (t_recipientResponse) jp.readValueAs(t_recipientResponse.class);
    }
    Public static t_recipientResponse updateRecipientreferenceId(T_recipientRefUp t)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATERECIPIENT';
        string reqpath = 'recipients/'+t.id;
        string body = TrolleyBase.callAPI('PATCH',formatJson(JSON.serialize(t)),reqpath);
        JSONParser jp = JSON.createParser(unformatJson(body));
        return (t_recipientResponse) jp.readValueAs(t_recipientResponse.class);
    }
    Public static t_invoiceResponse createInvoice(t_invoice t)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATEINVOICE';
        string reqpath = 'invoices/create';
        string body = TrolleyBase.callAPI('POST',formatJson(JSON.serialize(t)),reqpath);
        JSONParser jp = JSON.createParser(unformatJson(body));
        return (t_invoiceResponse) jp.readValueAs(t_invoiceResponse.class);
    }
    Public static t_invoicePaymentResponse createInvoicePayment(t_invoicePayment t)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATEINVOICEPAYMENT';
        string reqpath = 'invoices/payment/create';
        string body = TrolleyBase.callAPI('POST',formatJson(JSON.serialize(t)),reqpath);
        system.debug(body);
        JSONParser jp = JSON.createParser(unformatJson(body));
        return (t_invoicePaymentResponse) jp.readValueAs(t_invoicePaymentResponse.class);
    }
    Public static void updatePayment(T_paymentUpdate t,string batchId,string paymentId)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATEINVOICEPAYMENT';
            
        string reqpath = 'batches/'+batchid+'/payments/'+paymentId;
        string body = TrolleyBase.callAPI('PATCH',formatJson(JSON.serialize(t)),reqpath);
        system.debug(body);
        //JSONParser jp = JSON.createParser(unformatJson(body));
        //return (t_invoicePaymentResponse) jp.readValueAs(t_invoicePaymentResponse.class);
    }
/*    Public static void createPayment(T_payment t)
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'CREATEPAYMENT';
        string reqpath = 'payments';
        string body = TrolleyBase.callAPI('POST',formatJson(JSON.serialize(t)),reqpath);
    }
    Public static void updateRecipient(T_recipient t)
    {
        string reqpath = 'recipients/'+t.id;
        string body = TrolleyBase.callAPI('PATCH',JSON.serialize(t),reqpath);
    }

    Public static List<T_recipient> retriveAllRecipient()
    {
        if(test.isRunningTest())
            QBOpportunitySetup.QBAPITestOperation = 'RETRIVEREC';
        string reqpath = 'recipients';
        string body = TrolleyBase.callAPI('GET',null,reqpath);
        JSONParser jp = JSON.createParser(body);
        T_recipients t = (T_recipients)jp.readValueAs(T_recipients.class);
        return t.recipients;
    }
*/    
    Public class T_recipients
    {
        Public List<T_recipient> recipients;
        public T_recipient recipient{get;set;}
    }    
    Public class T_recipient
    {
        Public string id{get;set;}
        Public string referenceId{get;set;}
        Public string email{get;set;}
        Public string name{get;set;}
        Public string lastName{get;set;}
        Public string firstName{get;set;}
        Public string type{get;set;}
        Public string status{get;set;}
        Public string payoutMethod{get;set;}
        public string estimatedFees{get;set;}
        public List<T_account> accounts{get;set;}
        public T_address address{get;set;}
    }
    public class T_address
    {
        public string country{get;set;}
    }
    
    public class T_account
    {
        Public string id{get;set;}
        Public boolean primary{get;set;}
        Public string currency_x{get;set;}
        Public string country{get;set;}
        Public string type{get;set;}
        Public string emailAddress{get;set;}
        Public string wallet{get;set;}
    }
    
    public class t_accountResponse
    {
         Public string ok{get;set;}
        public T_account account{get;set;}
    }
    Public class T_recipientRefUp
    {
        Public string id{get;set;}
        Public string referenceId{get;set;}
    }
    Public class T_payments
    {
        public T_payments(List<T_payment> p)
        {
            payments=p;
        }
        Public List<T_payment> payments;
    } 
    Public virtual class T_paymentBase
    {
        Public string id{get;set;}
        public T_recipient recipient{get;set;}
        Public string amount{get;set;}
        Public string externalId{get;set;}
//        Public string category{get;set;}
//        public string currency_x{get;set;}        
        public string status{get;set;}
        public string memo{get;set;}  
        public boolean coverFees{get;set;}    
    }
    Public class T_payment extends T_paymentBase
    {
    }
    public class t_webhookPayment extends T_paymentBase
    {
        public string fees{get;set;}
    }
    Public class T_paymentUpdate
    {
        public string memo{get;set;}   
        public boolean coverFees{get;set;} 
        public string externalId{get;set;}    
    }
    Public class t_batches
    {
        Public List<t_batch> batches;
    } 
    Public class t_paymentwebhook
    {
        public string model{get;set;}
        public string action{get;set;}
        Public t_paymentwebhookbody body;
    } 
    Public class t_paymentwebhookbody
    {
        Public t_webhookPayment payment;
        Public T_recipient recipient;
        Public T_recipientAccount recipientAccount;
        
    } 
    public class T_recipientAccount
    {
        public string status{get;set;}
        public boolean primary{get;set;}
        public string recipientId{get;set;}
    }
    /*Public class t_invoicewebhook
    {
        public string model{get;set;}
        public string action{get;set;}
        Public t_invoicewebhookbody body;
    } 
    Public class t_invoicewebhookbody
    {
        Public T_invoice invoice;
    } */
    
    
    public virtual class t_batchBase
    {
        Public string id{get;set;}
        Public string amount{get;set;}
        Public string status{get;set;}
        public string description{get;set;}
    }
    public class t_batch extends t_batchBase
    {
        //public List<T_payment> payments{get;set;}
    }
    
    
    
    /*public class t_respondingpayments
    {
        public List<T_payment> payments{get;set;}
    }*/
    public class t_respondingbatch extends t_batchBase
    {
        //public t_respondingpayments payments{get;set;}
    }
    public class t_batchResponse
    {
        Public string ok{get;set;}
        public t_respondingbatch batch{get;set;}
    }
    
    public class t_recipientResponse
    {
        Public string ok{get;set;}
    }
   
    
    public class t_invoice
    {
        public string id{get;set;}
        public string recipientId{get;set;}
        public string externalId{get;set;}
        public string status{get;set;}
        public string invoiceNumber{get;set;}
        //public string description{get;set;}
        //public string invoiceDate{get;set;}
        //public string dueDate{get;set;}
        
        public List<t_invoiceline> lines{get;set;}
    }
    public class t_invoiceline
    {
        public string id{get;set;}
        public t_amount unitAmount{get;set;}
        public string quantity{get;set;}
        public string externalId{get;set;}
        public string description{get;set;}
    }
    public class t_amount
    {
        public string value{get;set;}
        public string currency_x{get;set;}
    }    
    public class t_invoiceResponse
    {
        Public string ok{get;set;}
        public t_invoice invoice{get;set;}
    }
    public class t_invoicePayment
    {
        public string batchId{get;set;}
        public List<t_id> ids{get;set;}
    }
    public class t_id
    {
        public t_id(string s)
        {
            invoiceId=s;
        }
        public string invoiceId{get;set;}
    }
    public class t_invoicePaymentResponse
    {
        Public string ok{get;set;}
        public t_respondinginvoicePayment invoicePayment{get;set;}
    }
    public class t_respondinginvoicePayment
    {
        Public string batchId{get;set;}
        Public string paymentId{get;set;}
    }
    public class p_paypalWebhook
    {
        public datetime create_time{get;set;}
        public string resource_type{get;set;}
        public string event_type{get;set;}
        public string summary{get;set;}
        public p_resource resource{get;set;}
    }
    public class p_resource
    {
        public p_batch_header batch_header{get;set;}
        
        public string transaction_id{get;set;}
        public t_amount payout_item_fee{get;set;}
        public string transaction_status{get;set;}
        public string payout_item_id{get;set;}
        public string payout_batch_id{get;set;}
        public t_payout_item payout_item{get;set;}
    }
    public class p_batch_header
    {
        public string payout_batch_id{get;set;}
        public string batch_status{get;set;}
        public t_amount amount{get;set;}
        public t_amount fees{get;set;}
        public integer payments{get;set;}
    }
    public class t_payout_item
    {
        public t_amount amount{get;set;}
        public string sender_item_id{get;set;}
    }
    
    
}