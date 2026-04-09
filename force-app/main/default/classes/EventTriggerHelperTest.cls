/**
* @File Name : EventTriggerHelperTest.cls
* @Description : Unit tests for EventTriggerHelper
* @Author :
* @Last Modified By :
* @Last Modified On : September 2, 2025
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 2, 2025 |   | Initial Version
**/
@isTest
public class EventTriggerHelperTest {
    
    // Common test data for all test methods
    private static User interviewer;
    private static User interviewer2;
    private static Contact interviewee;
    private static TR1__Job__c job;
    private static TR1__Application_V2__c application;
    private static TR1__Send_Out_Schedule_V2__c sendOut;

    @testSetup
    static void setupData() {
        // Create Candidate (Contact)
        interviewee = RD1TestDataFactory.createCandidate();
        interviewee.TR1__Is_Contact__c=true;
        system.debug('interviewee'+interviewee);
        // Create Job
        Account acc = RD1TestDataFactory.createTestAccount();
        Contact interviewee1 = RD1TestDataFactory.createTestContact(acc.Id,'Client');
        TR1__Job__c job = RD1TestDataFactory.createTestJob(acc.Id, interviewee1.Id);
        

        // Create Application
        application = RD1TestDataFactory.createApplication(interviewee.Id, job.Id, 'Consulting');
        application.TR1__Stage__c = 'internal interview';

        // Create Users (inside runAs to avoid Mixed DML)
        System.runAs(new User(Id = UserInfo.getUserId())) {
            interviewer  = RD1TestDataFactory.createUser('int1', 'Interviewer1', 'US');
            insert interviewer;
            interviewer2 = RD1TestDataFactory.createUser('int2', 'Interviewer2', 'US');
            insert interviewer2;
        }

        // Create SendOut
        sendOut = new TR1__Send_Out_Schedule_V2__c(
            Email_Message__c = 'Interview invite text',
            TR1__Interviewers_Ids__c = interviewer.Id,
            TR1__Interviewee__c = interviewee.Id,
            TR1__Application_V2__c=application.Id
        );
        insert sendOut;
        system.debug('sendOut'+sendOut);
        
                 
        TR1__ATS_Configuration_Settings__c trp = new TR1__ATS_Configuration_Settings__c(
            	TR1__Track_Interview_Attendees__c = true
        );
        insert trp;

        // Create attendees (user + contact)
        List<TR1__Interview_Attendee__c> attendees = new List<TR1__Interview_Attendee__c>{
            new TR1__Interview_Attendee__c(
                TR1__User__c = interviewer.Id,
                TR1__Send_Out_Schedule_V2__c = sendOut.Id
            ),
            new TR1__Interview_Attendee__c(
                TR1__Contact__c = interviewee.Id,
                TR1__Send_Out_Schedule_V2__c = sendOut.Id
            )
        };
        insert attendees;
        system.debug('attendees'+attendees);
    }

    @isTest
    static void testEventTriggerEndToEnd() {
        
        TR1__Send_Out_Schedule_V2__c sendOut=[Select id,Email_Message__c from TR1__Send_Out_Schedule_V2__c];
        // Step 1: Insert Event
        Event ev = new Event(
            StartDateTime = System.now().addDays(1),
            EndDateTime   = System.now().addDays(1).addHours(1),
            Subject       = 'Interview',
             Description   = 'Interview invite text',
            TR1__Send_Out_Schedule_V2__c = sendOut.Id
        );
        
        

        Test.startTest();
        insert ev;
        Test.stopTest();
        
        system.debug('ev'+ev);

        // Reload Event
        ev = [SELECT Id, Description, OwnerId FROM Event WHERE Id = :ev.Id];
        system.debug('event'+ev);
        System.assertEquals(sendOut.Email_Message__c, ev.Description, 'Description should come from SendOut');
   

        // Step 2: Verify EventRelations (2 → interviewer + interviewee)
        List<EventRelation> relations = [
            SELECT RelationId, IsInvitee 
            FROM EventRelation 
            WHERE EventId = :ev.Id
        ];
        
        EventRelation relToUpdate = null;
        System.assertEquals(2, relations.size(), 'Should have 2 invitee relations');
        for (EventRelation er : relations) {
            if (er.IsInvitee) {
        relToUpdate = er;
        break;
    }
        }

        // Step 3: Update RSVP on one relation
        relToUpdate.Status = 'Accepted';
        //Test.startTest();
        update relToUpdate;
        //Test.stopTest();

        // Step 4: Check Interview_Attendee got RSVP update
        List<TR1__Interview_Attendee__c> updatedAtts = [
            SELECT Id, RSVP_Status__c 
            FROM TR1__Interview_Attendee__c 
            WHERE TR1__Send_Out_Schedule_V2__c = :sendOut.Id
        ];
        Boolean anyUpdated = false;
        for (TR1__Interview_Attendee__c att : updatedAtts) {
            if (att.RSVP_Status__c != null) {
                anyUpdated = true;
            }
        }
        System.assert(anyUpdated, 'At least one attendee should have RSVP updated');
    }

    @isTest
    static void testBulkEvents() {
        
        TR1__Send_Out_Schedule_V2__c sendOut=[Select id,Email_Message__c from TR1__Send_Out_Schedule_V2__c];
        // Bulk insert 5 events
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 5; i++) {
            events.add(new Event(
                StartDateTime = System.now().addDays(1),
                EndDateTime   = System.now().addDays(1).addHours(1),
                Subject       = 'Bulk Interview ' + i,
                 Description   = 'Interview invite text',
                TR1__Send_Out_Schedule_V2__c = sendOut.Id
            ));
        }

        Test.startTest();
        insert events;
        Test.stopTest();

        // Validate all events updated correctly
        for (Event ev : [
            SELECT Id, Description
            FROM Event 
            WHERE Id IN :events
        ]) {
            System.assertEquals(sendOut.Email_Message__c, ev.Description, 'Description set correctly in bulk');
  
        }
    }
}