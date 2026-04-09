import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMandatoryFields from '@salesforce/apex/FieldSetUtility.getOpportunityMandatoryFields';

import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import JOB_OBJECT from '@salesforce/schema/TR1__Job__c';
import SERVICE_LINE_FIELD from '@salesforce/schema/Opportunity.Service_Line__c';
import SUB_SERVICE_LINE_FIELD from '@salesforce/schema/Opportunity.Sub_Service_Line__c';
import SERVICE_LINE_JOB_FIELD from '@salesforce/schema/TR1__Job__c.Service_line_job__c';
import SUB_SERVICE_LINE_JOB_FIELD from '@salesforce/schema/TR1__Job__c.Sub_service_line_job__c';

export default class StandardDependentPicklist extends LightningElement {
    @api recordId;

    @track controllingPicklistOptions = [];
    @track dependentPicklistOptions = [];
    @track selectedControllingValues = [];
    @track selectedDependentValues = [];
    @track error;
    @track showValidationPopup = false;
    @track validationFields = []; // Field names that failed validation
    @track mandatoryFieldsData = []; // Field names from fieldset
    @track hasEditAccess = false;
    @track permissionsLoaded = false;

    originalControllingValues = [];
    originalDependentValues = [];
    controllerValuesMap = {};
    allDependentRawValues = [];
    isUiReady = false;
    @track isEditMode = false;

    loaders = {
        opportunityPicklist: false,
        jobPicklist: false,
        recordData: false,
        permissions: false
    };

    handleEditClick() {
        if (!this.hasEditAccess) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Access Denied',
                message: 'You do not have permission to edit this record',
                variant: 'warning'
            }));
            return;
        }
        this.isEditMode = true;
    }

    handleCancel() {
        this.isEditMode = false;
        // Reset values to original
        this.selectedControllingValues = [...this.originalControllingValues];
        this.selectedDependentValues = [...this.originalDependentValues];
    }

    get isEditFlag() {
        // Don't show modal if user doesn't have edit access
        if (!this.hasEditAccess) {
            return false;
        }
        
        // Show modal if in edit mode
        if (this.isEditMode) {
            return true;
        }
        
        // Check if original values are empty or null - if so, show modal automatically
        const hasControllingValues = this.originalControllingValues && this.originalControllingValues.length > 0;
        const hasDependentValues = this.originalDependentValues && this.originalDependentValues.length > 0;
        
        // Show modal if either service line or sub service line is not set
        return !hasControllingValues || !hasDependentValues;
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    oppInfoHandler({ data, error }) {
        if (data) {
            this.oppRecordTypeId = data.defaultRecordTypeId;
            
            // Check edit permissions
            const serviceLineField = data.fields[SERVICE_LINE_FIELD.fieldApiName];
            const subServiceLineField = data.fields[SUB_SERVICE_LINE_FIELD.fieldApiName];
            
            this.hasEditAccess = data.updateable && 
                               serviceLineField?.updateable && 
                               subServiceLineField?.updateable;
                               
            this.loaders.permissions = true;
        } else if (error) {
            this.handleError('Error loading Opportunity metadata', error);
            this.loaders.permissions = true;
        }
        this.loaders.opportunityPicklist = true;
        this.checkAllDataLoaded();
    }

    @wire(getObjectInfo, { objectApiName: JOB_OBJECT })
    jobObjectInfo;

    @wire(getPicklistValuesByRecordType, { objectApiName: OPPORTUNITY_OBJECT, recordTypeId: '$oppRecordTypeId' })
    oppPicklistHandler({ data, error }) {
        if (data) {
            const controllingField = SERVICE_LINE_FIELD.fieldApiName;
            if(controllingField){ this.controllingPicklistOptions = data.picklistFieldValues[controllingField].values;}
        } else if (error) {
            this.handleError('Error loading Opportunity Service Line picklist', error);
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: JOB_OBJECT, recordTypeId: '$jobObjectInfo.data.defaultRecordTypeId' })
    jobPicklistHandler({ data, error }) {
        if (data) {
            const depField = SUB_SERVICE_LINE_JOB_FIELD.fieldApiName;
            const controllingMap = data.picklistFieldValues[depField].controllerValues;
            const depValues = data.picklistFieldValues[depField].values;

            this.controllerValuesMap = controllingMap;
            this.allDependentRawValues = depValues;

            if (this.selectedControllingValues.length > 0) {
                this.updateDependentOptions();
            }
        } else if (error) {
            this.handleError('Error loading Job picklist data', error);
        }
        this.loaders.jobPicklist = true;
        this.checkAllDataLoaded();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SERVICE_LINE_FIELD, SUB_SERVICE_LINE_FIELD] })
    recordHandler({ data, error }) {
        if (data) {
            const controllingStr = getFieldValue(data, SERVICE_LINE_FIELD);
            const dependentStr = getFieldValue(data, SUB_SERVICE_LINE_FIELD);

            this.selectedControllingValues = controllingStr ? controllingStr.split(';') : [];
            this.selectedDependentValues = dependentStr ? dependentStr.split(';') : [];

            this.originalControllingValues = [...this.selectedControllingValues];
            this.originalDependentValues = [...this.selectedDependentValues];
        } else if (error) {
            this.handleError('Error loading Opportunity record', error);
        }
        this.loaders.recordData = true;
        this.checkAllDataLoaded();
    }

    updateDependentOptions() {
        if (!this.selectedControllingValues || this.selectedControllingValues.length === 0) {
            this.dependentPicklistOptions = [];
            return;
        }

        const controllingIndexes = this.selectedControllingValues
            .map(value => this.controllerValuesMap[value])
            .filter(idx => idx !== undefined);

        const filtered = this.allDependentRawValues.filter(item =>
            item.validFor.some(index => controllingIndexes.includes(index))
        );

        this.dependentPicklistOptions = filtered.map(item => ({ label: item.label, value: item.value }));

        const validValues = this.dependentPicklistOptions.map(opt => opt.value);
        this.selectedDependentValues = this.selectedDependentValues.filter(val => validValues.includes(val));
    }

    checkAllDataLoaded() {
        const allDone = Object.values(this.loaders).every(v => v);
        if (this.isUiReady || !allDone) return;
        this.isUiReady = true;
        this.permissionsLoaded = true;
    }

    handleControllingChange(event) {
        this.selectedControllingValues = event.detail.value;
        this.updateDependentOptions();
    }

    handleDependentChange(event) {
        this.selectedDependentValues = event.detail.value;
    }

    handleSave() {
        const fields = {
            Id: this.recordId,
            [SERVICE_LINE_FIELD.fieldApiName]: this.selectedControllingValues.join(';'),
            [SUB_SERVICE_LINE_FIELD.fieldApiName]: this.selectedDependentValues.join(';')
        };

        updateRecord({ fields })
            .then(() => {
                this.originalControllingValues = [...this.selectedControllingValues];
                this.originalDependentValues = [...this.selectedDependentValues];
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Record updated successfully',
                    variant: 'success'
                }));
                this.isEditMode = false;
            })
            .catch(error => {
                this.handleValidationError(error);
            });
    }

    handleValidationError(error) {
        let isValidationError = false;
        
        if (error.body) {
            console.log('Error body:', JSON.stringify(error.body, null, 2));
            
            // Check various validation error patterns
            isValidationError = 
                error.body.message?.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ||
                error.body.message?.includes('REQUIRED_FIELD_MISSING') ||
                error.body.message?.includes('FIELD_FILTER_VALIDATION_EXCEPTION') ||
                error.body.message?.includes('DUPLICATE_VALUE') ||
                error.body.message?.includes('VALIDATION_FORMULA') ||
                error.body.fieldErrors ||
                error.body.pageErrors ||
                (error.body.output && error.body.output.fieldErrors) ||
                (error.body.output && error.body.output.errors) ||
                error.body.enhancedErrorType === 'RecordError' ||
                (Array.isArray(error.body) && error.body.some(e => e.errorCode));
        }
        
        // Additional fallback checks
        if (!isValidationError) {
            isValidationError = 
                error.message?.includes('validation') ||
                error.message?.includes('required') ||
                error.message?.includes('REQUIRED_FIELD_MISSING') ||
                error.statusText === 'Bad Request';
        }
        if (isValidationError) {
            console.log('Processing validation error');
            this.fetchMandatoryFields();
        } else {
            console.log('Processing as regular error');
            this.handleError('Error updating record', error);
        }
    }

    // Fetch mandatory fields from fieldset
    fetchMandatoryFields() {
        getMandatoryFields({ 
            recordId: this.recordId, 
            objectName: 'Opportunity', 
            fieldSetName: 'Opportunity_Manadatory_Fields' 
        })
        .then(result => {
            console.log('Mandatory fields result:', result);
            
            if (result && result.unfilledMandatoryFields) {
                // Now result.unfilledMandatoryFields is a List<String>, not List<FieldInfo>
                this.mandatoryFieldsData = result.unfilledMandatoryFields; // This is now an array of field names
                this.validationFields = result.unfilledMandatoryFields; // Same array of field names
                this.showValidationPopup = true;
            } else {
                console.log('No mandatory fields found or all fields are filled');
                this.handleError('Error updating record', 'Validation failed but no mandatory fields found');
            }
        })
        .catch(error => {
            console.error('Error fetching mandatory fields:', error);
            this.handleError('Error fetching validation fields', error);
        });
    }

    handleValidationPopupClose() {
        this.showValidationPopup = false;
        this.validationFields = [];
        this.mandatoryFieldsData = [];
    }

    handleValidationFormSuccess(event) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Validation fields updated successfully',
            variant: 'success'
        }));
        this.showValidationPopup = false;
        this.validationFields = [];
        this.mandatoryFieldsData = [];
        this.isEditMode = false;
    }

    handleValidationFormError(event) {
        const errorMessage = event.detail.message || 'An unexpected error occurred';
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
            mode: 'sticky'
        }));
        console.log('Validation form submission error:', errorMessage);
    }

    handleError(title, error) {
        console.error(title, error);
        const msg = error.body?.message || error.message || 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({
            title,
            message: msg,
            variant: 'error'
        }));
    }

    get isDependentOptionsAvailable() {
        return this.dependentPicklistOptions.length > 0;
    }

    get showContent() {
        return this.isUiReady && !this.error && this.permissionsLoaded;
    }

    get showLoadingSpinner() {
        return (!this.isUiReady || !this.permissionsLoaded) && !this.error;
    }

    get hasSelectedControllingValues() {
        return this.selectedControllingValues.length > 0;
    }

    get isControllingOptionsAvailable() {
        return this.controllingPicklistOptions.length > 0;
    }

    get selectedControllingValuesDisplay() {
        return this.selectedControllingValues && this.selectedControllingValues.length > 0 ?
            this.selectedControllingValues.map(val => {
                const match = this.controllingPicklistOptions.find(opt => opt.value === val);
                return match ? match.label : val;
            }).join(', ') : 'None';
    }

    get selectedDependentValuesDisplay() {
        return this.selectedDependentValues && this.selectedDependentValues.length > 0 ?
            this.selectedDependentValues.map(val => {
                const match = this.dependentPicklistOptions.find(opt => opt.value === val);
                return match ? match.label : val;
            }).join(', ') : 'None';
    }
}