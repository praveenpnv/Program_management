public class EmailSender {
    @AuraEnabled
    public static void sendEmail(Id recordId, String invoicingName, String paymentTerms, String graydonRating, String contactPerson, String comment) {
    List<Account> queriedAccounts = [SELECT Id, Name, Owner.name, CreatedById, BillingCity, BillingCountry, BillingCountryCode, BillingPostalCode, BillingState, BillingStreet, BH_VAT_Number__c, AUSY_Changepoint_ID__c FROM Account WHERE Id = :recordId LIMIT 1];
	
    RD1_Settings__mdt rd1=RD1_Settings__mdt.getInstance('RD1_Setting');
    if (rd1 == null) {
        System.debug('No predefined email found.');
        return;
    }
       
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setTemplateId([SELECT Id FROM EmailTemplate WHERE Name = 'Application ChangePoint Id request' LIMIT 1].Id);
   
    EmailTemplate emailTemplate = [SELECT HtmlValue, Body, Subject FROM EmailTemplate WHERE Name =  'Application ChangePoint Id request' LIMIT 1];
    System.debug('Email Template: ' + emailTemplate);
    String emailBodyHtml = emailTemplate.HtmlValue;
    String emailSubject = emailTemplate.Subject;
	
    String allowedSender = rd1.Placement_To_Email_Address__c;
     	if (queriedAccounts.size() > 0) {
      		Account acc = queriedAccounts[0];
            User sender = [SELECT FirstName, LastName, Signature, Opco__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String baseUrl = System.Url.getSalesforceBaseUrl().toExternalForm();
            String accountLink = baseUrl + '/lightning/r/Account/' + acc.Id + '/view';
			String recipientEmail;
            
            if (sender.Opco__c == System.Label.Belux) {
                recipientEmail = rd1.Recipient_Email_Belux__c;
            } else if (sender.Opco__c == System.Label.France) {
                recipientEmail = rd1.Recipient_Email_France__c;
            } else {
                 recipientEmail = rd1.Recipient_Email_Other__c;
            }
            emailSubject = emailSubject.replace('{!Account.Name}', acc.Name);
            emailBodyHtml = emailBodyHtml.replace('{!Account.Name}', acc.Name)
                .replace('{Account Link}', 
                '<a href="' + accountLink + '" target="_blank">' + acc.Name + '</a>')
                .replace('{!Account.BillingStreet}', acc.BillingStreet != null ? acc.BillingStreet : '')
                .replace('{!Account.BillingCity}', acc.BillingCity != null ? acc.BillingCity : '')
                .replace('{!Account.BillingState}', acc.BillingState != null ? acc.BillingState : '')
                .replace('{!Account.BillingCountry}', acc.BillingCountry != null ? acc.BillingCountry : '')
                .replace('{!Account.BillingCountryCode}', acc.BillingCountryCode != null ? acc.BillingCountryCode : '')
                .replace('{!Account.BillingPostalCode}', acc.BillingPostalCode != null ? acc.BillingPostalCode : '')
                .replace('{invoicingName}', invoicingName!= null ? invoicingName : '')
                .replace('{!Account.BH_VAT_Number__c}', acc.BH_VAT_Number__c != null ? acc.BH_VAT_Number__c : '')
                .replace('{graydonRating}', graydonRating != null ? graydonRating : '')
                .replace('{paymentTerms}', paymentTerms != null ? paymentTerms : '')
                .replace('{contactPerson}', contactPerson != null ? contactPerson : '')
                .replace('{comment}', comment != null ? comment : '')
                .replace('{!Account.OwnerFullName}', acc.Owner.name != null ? acc.Owner.name : '')
                .replace('{!User.Name}', sender.LastName != null ? sender.FirstName + ' ' + sender.LastName : '');
            email.setHtmlBody(emailBodyHtml); 
            email.setSaveAsActivity(false);
            email.setToAddresses(recipientEmail.split(','));
            email.setSubject(emailSubject);
            email.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress WHERE Address = :allowedSender LIMIT 1].Id);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email Send Results: ' + results);
            if (results[0].isSuccess()) {
                System.debug('Email sent successfully');
            } else {
                System.debug('Email send failed with error: ' + results[0].getErrors()[0].getMessage());
            } 
        }else {
            System.debug('No account found with the provided ID');
        }
    }
}