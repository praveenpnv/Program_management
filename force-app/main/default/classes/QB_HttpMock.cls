public class QB_HttpMock implements HttpCalloutMock 
{
   public static string Operation;  
   String returnResult = '';
   
   public QB_HttpMock() 
   {
      this.returnResult = '{"foo":"bar"}';
      if(QBOpportunitySetup.QBAPITestOperation!=NULL)
          for(QB_Test_Data__c QBT:[Select JSON__c from QB_Test_Data__c Where Name=:QBOpportunitySetup.QBAPITestOperation])
              this.returnResult = QBT.Json__c;
   }
   
   public QB_HttpMock(String json) 
   {
      this.returnResult = json;
   }
   
   
   public HTTPResponse respond(HTTPRequest req) 
   {
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      response.setBody(returnResult);
      return response;
  }
}