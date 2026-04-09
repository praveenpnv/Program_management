/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CustomClosingReportHandler {
    
    public static void SendEmail(List<TR1__Closing_Report__c> newList) {
        if (newList.isEmpty()) return;
        
        Set<Id> parentIds = new Set<Id>();
        Set<Id> crIds = new Set<Id>();
        
        for (TR1__Closing_Report__c cr : newList) {
            if (cr.ParentPlacementId__c != null) parentIds.add(cr.ParentPlacementId__c);
            crIds.add(cr.Id);
        }
        
        if (parentIds.isEmpty()) return;
        
        Schema.DescribeSObjectResult describeResult = TR1__Closing_Report__c.SObjectType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = describeResult.fieldSets.getMap();
        Schema.FieldSet fs = fieldSetMap.get('Change_Request');
        if (fs == null) return;
        
        List<Schema.FieldSetMember> fieldSetMembers = fs.getFields();
        
        List<String> fieldNames = new List<String>();
        Map<String, String> relationshipFields = new Map<String, String>();
        
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            String fieldAPI = fsm.getFieldPath();
            Schema.SObjectField sField = TR1__Closing_Report__c.SObjectType.getDescribe().fields.getMap().get(fieldAPI);
            Schema.DescribeFieldResult fieldDescribe = sField.getDescribe();
            
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                String relationshipName = fieldDescribe.getRelationshipName();
                if (relationshipName != null) {
                    fieldNames.add(relationshipName + '.Name');
                    relationshipFields.put(fieldAPI, relationshipName + '.Name');
                } else {
                    fieldNames.add(fieldAPI);
                }
            } else {
                fieldNames.add(fieldAPI);
            }
        }
        
        String parentSoql = 'SELECT ' + String.join(fieldNames, ',') +
            ' FROM TR1__Closing_Report__c WHERE Id IN :parentIds';
        List<TR1__Closing_Report__c> parentList = Database.query(parentSoql);
        
        Map<Id, TR1__Closing_Report__c> parentMap = new Map<Id, TR1__Closing_Report__c>();
        for (TR1__Closing_Report__c rec : parentList) parentMap.put(rec.Id, rec);
        
        String crSoql = 'SELECT ' + String.join(fieldNames, ',') +
            ' FROM TR1__Closing_Report__c WHERE Id IN :crIds';
        List<TR1__Closing_Report__c> crListWithNames = Database.query(crSoql);
        Map<Id, TR1__Closing_Report__c> crMapWithNames = new Map<Id, TR1__Closing_Report__c>();
        for (TR1__Closing_Report__c rec : crListWithNames) crMapWithNames.put(rec.Id, rec);
        
        // RecordType map
        Map<Id, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.TR1__Closing_Report__c.getRecordTypeInfosById();
        
        Map<String, String> comparisonFieldMap = new Map<String, String>{
            'Sales_CR__c' => 'TR1__Job_Credit__c',
                'Sales_secondary_CR__c' => 'TR1__Other_Credit__c',
                'Recruiting_CR__c' => 'TR1__Candidate_Credit__c',
                'Recruiting_secondary_CR__c' => 'TR1__Marketing_Credit__c'
                };
                    
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
      
        RD1_Settings__mdt settings = [
            SELECT Notify_Recipient__c,CC_Recipients__c,Org_Wide_Email__c 
            FROM RD1_Settings__mdt
            WHERE DeveloperName = 'RD1_Setting'
            LIMIT 1
        ];
      
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();

        if (settings != null) {
            if (String.isNotBlank(settings.Notify_Recipient__c)) {
                toAddresses = settings.Notify_Recipient__c.replace(' ', '').split(',');
            }
            if (String.isNotBlank(settings.CC_Recipients__c)) {
                ccAddresses = settings.CC_Recipients__c.replace(' ', '').split(',');
            }
        
            OrgWideEmailAddress owea;
            try {
               owea = [
                    SELECT Id, Address, DisplayName
                    FROM OrgWideEmailAddress
                    WHERE Address = :settings.Org_Wide_Email__c
                    LIMIT 1
                     ];
            } catch (QueryException e) {
                System.debug('Organization-Wide Email Address not found or not verified: ' + e.getMessage());
                return;
            }
            
        
        for (TR1__Closing_Report__c cr : newList) {
            if (cr.RecordTypeId == null || cr.ParentPlacementId__c == null) continue;
            
            String recordTypeName = rtMap.get(cr.RecordTypeId).getDeveloperName();
            if (recordTypeName != 'Change_Request_Permanent' && recordTypeName != 'Change_Request') continue;
            
            TR1__Closing_Report__c parentRec = parentMap.get(cr.ParentPlacementId__c);
            if (parentRec == null) continue;
            
            TR1__Closing_Report__c crFull = crMapWithNames.get(cr.Id);
            List<String> diffRows = new List<String>();
            
            
            Set<String> hiddenFieldsForUI = new Set<String>{
                'TR1__Job_Credit__c',
                    'TR1__Other_Credit__c',
                    'TR1__Candidate_Credit__c',
                    'TR1__Marketing_Credit__c',
                    'CreatedById',
                    'Id'
                    };
                        
                        for (Schema.FieldSetMember fsm : fieldSetMembers) {
                            String crField = fsm.getFieldPath();
                            String parentField = crField;
                            
                            if (comparisonFieldMap.containsKey(crField)) {
                                parentField = comparisonFieldMap.get(crField);
                            }
                            
                            Object parentVal;
                            Object crVal;
                            
                            if (relationshipFields.containsKey(parentField)) {
                                parentVal = parentRec.getSObject(relationshipFields.get(parentField).split('\\.')[0])?.get('Name');
                            } else {
                                parentVal = parentRec.get(parentField);
                            }
                            
                            if (relationshipFields.containsKey(crField)) {
                                crVal = crFull.getSObject(relationshipFields.get(crField).split('\\.')[0])?.get('Name');
                            } else {
                                crVal = crFull.get(crField);
                            }
                            
                            System.debug('Field: ' + crField + ' | parentVal=' + parentVal + ' | crVal=' + crVal);
                            
                            String actualParentFieldAPI = comparisonFieldMap.containsKey(crField) ? comparisonFieldMap.get(crField) : crField;
                            Boolean renderInEmail = !(hiddenFieldsForUI.contains(actualParentFieldAPI) && crVal == null);
                            
                            System.debug('Field: ' + crField + ' | parentVal=' + parentVal + ' | crVal=' + crVal + ' | renderInEmail=' + renderInEmail);
                            if (String.valueOf(parentVal) != String.valueOf(crVal) && renderInEmail) {
                                diffRows.add(
                                    '<tr>' +
                                    '<td>' + fsm.getLabel() + '</td>' +
                                    '<td>' + (parentVal != null ? String.valueOf(parentVal) : '') + '</td>' +
                                    '<td>' + (crVal != null ? String.valueOf(crVal) : '') + '</td>' +
                                    '</tr>'
                                );
                            }
                        }
            
            if (!diffRows.isEmpty()) {
                String approvalUrl = 'https://randstaddigital.lightning.force.com/lightning/page/home';
                
                String htmlBody =
                    '<p><b>Action:</b> Change Request</p>' +
                    //'<p><b>Added by:</b> ' + cr.CreatedBy.Name + '</p>' +
                    '<p><b>Placement :</b> Parent Placement ID (' + cr.CR_Number__c + ')</p>' +
                    '<p><b>Company:</b> ' + cr.Account_TK__c + '</p>' +
                    '<p><b>Change Request:</b> ' + cr.Name + '</p>' +
                    '<p><b>Requested by:</b> ' + cr.Requested_by__c + '</p>' +
                    '<p><b>Type:</b> ' + cr.Request_Type__c + '</p>' +
                    '<p><b>Status:</b> ' + cr.Request_Status__c + '</p>' +
                    '<p>This Change Request can be approved at the following URL: <a href="' + approvalUrl + '">Approve</a></p>' +
                    '<p><b>Change Request Effective Date:</b> ' + cr.Change_Request_Effective_Date__c + '</p>' +
                    '<p><b>Change Request Comments:</b> ' + cr.Change_Request_Comments__c + '</p>' +
                    '<p><b>Comments:</b> ' + cr.Comments__c + '</p>' +
                    '<hr />' +
                    '<table border="1" style="border-collapse:collapse;">' +
                    '<tr><th>Field</th><th>Placement Value</th><th>Change Request Value</th></tr>' +
                    String.join(diffRows, '') +
                    '</table>';
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                //mail.setToAddresses(new List<String>{'rd-assignments@randstaddigital.com','kishor.mali@randstaddigital.com'});
                mail.setToAddresses(toAddresses);
                if (!ccAddresses.isEmpty()) mail.setCcAddresses(ccAddresses);
                mail.setOrgWideEmailAddressId(owea.Id);
                mail.setSubject('Placement Change Request Created - ' + cr.Name);
                mail.setHtmlBody(htmlBody);
                emails.add(mail);
            }
        }
              
        if (!emails.isEmpty()) {
            try {
                System.debug('Attempting to send ' + emails.size() + ' email(s)...');
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
                
                for (Messaging.SendEmailResult res : results) {
                    if (res.isSuccess()) {
                        System.debug(' Email sent successfully.');
                    } else {
                        for (Messaging.SendEmailError err : res.getErrors()) {
                            System.debug('Email send failed: ' + err.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(' Exception while sending email: ' + e.getMessage());
                System.debug('Stack Trace: ' + e.getStackTraceString());
            }
        }  
    }
 }
}