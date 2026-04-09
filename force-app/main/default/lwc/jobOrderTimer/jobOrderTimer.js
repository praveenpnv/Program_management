import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import extendJob from '@salesforce/apex/JobOrderController.extendJob';
import getExtensionOptions from '@salesforce/apex/JobOrderController.getExtensionOptions';
import canExtendJob from '@salesforce/customPermission/Assign_a_job';

const FIELDS = [
    'TR1__Job__c.Job_Expiry_Date__c',
    'TR1__Job__c.CreatedDate',
    'TR1__Job__c.TR1__Status__c',
    'TR1__Job__c.Has_Been_Extended__c',
    'TR1__Job__c.Responsible_Recruiter__c',
    'TR1__Job__c.TR1__Closed_Reason__c' // Added to check for 'Closed Expired' reason
];

export default class JobOrderTimer extends LightningElement {
    @api recordId;
    @track remainingTime;
    @track showExtendButton = false;
    //@track hasBeenExtended;
    @track selectedDays;

    @track isSingleOption = false;
    @track singleOptionLabel;
    @api isDashboard;


    timerClass = 'timer';
    isShowTimer;
    jobExpiryDate;
    timerInterval;
    timeoutId;

    @track extensionOptions = [];
    JobStatus;
    ClosedReason;

    get isMultipleOptions() {
    return this.extensionOptions.length > 1;
    }

    get singleOptionLabel() {
        return this.extensionOptions.length ? this.extensionOptions[0].label : '';
    }


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    jobOrder({ error, data }) {
        if (data) {
            this.isShowTimer = false;
            const jobExpiryDate = data.fields.Job_Expiry_Date__c.value;
            const createdDate = data.fields.CreatedDate.value;
            this.JobStatus = data.fields?.TR1__Status__c?.value;
            this.ClosedReason = data.fields?.TR1__Closed_Reason__c?.value;
            //this.hasBeenExtended = data.fields.Has_Been_Extended__c.value;
 
            let expiryDate;
            if (jobExpiryDate) {
                expiryDate = new Date(jobExpiryDate);
            } else {
                const createdDateObj = new Date(createdDate);
                createdDateObj.setDate(createdDateObj.getDate() + 15);
                expiryDate = createdDateObj;
            }
 
            const isAcceptingCandidates = this.JobStatus === 'Accepting Candidates';
            const isClosedExpired = this.JobStatus === 'Closed' && this.ClosedReason === 'Closed Expired';
            const hasRecruiter = data.fields?.Responsible_Recruiter__c?.value;
 
            this.isShowTimer = (isAcceptingCandidates || isClosedExpired || this.JobStatus === 'Closed Expired') && hasRecruiter;
 
            this.startTimer(expiryDate);
            getRecordNotifyChange([{ recordId: this.recordId }]);
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading job order',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    connectedCallback() {
        if (!this.recordId) {
            console.warn('Job Id not provided');
            return;
        }

        getExtensionOptions({ jobId: this.recordId })
            .then((result) => {
                 console.warn('result->', result);
                if (result && result.length > 0) {
                this.extensionOptions = result.map(day => {
                    return { value: day, label: `${day} Days` };
                });

                    if (this.extensionOptions.length === 1) {
                        this.isSingleOption = true;
                        this.singleOptionLabel = `Extend by ${this.extensionOptions[0].label}`;
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching extension options:', error);
            });
    }


    startTimer(expirationDate) {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
        }
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
        }
        const endTime = new Date(expirationDate);
        this.updateTime(endTime);
        this.timerInterval = setInterval(() => this.updateTime(endTime), 1000);
    }

    updateTime(endTime) {
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
        }

        const now = new Date();
        const distance = endTime - now;

        if (distance < 0) {  
            // Timer has expired
            clearInterval(this.timerInterval);
            this.timerClass = this.isDashboard ? 'dashboard-timer-red' : 'timer red';
            this.remainingTime = 'Closed - Expired';
            this.showExtendButton = canExtendJob && (this.extensionOptions.length > 0);
            // Do not hide the timer component itself, just update the text
            return;
        }

        const days = Math.floor(distance / (1000 * 60 * 60 * 24));
        const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((distance % (1000 * 60)) / 1000);

        this.remainingTime = `${days}d ${hours}h ${minutes}m ${seconds}s Left`;

        const isAcceptingCandidates = this.JobStatus === 'Accepting Candidates';
        const isClosedExpired = (this.JobStatus === 'Closed' || this.JobStatus === 'Closed Expired') && this.ClosedReason === 'Closed Expired';

        // console.log('distance->', distance); console.log('isAcceptingCandidates->',isAcceptingCandidates); console.log('isClosedExpired->',isClosedExpired);
        // Show extend button if within 3 days of expiry or already expired
        if (distance <= 72 * 60 * 60 * 1000 && isAcceptingCandidates) {
            this.timerClass = 'timer red';
            // Use custom permission to control visibility
            this.showExtendButton = canExtendJob && (this.extensionOptions.length > 0);
        } else if (isClosedExpired) {
            this.timerClass = 'timer red';
            this.remainingTime = 'Closed - Expired';
             this.showExtendButton = canExtendJob && (this.extensionOptions.length > 0);
        } else {
            this.timerClass = 'timer';
            this.showExtendButton = false;
        }

        if(this.isDashboard){
            this.timerClass = 'dashboard-timer';
        }

        this.timeoutId = setTimeout(() => this.updateTime(endTime), 1000);
    }

    handleExtendJob(event) {
        let selectedValue = this.selectedDays || event.detail.value;
        // If it's a single button, the value comes from the first option
        if(!selectedValue){
            selectedValue = this.extensionOptions[0].value;
        }
  
        // Hide the timer temporarily to give user feedback
        this.isShowTimer = false;

        extendJob({ jobId: this.recordId, selectedTime: selectedValue })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Job extended successfully',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Extending Job',
                        message: this.getErrorMessage(error),
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                console.log('error->',error);
                this.isShowTimer = true;
            });
    }

    getErrorMessage(error) {
        let message = 'An unknown error occurred.';
        if (error) {
            if (error.body && Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
                // Handle page-level errors
                message = error.body.pageErrors.map(e => e.message).join(', ');
            } else if (error.body && typeof error.body.fieldErrors === 'object') {
                // Handle field-level errors (from validation rules)
                const fieldErrors = Object.values(error.body.fieldErrors);
                if (fieldErrors.length > 0 && fieldErrors[0].length > 0) {
                    message = fieldErrors[0].map(e => e.message).join(', ');
                }
            } else if (error.body && typeof error.body.message === 'string') {
                // Handle generic AuraHandledException message
                message = error.body.message;
            }
        }
        return message;
    }
    
}