import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApplicantData from '@salesforce/apex/FieldSetUtility.getApplicantData';
import {
  FlowNavigationBackEvent,
  FlowNavigationNextEvent
} from "lightning/flowSupport";

export default class AtsMandatoryPopup extends LightningElement {
    @api objectApiName; // Default object API name
    @api fieldSetName; // Default FieldSet name
    @api recordId; // Record Id if you want to edit an existing record
    @api mode = 'edit'; // Edit mode by default
    @api appStageName;
    @track fieldNames;
    @track fields = [];
    activeSection = ['A']; 
    @track applicantId;
    @track unfilledMandatoryFields;
    @track showSpinner = true;
    hasRendered = false;
    allFieldsFilled;


    disconnectedCallback() {
        refreshApex(this.wiredApplicantDataResult);
    }

    renderedCallback(){
       if (!this.hasRendered) {
            this.hasRendered = true; // Ensure refreshApex is only called once
            refreshApex(this.wiredApplicantDataResult);
        }
    }
    
    @wire(getApplicantData, { applicationId: '$recordId', objectName: '$objectApiName', fieldSetName: '$fieldSetName' })
    wiredApplicantData(result) {
        this.wiredApplicantDataResult = result; // Store the wired result for refresh
        const { data, error } = result;
        
        if (data) {
            console.log('Applicant Data:', data); // For debugging
            this.showSpinner = false;
            this.applicantId = data.applicantId;
            this.unfilledMandatoryFields = data.unfilledMandatoryFields;
            this.allFieldsFilled = data.allFieldsFilled;
            
            if(this.allFieldsFilled){
                  this.handleFlowNext();
            }
            
            this.generateFieldConfigs();
        } else if (error) {
            this.showSpinner = false;
            console.error('Error fetching applicant data:', error);
        }
    }

    generateFieldConfigs() {
        this.fields = this.unfilledMandatoryFields;
    }

    @api
    handleSubmit(event) {
          event.preventDefault();
        // Handle form submission if needed
        this.template
            .querySelectorAll('lightning-record-edit-form')
            .forEach((form) => {
                form.submit();
            });
    }

    handleSuccess(event) {
        const toastEvent = new ShowToastEvent({
            message: 'Saved Successfully',
            title: 'Success',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);
        this.handleFlowNext();
        refreshApex(this.wiredApplicantDataResult);
    }
    
    handleFlowNext(){
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    }

    handleError(event) {
         const errorMessage = event.detail.message || 'An unexpected error occurred';
        // Show a toast notification with the error message
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error',
                mode: 'sticky'
            })
        );

        // Additional error handling logic can go here if needed
        console.log('Form submission error:', errorMessage);
    }
}