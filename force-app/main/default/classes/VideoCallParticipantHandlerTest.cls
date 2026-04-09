/**
* @File Name : VideoCallParticipantHandlerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 8, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 8, 2025 |   | Initial Version
**/

@isTest
public class VideoCallParticipantHandlerTest {
    
    @testSetup
    static void setupData() {

        // Create a VideoCall
        VideoCall vc = new VideoCall(
            //Subject = 'Interview Call',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            VendorMeetingKey='djsnbvdsklcdksmcdlscl',
            Name='Test'
        );
        insert vc;

        // Create a Send Out Schedule (to be updated later)
         Contact interviewee = RD1TestDataFactory.createCandidate();
        // Create Job
        Account acc = RD1TestDataFactory.createTestAccount();
        Contact interviewee1 = RD1TestDataFactory.createTestContact(acc.Id,'Client');
        TR1__Job__c job = RD1TestDataFactory.createTestJob(acc.Id, interviewee1.Id);
        

        // Create Application
        TR1__Application_V2__c application = RD1TestDataFactory.createApplication(interviewee.Id, job.Id, 'Consulting');

        // Create Users (inside runAs to avoid Mixed DML)
        System.runAs(new User(Id = UserInfo.getUserId())) {
            User interviewer  = RD1TestDataFactory.createUser('int1', 'Interviewer1', 'US');
            insert interviewer;
            
        }

        // Create SendOut
        TR1__Send_Out_Schedule_V2__c sendOut = new TR1__Send_Out_Schedule_V2__c(
            Email_Message__c = 'Interview invite text',
            //TR1__Interviewers_Ids__c = interviewer.Id,
            TR1__Interviewee__c = interviewee.Id,
            TR1__Application_V2__c=application.Id
        );
        insert sendOut;


        // Create an Event that overlaps VideoCall timing
        Event ev = new Event(
            Subject = 'Interview Event',
            StartDateTime = vc.StartDateTime,
            EndDateTime = vc.EndDateTime,
            WhatId = sendOut.Id
            //OwnerId = interviewer.Id
        );
        insert ev;

    }
    
    @isTest
    static void testAfterInsertUpdateHandler() {
        // Fetch test data
        VideoCall vc = [SELECT Id FROM VideoCall LIMIT 1];
        User interviewer = [SELECT Id FROM User WHERE Alias = 'aduser' LIMIT 1];

        // Insert VideoCallParticipant -> should trigger handler
        VideoCallParticipant vcp = new VideoCallParticipant(
            VideoCallId = vc.Id,
            RelatedPersonId = interviewer.Id
        );
        insert vcp;

        // Re-query SendOut to check update
        TR1__Send_Out_Schedule_V2__c sendOut = [
            SELECT Id, VideoCallid__c
            FROM TR1__Send_Out_Schedule_V2__c
            LIMIT 1
        ];
        //System.assertEquals(vc.Id, sendOut.VideoCallid__c,'SendOut should be updated with VideoCallId');

        // Verify VideoCallShare was created
        List<VideoCallShare> shares = [
            SELECT Id, ParentId, UserOrGroupId, AccessLevel
            FROM VideoCallShare
            WHERE ParentId = :vc.Id
        ];
        System.assert(!shares.isEmpty(), 'VideoCallShare should be inserted');
        //System.assertEquals('Read', shares[0].AccessLevel, 'Access should be Read');
    }
}