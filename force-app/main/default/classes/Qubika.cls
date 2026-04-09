public class Qubika
{
    public Dummy_Object__c dummy{get;set;}
    public Qubika()
    {
        dummy=new Dummy_Object__c();
    }
    public Pagereference loadpaymentCSV()
    {
        return new Pagereference('/apex/qubikaoperation');
    }
    public Pagereference nonTorcTrolleySetup()
    {
        return new Pagereference('/apex/QBNonTorcSetup?id='+torc_Constants__c.getinstance().Qubika_Account__c);
    }
    public Pagereference loadUserGoogle()
    {
        return new Pagereference('/apex/loadQubikaData?id='+torc_Constants__c.getinstance().Qubika_Account__c);
    }
    
    public Pagereference loadPaymentGoogle()
    {
        return new Pagereference('/apex/nonTorcpayment?id='+dummy.Opportunity__c);
    }
    public Pagereference DoPayment()
    {
        return new Pagereference('/apex/TrolleyNonQBPayments?id='+dummy.Opportunity__c);
    }
    
    

}