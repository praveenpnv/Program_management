import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue,updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import RefreshATS from "@salesforce/messageChannel/RefreshATS__c";

const FIELDS = ['TR1__Application_V2__c.RecordTypeId'];

// Import message service features required for subscribing and the message channel
import { subscribe, unsubscribe, publish,  MessageContext } from "lightning/messageService";


export default class AtsStageForm extends LightningElement {
    @api objectApiName; // Default object API name
    @api fieldSetName; // Default FieldSet name
    @api recordId; // Record Id if you want to edit an existing record
    @api appStage;
    @api appStageName;
    @api currentSubStage;
    @api isSaving =false;
    @api emailPageType='ATSValidation';
    @api fieldName = 'TR1__Application_V2__c.TR1__Stage__c';
    @api fieldAppStage = 'TR1__Stage__c';
    @api fieldAppSubStage = 'Substage__c';
    @track displayValue = '';
    @track recordTypeId;
    @api isReadOnly;
    
    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.recordTypeId = data.fields.RecordTypeId.value;
        } else if (error) {
            console.error('Error fetching record: ', error);
        }
    }

   @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$fieldName' })
    wiredPicklistValues({ error, data }) {
        if (data) {
           console.log('data'+JSON.stringify(data.values));
           console.log('this.appStage',this.appStage);
            const picklistValue = this.appStage;
            const picklistOption = data.values.find(option => option.value === picklistValue);
            if (picklistOption) {
                this.appStageName = picklistOption.label;
            }
        } else if (error) {
            console.error('Error fetching picklist values: ', error);
        }
    }

    get isSendOut()   {
        return this.appStage ==='Send Out'||this.appStage ==='Application';
    }
      get isApplication()   {
        return this.appStage ==='Application';
    }
 handleTaskSave()
 {

        this.template.querySelector('c-ats-comments').handleSaveDescription();
        
 }
handleFieldSetSave()
{
       this.template.querySelector('c-ats-field-set-form').handleSubmit();
}


handleStageChange(event) {
        this.currentSubStage = event.detail;
        console.log('Updated currentSubStage:', this.currentSubStage);
    }
 
 updateRecordStage() {
        const fields = {};
        fields.Id = this.recordId;
       // fields[this.fieldName] = this.appStage;
      fields[this.fieldAppStage] = this.appStage;
     fields[this.fieldAppSubStage] = this.currentSubStage;
        const recordInput = { fields };
        this.isSaving = true;
        updateRecord(recordInput)
            .then(() => {
                this.isSaving = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record updated successfully',
                        variant: 'success'
                    })
                );
                // Refresh ATS View
					publish(this.messageContext, RefreshATS, { recordId: this.recordId });  
            })
            .catch(error => {
    this.isSaving = false;
    console.error('Error updating record', JSON.stringify(error));

    let messages = [];

    // Field-level errors (including for related fields like ParentObject__r.Field__c)
    const fieldErrors = error?.body?.output?.fieldErrors;
    if (fieldErrors) {
        Object.entries(fieldErrors).forEach(([field, errors]) => {
            errors.forEach(err => {
                messages.push(`Field ${field}: ${err.message}`);
            });
        });
    }

    // Page-level (general) errors
    const pageErrors = error?.body?.output?.errors;
    if (pageErrors && Array.isArray(pageErrors)) {
        pageErrors.forEach(err => {
            messages.push(err.message);
        });
    }

    // Apex or unknown error fallback
    if (messages.length === 0) {
        messages.push(error?.body?.message ?? 'An unknown error occurred');
    }

    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error updating record',
            message: messages.join(' | '),
            variant: 'error'
        })
    );
});

    }

// Open Rejection Modal
    openRejectionModal() {
        const rejectPayload = {
            Action: "REJECT_TALENT",
            Button: "REJECT_TALENT"
        };

        publish(this.messageContext, RefreshATS, rejectPayload);
    }

    handleSaveResponse()

{
       const stageQestion = this.template.querySelector('c-ats-stage-question');
       this.isSaving = true;
    stageQestion.saveResponses();
       stageQestion.addEventListener('responsesuccess', () => {
        this.updateRecordStage(); // Update the record stage after field set form save success
    });

    // Listen for task errors
    stageQestion.addEventListener('taskerror', (event) => {
        this.isSaving = false;
        this.showToast('responseerror', event.detail.message, 'error');
    });

}
handleSaveAll() {

    console.log('save alll');

    const taskManager = this.template.querySelector('c-ats-comments');
    const fieldSetForm = this.template.querySelector('c-ats-field-set-form');
 

    

    // Listen for task save success
    taskManager.addEventListener('tasksuccess', () => {
               

       // fieldSetForm.handleSubmit(); // Submit the field set form after task save success
    });

    // Handle field set success, and proceed to update the record
    fieldSetForm.addEventListener('success', () => {
            this.isSaving = true;

        (this.isApplication)?this.handleSaveResponse():this.updateRecordStage(); // Update the record stage after field set form save success
    });

    // Listen for task errors
    /*taskManager.addEventListener('taskerror', (event) => {
               this.isSaving = false;

        this.showToast('Error', event.detail.message, 'error');
    });*/

    // Listen for field set errors
    fieldSetForm.addEventListener('error', (event) => {
        console.log('error');
               this.isSaving = false;

        this.showToast('Error', event.detail.message, 'error');
    });

    // Start the save process by calling task save
          //this.isSaving = true;

    //taskManager.handleSaveDescription();
    fieldSetForm.handleSubmit();
}

}