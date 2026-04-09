public class EmailsenderNotifyADP {

    @InvocableMethod
    public static void sendEmail(List<Id> closingReportIds) {
        // Query the closing reports based on the provided IDs
        List<TR1__Closing_Report__c> queriedClosing = [SELECT Id, TR1__Person_Placed__c FROM TR1__Closing_Report__c WHERE Id IN :closingReportIds];
        
        RD1_Settings__mdt rd1=RD1_Settings__mdt.getInstance('RD1_Setting');
         // rd1.getInstance('RD1_Setting');
              
              // MyCustomMetadata__mdt customMetadataInstance = MyCustomMetadata__mdt.getInstance(developerName);
        // Check if there are any records returned by the query
        if (!queriedClosing.isEmpty()) {
            // Create a list to hold the email messages
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            // Query for the dummy contact
            List<Contact> contactList = [SELECT Id, Email FROM Contact WHERE Email =:rd1.Placement_To_Email_Address__c ];
            if (contactList.isEmpty()) {
                
                return;
            }
            Contact relatedContact = contactList[0];
            System.debug('relatedContact: ' + relatedContact);

            // Query for the email template
            List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE Name =:rd1.Engagement_Placement_Notification_Email__c LIMIT 1];
            if (templateList.isEmpty()) {
                
                return;
            }
            EmailTemplate template = templateList[0];

            // Iterate over the queried closing reports
            for (TR1__Closing_Report__c closingReport : queriedClosing) {
                // Create the email message
                Messaging.SingleEmailMessage emailService = new Messaging.SingleEmailMessage();
                emailService.setToAddresses(new String[] {rd1.Placement_To_Email_Address__c});
                emailService.setBccAddresses(new String[] {rd1.Placement_BCC_Email_Address__c});

                // Set the TargetObjectId to a dummy contact's ID
               emailService.setTargetObjectId(relatedContact.Id);
                

                // Set email template
                emailService.setTemplateId(template.Id);

                // Add the email to the list
                emailService.setSaveAsActivity(true);
                emailService.setWhatId(closingReport.Id);

                // Add the email to the list
                emails.add(emailService);
            }
            System.debug('emails: ' + emails);

            // Send all emails in one go
            if (!emails.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
                for (Messaging.SendEmailResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Email sent successfully');
                    } else {
                        System.debug('Email send failed with error: ' + result.getErrors()[0].getMessage());
                    }
                }
            }
        } else {
            System.debug('No closing reports found with the provided IDs');
        }
    }
}