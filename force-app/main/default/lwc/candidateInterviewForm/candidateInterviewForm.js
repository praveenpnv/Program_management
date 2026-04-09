import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// The field API names from Candidate__c object
const CANDIDATE_FIELDS = [
    'Contact.Primary_Interview_Taker__c',
    'Contact.Date_of_the_First_Interview__c',
    'Contact.Secondary_Interview_Taker__c',
    'Contact.Date_of_the_Second_Interview__c',
    'Contact.Job_Expert__c',
    'Contact.Date_of_the_Technical_Interview__c'
];

export default class CandidateInterviewForm extends LightningElement {
    @api applicationId; // This is the Application__c record id which is passed as a property
    candidateId;

    @api interviewRound;

    get showPrimaryInterview() {
        return this.interviewRound === 'Interview 1';
    }
    
    get showSecondaryInterview() {
        return this.interviewRound === 'Interview 2';
    }

    get showJobExpertInterview() {
        return this.interviewRound === 'Interview 3';
    }


    // Wire the getRecord to fetch candidate based on the application relationship
    @wire(getRecord, { recordId: '$applicationId', fields: ['TR1__Application_V2__c.TR1__Applicant__c'] })
    wiredApplication({ error, data }) {
        if (data) {
            this.candidateId = data.fields.TR1__Applicant__c.value; // Fetch Candidate Id from Application
            console.log('candidate Id'+this.candidateId);
        } else if (error) {
            console.error(error);
        }
    }

    // Wire candidate record data using the fetched candidateId
    @wire(getRecord, { recordId: '$candidateId', fields: CANDIDATE_FIELDS })
    candidate;
}