@RestResource(urlMapping='/torcRD1Event')
global with sharing class torcRD1Event 
{
    @HttpPost
    global static void postEvent() 
    {
        RestRequest req = RestContext.request;
        String body = (req.requestBody == null) ? null : req.requestBody.toString();
        body = AWSDataLoad.bodyreparse(body);
        system.debug('INITIAL BODY:' +body);
        List<Object> lst = (List<Object>)JSON.deSerializeUntyped(body);
        integer batchNo = integer.valueOf(Math.random()*99999999);
        string retId = AWSDataLoad.realTimeProcess(lst,batchNo);
        retId = retId==NULL?'':retId;
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf('OK-'+dateTime.Now()+'-'+batchNo+'-'+retId);
    }
}