import { LightningElement, api, wire, track } from 'lwc';
import getFieldSetFields from '@salesforce/apex/FieldSetController.getFieldSetFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {FlowNavigationFinishEvent} from "lightning/flowSupport";

export default class FieldSetForm extends LightningElement {
    @api objectApiName = 'Account'; // Default object API name
    @api fieldSetName = 'MyFieldSet'; // Default FieldSet name
    @api recordId; // Record Id if you want to edit an existing record
    @api mode = 'edit'; // Edit mode by default
    @api appStageName;
    @track fieldNames;
    @track fields = [];
    @api isReadOnly;
    activeSection = ['A']; 

    @wire(getFieldSetFields, { objectName: '$objectApiName', fieldSetName: '$fieldSetName' })
    wiredFields({ error, data }) {
        if (data) {
            this.fieldNames = data;
            this.generateFieldConfigs();
        } else if (error) {
            console.error('Error retrieving field names:', error);
        }
    }

   generateFieldConfigs() {
    if (this.fieldNames && Array.isArray(this.fieldNames)) {
        this.fields = this.fieldNames.map(f => ({
            fieldPath: f.fieldPath,
            required: f.required
        }));
    }
}



  @api
    handleSubmit(event) {
        // Handle form submission if needed

        try {
        let isValid = true;

    this.template.querySelectorAll('lightning-input-field')
        .forEach((inputCmp) => {
            if (!inputCmp.reportValidity()) {
                isValid = false;
            }
        });

    if (isValid) {
        this.template
            .querySelectorAll('lightning-record-edit-form')
            .forEach((form) => {
                form.submit();
            });
    }
        }
        catch(error){

        const event = new CustomEvent('error', { detail: { message: 'required fields missing' } });
        this.dispatchEvent(event); // Dispatch 'error' event
    
        }
    }
    handleFlowFinish(){
      const navigateNextEvent = new FlowNavigationFinishEvent();
      this.dispatchEvent(navigateNextEvent);
    }

    handleSuccess(event) {
        setTimeout(() => {
            this.handleFlowFinish();
        }, 1000);   
         
        const fieldSetEvent = new CustomEvent('success', { detail: { message: 'FieldSet updated successfully!' } });
       // this.dispatchEvent(fieldSetEvent); // Dispatch 'tasksuccess' event
    }

    handleError(event) {
        // Handle form error if needed
        const toastEvent = new ShowToastEvent({
            message: `Error saving record: ${event.detail.message}`,
            title: 'Error',
            variant: 'error'
        });
        this.dispatchEvent(toastEvent);
    }
}