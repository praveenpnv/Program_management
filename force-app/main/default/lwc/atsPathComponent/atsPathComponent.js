import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
const FIELDS = ['Record.RecordTypeId'];

export default class AtsPathComponent extends LightningElement {
    @api objectApiName; // Specify the object API name
    @api fieldName; // Specify the dependent field
    @api appStage; // Controlling field value passed as a parameter
    @api currentStage; // This can be set by the parent component
    @api currentSubStage; 
    @api isReadOnly;
    @api recordId; // Record ID passed as a parameter

    @track stages = []; // Initialize stages array with tracking
    @track error;
    recordTypeId;
records;
dataAvailable = false;
get isDisabled(){
    return this.isReadOnly===true ? 'readonly-step' : ''
}
    // Construct the dynamic fields array
    get fields() {
                return [`${this.objectApiName}.RecordTypeId`, `${this.objectApiName}.${this.fieldName}`];

    }
    get whereCls() {
        return `{ "and": [
        { "TR1__ATS_Stage__c": { "eq": "${this.appStage}" } },
        { "TR1__Is_Active__c": { "eq": true } }
    ]}`;
    }
    // Fetch the record to get the RecordTypeId
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('Record Data:', data);
            this.recordTypeId = data.fields.RecordTypeId.value;
            //this.currentSubStage =getFieldValue(data, `${this.objectApiName}.${this.fieldName}`);
            console.log('RecordTypeId:', this.recordTypeId);
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching record:', error);
            this.error = error.body.message;
            this.recordTypeId = undefined;
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',  // Parent record ID (TR1__Application__c)
        relatedListId: 'TR1__Sub_Statuses__r',  // Custom related list API name (__r suffix)
        fields: ['TR1__Sub_Status__c.TR1__Value__c'],  // Fields to retrieve
        where: '$whereCls',  // Apply dynamic where clause


        pageSize: 100,  // Optional: Adjust number of records to retrieve
    })
    listInfo({ error, data }) {
        if (data) {
            this.records = data.records;
            this.error = undefined;
            if (this.records.length > 0) {
                this.currentSubStage = this.records[0].fields.TR1__Value__c.value;
                console.log('sub stage' + this.currentSubStage);

            }
        } else if (error) {
            this.error = error;
            console.error('error fetching sub status', error);

            this.records = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            console.log('Object Info:', data);
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: '$objectApiName', recordTypeId: '$recordTypeId' })
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('Picklist Values Data:', data);
            const dependentFieldData = data.picklistFieldValues[this.fieldName];
            const controllingValue = dependentFieldData.controllerValues[this.appStage];
            //const controllingValue = this.appStage;
            console.log('Dependent Field Data:', dependentFieldData);
            console.log('Controlling Value:', controllingValue);
            const dependentValues = dependentFieldData.values.filter(item => item.validFor.includes(controllingValue));

            if (dependentValues && dependentValues.length > 0) {
                // Map dependentValues to stages array with label, value, and isSelected properties
                this.stages = dependentValues.map(item => ({
                    label: item.label,
                    value: item.value,
                    isSelected: item.value === this.currentStage // Compare value to currentStage
                }));

                const currentStagePresent = this.stages.some(stage => stage.value === this.currentSubStage);

                // If currentStage is not present, set the first stage as the current stage
                if (!currentStagePresent && this.stages.length > 0) {
                    this.currentSubStage = this.stages[0].value;
                    }
                                this.dispatchEvent(new CustomEvent('stagechange', { detail: this.currentSubStage }));

                console.log('Stages:', JSON.stringify(this.stages));
                this.dataAvailable = true;
            } else {
                this.stages = [];
                console.log('No dependent values found.');
            }
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching picklist values:', error);
            this.error = error.body.message;
            this.stages = [];
        }
    }

    get recordTypeId() {
        return this.recordTypeId;
    }

     handleStageClick(event) {
        
        this.currentSubStage = this.stages[event.detail.index].value;
        this.dispatchEvent(new CustomEvent('stagechange', { detail: this.currentSubStage }));
        console.log('this.currentSubStage',this.currentSubStage);

        // Handle the click event and set the current step
    }


}