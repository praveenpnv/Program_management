import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getApplicantData from '@salesforce/apex/FieldSetUtility.getApplicantData';
import {
    FlowNavigationBackEvent,
    FlowNavigationNextEvent
} from "lightning/flowSupport";

export default class AtsMandatoryPopup extends LightningElement {
    @api objectApiName;
    @api fieldSetName;
    @api recordId;
    @api mode = 'edit';
    @api appStageName;
    @track fields = [];
    activeSection = ['A'];
    @track readonlyDependentFields = [];
    @track applicantId;
    @api unfilledMandatoryFields = [];
    @track showSpinner = false;
    hasRendered = false;
    allFieldsFilled;
    @track readonlyControllingFields = [];
    @track readOnlyFieldMap = {};

    objectInfo;

    connectedCallback() {
        this.generateFieldConfigs();
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
            this.generateFieldConfigs();
        }
        if (error) {
            console.error('Error getting object info:', error);
        }
    }

    fetchDependentFieldsMap() {
        if (!this.objectInfo || !this.objectInfo.fields) {
            console.warn('objectInfo.fields is undefined. Cannot fetch dependent fields.');
            this.readonlyDependentFields = [];
            return;
        }

        const controllingFields = new Set(this.unfilledMandatoryFields);
        const dependents = new Set();

        Object.entries(this.objectInfo.fields).forEach(([fieldApiName, fieldInfo]) => {
            const controllingField = fieldInfo.controllerName;
            if (controllingField && controllingFields.has(controllingField)) {
                dependents.add(fieldApiName);
                console.log(`Field "${fieldApiName}" is dependent on controlling field "${controllingField}"`);
            }
        });

        this.readonlyDependentFields = Array.from(dependents);
        console.log('Readonly dependent fields:', this.readonlyDependentFields);
    }

   @track readOnlyFieldMap = {};

generateFieldConfigs() {
    if (!this.unfilledMandatoryFields || !this.objectInfo || !this.objectInfo.fields) {
        this.fields = this.unfilledMandatoryFields || [];
        return;
    }

    const requiredFields = new Set(this.unfilledMandatoryFields);
    const controllingFields = new Set();

    Object.entries(this.objectInfo.fields).forEach(([fieldApiName, fieldInfo]) => {
        const controllingField = fieldInfo.controllerName;
        if (controllingField && requiredFields.has(fieldApiName)) {
            controllingFields.add(controllingField);
            if (!requiredFields.has(controllingField)) {
               // requiredFields.add(controllingField);
              this.readonlyControllingFields.push(controllingField);
            }
        }
    });

   // this.readonlyControllingFields = Array.from(controllingFields);
    this.fields = Array.from(requiredFields);

    // Build a lookup map
    /*this.readOnlyFieldMap = {};
    this.readonlyControllingFields.forEach(field => {
        this.readOnlyFieldMap[field] = true;
    });*/

    this.fetchDependentFieldsMap();
}

/*isReadOnly(fieldName) {
    return this.readonlyControllingFields.includes(fieldName);
}*/


    @api
    handleSubmit(event) {
        event.preventDefault();
        this.template.querySelectorAll('lightning-record-edit-form').forEach((form) => {
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
    }

    handleFlowNext() {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handleError(event) {
        const errorMessage = event.detail.message || 'An unexpected error occurred';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error',
                mode: 'sticky'
            })
        );
        console.log('Form submission error:', errorMessage);
    }
}