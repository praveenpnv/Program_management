import { LightningElement, api, track,wire } from 'lwc';
import getFieldSetFields from '@salesforce/apex/OpportunityLIcontroller.getFieldSetFields';
import getDefaultLineItemValue from '@salesforce/apex/OpportunityLIcontroller.getDefaultLineItemValues';
import assignStandardPricebook from '@salesforce/apex/OpportunityLIcontroller.assignStandardPricebook';
import getOpportunityFields from '@salesforce/apex/OpportunityLIcontroller.getOpportunityFields';
import getJobTypePicklistValues from '@salesforce/apex/OpportunityLIcontroller.getJobTypePicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import JOB_TYPE_FIELD from '@salesforce/schema/OpportunityLineItem.Job_Type__c';
import OPP_SL_FIELD from '@salesforce/schema/OpportunityLineItem.Service_Line__c';
import OPP_SSL_FIELD from '@salesforce/schema/OpportunityLineItem.Sub_Service_Line__c';
import SoW from '@salesforce/label/c.SoW';
import Solutions from '@salesforce/label/c.Solutions';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import JOB_OBJECT from '@salesforce/schema/TR1__Job__c';
import OPP_OBJECT from '@salesforce/schema/Opportunity';

export default class OpportunityLineItemLauncher extends LightningElement {
    @api recordId; // Opportunity ID
    fields = [];
    pricebookEntryId;
    salesPrice;
    quantity;
    stageName;
    isModalOpen = false;
    isAddJobDisabled = false;
    @track isLoading = false;
    oliJobType;
    opportunityRecordName;
    jobTypeOptions = [];
    isJobType = false;
    isServiceLine = false;
    showField = true;
    oppServiceLine;
    oppServiceLineOptions = [];
    oppSubServiceLine;
    oppSubServiceLineOptions = [];
    jobTypeFieldName = JOB_TYPE_FIELD;
    serviceLineFieldName = OPP_SL_FIELD;
    subServiceLineFieldName = OPP_SSL_FIELD;
    jobFunctionId;
    jobInfo;
    oppInfo;
    @track hideFormMessages = false;



    connectedCallback() {
        this.checkOpportunityStage();
        this.initialize();
    }
    async checkOpportunityStage() {
        try {
            const opp = await getOpportunityFields({ opportunityId: this.recordId });
            this.stageName = opp.StageName;
            this.opportunityRecordName = opp.RecordType.Name;
            if (opp.IsClosed) {
                this.isAddJobDisabled = true;
            }

            if (this.opportunityRecordName == SoW) {
                this.oppServiceLine = opp.Service_Line__c;
                this.oppSubServiceLine = opp.Sub_Service_Line__c;
                if (this.oppServiceLine) {
                    this.oppServiceLineOptions = this.oppServiceLine.split(';').map(option => {
                        const trimmedOption = option.trim();
                        return { label: trimmedOption, value: trimmedOption };
                    });
                }
                if (this.oppSubServiceLine) {
                    this.oppSubServiceLineOptions = this.oppSubServiceLine.split(';').map(option => {
                        const trimmedOption = option.trim();
                        return { label: trimmedOption, value: trimmedOption };
                    });
                }
            }

            // Always fetch job type values to set up the options
            this.fetchJobTypePicklistValues();
        } catch (error) {
            console.error('Error fetching Opportunity stage:', error);
        }
    }

     @wire(getObjectInfo, { objectApiName: JOB_OBJECT })
    wiredJobInfo({ error, data }) {
        if (data) {
            this.jobInfo = data;
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }

   get isJobCreateable() {
        return!(this.jobInfo ? this.jobInfo.createable : false) || this.isAddJobDisabled;
        
    }

    @wire(getObjectInfo, { objectApiName: OPP_OBJECT })
    wiredOppInfo({ error, data }) {
        if (data) {
            this.oppInfo = data;
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }

    get isOppCreateable() {
        return this.isAddJobDisabled ||
        !(this.jobInfo ? this.jobInfo.createable : false) ||
        !(this.oppInfo ? this.oppInfo.createable : false);
        
    }

    async initialize() {
        try {
            await this.ensurePricebook(); // must complete before loading defaults
            await this.loadFields();
            await this.loadDefaults();
        } catch (error) {
            console.error('Initialization error:', error);
        }
    }

    async loadFields() {
        try {
            const fs = await getFieldSetFields({ fieldSetName: 'LineItem_Field' });
            if (!fs || !Array.isArray(fs)) {
                console.error('Invalid field set response:', fs);
                return;
            }
            this.fields = fs.map(field => {
                switch (field.fieldName) {
                    case 'Job_Type__c':

                        this.jobTypeFieldName = field.fieldName;
                        return { ...field, isJobType: true, isRequired: true };

                    case 'Service_Line__c':
                        if (this.opportunityRecordName === SoW) {
                            this.serviceLineFieldName = field.fieldName;
                            return { ...field, isServiceLine: true, isRequired: true };
                        }
                        else { return { ...field, isJobType: false, isServiceLine: false, isSubServiceLine: false, showField: true }; }

                    case 'Sub_Service_Line__c':
                        if (this.opportunityRecordName === SoW) {
                            this.subServiceLineFieldName = field.fieldName;
                            return { ...field, isSubServiceLine: true, isRequired: true };
                        }
                        else { return { ...field, isJobType: false, isServiceLine: false, isSubServiceLine: false, showField: true }; }

                    default:
                        return { ...field, isJobType: false, isServiceLine: false, isSubServiceLine: false, showField: true };
                }
            });
            console.log('Loaded Fields:', JSON.stringify(this.fields));
        } catch (error) {
            console.error('Error loading fields:', error?.body?.message || error.message || JSON.stringify(error));
        }
    }

    async ensurePricebook() {
        try {
            await assignStandardPricebook({ opportunityId: this.recordId });
        } catch (error) {
            const message = error.body?.message || error.message || 'Unexpected error occurred.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Assigning Pricebook',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            throw new Error(message);
        }
    }

    async loadDefaults() {
        try {
            const defaults = await getDefaultLineItemValue({ opportunityId: this.recordId });
            this.pricebookEntryId = defaults.pricebookEntryId;
            this.salesPrice = defaults.salesPrice;
            this.quantity = defaults.quantity;
            console.log('defaults' + JSON.stringify(defaults));
        } catch (error) {
            const message = error.body?.message || error.message || 'Unexpected error occurred.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cannot Create Line Item',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            console.error('Error loading default values:', error);
        }
    }

    async fetchJobTypePicklistValues() {
        try {
            const data = await getJobTypePicklistValues();
            if (data) {
                this.oliJobTypeOptions = data.map(option => {
                    return { label: option.label, value: option.value };
                });
                if (this.oliJobTypeOptions.length > 0) {
                    if (this.opportunityRecordName == SoW) {
                        this.jobTypeOptions = this.oliJobTypeOptions.filter(option =>
                            option.value === Solutions || option.label === Solutions
                        );
                        this.oliJobType = Solutions;
                    } else {
                        this.jobTypeOptions = this.oliJobTypeOptions.filter(option =>
                            option.value !== Solutions && option.label !== Solutions
                        );
                        this.oliJobType = this.jobTypeOptions.length > 0 ? this.jobTypeOptions[0].value : null;
                    }
                }
            }
        } catch (error) {
            console.error('Error fetching job type picklist values:', error);
            // Handle error appropriately
        }
    }

    // Handle Job Type combobox change
    handleJobTypeChange(event) {
        this.oliJobType = event.detail.value;
    }
    handleServiceLineChange(event) {
        this.oppServiceLine = event.detail.value;
    }
    handleSubServiceLineChange(event) {
        this.oppSubServiceLine = event.detail.value;
    }

    handleJobFunctionChange(event) {
        this.jobFunctionId = event.detail.recordId;
        console.log(' this.jobFunctionId' + this.jobFunctionId);  // Id of selected Job Function record
    }

    openModal() {
        this.isModalOpen = true;
    }

    openCreateJobModal() {
        this.template.querySelector('c-opportunity-line-item-table').openModal();
    }

    closeModal() {
        this.isModalOpen = false;
    }
    handleSubmit(event) {
        event.preventDefault();
        const jobFunctionPicker = this.template.querySelector('lightning-record-picker');
    if (!jobFunctionPicker.checkValidity()) {
        jobFunctionPicker.reportValidity();
        this.isLoading = false;
        return; // stop submit if invalid
    }
        this.isLoading = true;
        const formFields = event.detail.fields;
        if (this.oliJobType && this.jobTypeFieldName) {
            formFields[this.jobTypeFieldName] = this.oliJobType;
        }
        if (this.oppServiceLine && this.serviceLineFieldName) {
            formFields[this.serviceLineFieldName] = this.oppServiceLine;
        }
        if (this.oppSubServiceLine && this.subServiceLineFieldName) {
            formFields[this.subServiceLineFieldName] = this.oppSubServiceLine;
        }
        if (this.jobFunctionId) {
            formFields['Job_Function__c'] = this.jobFunctionId;
            console.log('this.jonFunctionName' + this.jonFunctionName);
        }

        this.template.querySelector('lightning-record-edit-form').submit(formFields);
    }

    handleError(event) {
        this.isLoading = false;
        event.preventDefault();
        const fieldErrors = event.detail?.output?.fieldErrors || {};
        console.log('fieldErrors'+JSON.stringify(fieldErrors));
    
        let customErrorMessage = '';
        let isPicklistMismatchError = false;
        if (fieldErrors[this.subServiceLineFieldName] && 
            fieldErrors[this.subServiceLineFieldName].some(error => 
                error.message && error.message.includes('bad value for restricted picklist'))) {
                customErrorMessage = 'Sub Service Line does not match the selected Service Line.';
                isPicklistMismatchError = true;
        }
        if (isPicklistMismatchError) {
        this.hideFormMessages = true;
        setTimeout(() => {
            this.hideFormMessages = false;
        });
        
        this.dispatchEvent(new ShowToastEvent({
            title: 'Validation Error',
            message: customErrorMessage,
            variant: 'error'
        }));
    } else {

        const pageErrors = event.detail?.output?.errors || [];
        let messages = [];
        if (pageErrors.length > 0) {
            messages = pageErrors.map(err => err.message);
        }

        console.log('messages'+messages);

        this.dispatchEvent(new ShowToastEvent({
            title: 'Validation Error',
            message:messages.join('\n'),
            variant: 'error'
        }));
        this.hideFormMessages = false;
    }
    }

    handleSuccess() {
        this.isLoading = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Opportunity Line Item created successfully!',
            variant: 'success'
        }));
        this.closeModal();

        const tableComponent = this.template.querySelector('c-opportunity-line-item-table');
        tableComponent.refreshTable();
        console.log('Parent: End of setTimeout refresh sequence.');
    }

}