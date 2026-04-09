/**
 * @description       : Apex controller for the SubmittalEmailWrapper Aura component
 * @author            : mhamdaoui@salesforce.com
 * @last modified on  : 07-15-2024
 * @last modified by  : Raga Viswanathan
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-30-2022   mhamdaoui@salesforce.com   Initial Version
 * 1.1   07-12-2022   Raga Viswanathan           CITATS-1210
 * 1.2   10-07-2022   iabdennour@salesforce.com  CITATS-1676 - Update Client Contacts for activated/deactivated users, called from 'Client Contact for User' flow
 * 1.3   10-10-2022   Raga Viswanathan           CITATS-1687
 * 1.4   10-11-2022   iabdennour@salesforce.com  CITATS-1676 - Update create contact method to also allow for update of contacts
 **/
public with sharing class EmailModalBHWrapperCtrl {
    public static final String SUBMITTAL_STAGE = 'Submittal';
    public static final String PROPOSED_TO_CLIENT = 'Proposed to Client';

    /**
     * @description Method pulls related job Id, job name, contact ids for resumes,
     * initial 'To' list based on passed application Ids
     *
     * @param appIds list of selected application Ids
     * @param stage  ats Modal stage name
     * @return Map with necessary details
     */
    @AuraEnabled
    public static Map<String, Object> getDetailsByApplicationIds(List<String> appIds, String stage) {
        Map<String, Object> submittalDetailsMap = new Map<String, Object>{
            'defaultResumeAttachment' => TR1__TalentRoverProperties__c.getOrgDefaults()?.TR1__Do_Not_Attach_Resume_In_Call_List__c == false
        };
        if (appIds.isEmpty()) {
            return submittalDetailsMap;
        }

        List<TR1__Application_V2__c> apps = [
            SELECT Id, TR1__Job__c, TR1__Job__r.Name, TR1__Job__r.TR1__Contact__c, TR1__Applicant__c, TR1__Job__r.TR1__Hiring_Manager__c, TR1__Job__r.TR1__Job_Contact__c
            FROM TR1__Application_V2__c
            WHERE Id IN :appIds
            WITH SECURITY_ENFORCED
        ];

            String jobId;
            String jobName;
            String initialToList;
            String hiringManager;
            String clientContact;
            Set<Id> contIds = new Set<Id>();
            if (!apps.isEmpty()) {
                for (TR1__Application_V2__c app : apps) {
                    contIds.add(app.TR1__Applicant__c);
                    jobId = app.TR1__Job__c;
                    jobName = app.TR1__Job__r.Name;
                    initialToList = app.TR1__Job__r.TR1__Job_Contact__c;
                    hiringManager = app.TR1__Job__r.TR1__Hiring_Manager__c;
                    clientContact = app.TR1__Job__r.TR1__Job_Contact__c;
                }
                submittalDetailsMap.put('contIds', contIds);
                submittalDetailsMap.put('jobId', jobId);
                submittalDetailsMap.put('jobName', jobName);
                submittalDetailsMap.put('initialToList', initialToList);
                submittalDetailsMap.put('hiringManager', hiringManager);
                submittalDetailsMap.put('clientContact', clientContact);
            }

        return submittalDetailsMap;
    }

    
    /**
     * @description Method updates application's TR1__Stage__c field with the SUBMITTAL_STAGE value
     *
     * @param applicationIds list of selected application Ids
     * @param stage
     * @return instance of the Response class
     */
    @AuraEnabled
    public static Response callSubmitWithEmail(List<String> applicationIds, String stage) {
        Response resp = new Response();
        try {
            List<TR1__Application_V2__c> lstApplications = new List<TR1__Application_V2__c>();

            if (!Schema.sObjectType.TR1__Application_V2__c.isUpdateable()) {
                AuraHandledException e = new AuraHandledException('InsufficientAccessRights');
                e.setMessage('InsufficientAccessRights');


                throw e;
            }

            // Update the Application V2 records
            if (applicationIds.size() > 0) {
                for (String appId : applicationIds) {
                    TR1__Application_V2__c app = new TR1__Application_V2__c();
                    app.Id = appId;
                    app.TR1__Stage__c = stage;
                    lstApplications.add(app);
                }

                if (lstApplications.size() > 0) {
                    update lstApplications;
                }
            }
            resp.isSuccess = true;
            resp.message = 'The Candidate(s) have been Submitted and the Email has been sent successfully.';
        } catch (Exception ex) {
            resp.isSuccess = false;
            resp.message = ex.getMessage();
        }
        return resp;
    }
    /**
     * @description Response class
     */
    public with sharing class Response {
        /**
         * @description Boolean isSuccess
         */
        @AuraEnabled
        public Boolean isSuccess { get; set; }
        /**
         * @description String message
         */
        @AuraEnabled
        public String message { get; set; }
    }


    }