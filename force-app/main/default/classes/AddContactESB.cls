public with sharing class AddContactESB {

    @AuraEnabled(cacheable=true)
    public static List<ID> ESBSFSubmitContact(Id contactId) {
        System.debug('Contact id: ' + contactId);
        List<ID> jobIDs = new List<ID>();
        
        // Fetch contact details
        Contact c = [SELECT 
                     FirstName, 
                     LastName,
                     OwnerId, 
                     TR1__Birthdate__c, 
                     Email, 
                     MailingStreet, 
                     MailingCity, 
                     MailingState, 
                     MailingCountry, 
                     MailingPostalCode, 
                     Nationality__c,
                     MobilePhone, 
                     BH_Preferred_Language__c,
                     Chapter_KPF__c,
                     Unit__c,
                     Primary_role__c 
                     FROM Contact 
                     WHERE ID = :contactId];
        
        List<String> missingFields = new List<String>();
        
        // Validate required fields
        if (String.isBlank(c.FirstName)) {
            missingFields.add('First Name');
        }
        /*if (String.isBlank(c.LastName)) {
            missingFields.add('Last Name');
        }*/
        if (c.TR1__Birthdate__c == null) {
            missingFields.add('Date of Birth');
        }
        if (String.isBlank(c.Email)) {
            missingFields.add('Email');
        }
        if (String.isBlank(c.MailingStreet)) {
            missingFields.add('Street Address');
        }
        if (String.isBlank(c.MailingCity)) {
            missingFields.add('City');
        }
        if (String.isBlank(c.MailingCountry)) {
            missingFields.add('Country');
        }
        if (String.isBlank(c.MailingPostalCode)) {
            missingFields.add('Postal Code');
        }
        if (String.isBlank(c.Nationality__c)) {
            missingFields.add('Nationality');
        }
        if (String.isBlank(c.MobilePhone)) {
            missingFields.add('Phone');
        }
        if (String.isBlank(c.BH_Preferred_Language__c)) {
            missingFields.add('Preferred Language');
        }
        /*if (String.isBlank(c.Sub_service_line__c)) {
            missingFields.add('Sub Service Line');
        }*/
        /*if (String.isBlank(c.Chapter_KPF__c)) {
            missingFields.add('Chapter');
        }*/
        if (String.isBlank(c.Unit__c)) {
            missingFields.add('Business Unit');
        }
        /*if (String.isBlank(c.Primary_role__c)) {
            missingFields.add('Role');
        }*/

        if (!missingFields.isEmpty()) {
            throw new EngagementCalloutException('The candidate cannot be sent to Mpleo, as the following relevant fields are missing: ' + String.join(missingFields, ', ') + '. Please correct the data on the candidate and try again.');
        }

        // Prepare JSON payload
        Map<String, Object> msg = new Map<String, Object>();
        msg.put('tag', 'salesforce.candidate.mpleo');
        
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('identifier', contactId);      
        msg.put('payload', payload);
        
        String body = JSON.serialize(msg);  
        System.debug('body->' + body);
        String esbURL = ESBSelector.getEsbUrlOpp(c.OwnerId);
        System.debug('esbURL->' + esbURL);
        
        // Queue the call
        jobIDs.add(System.enqueueJob(new QueueableESBCall(esbURL + 'api/message/add', 'POST', body)));
        
        // Return job IDs
        return jobIDs;
    }
}