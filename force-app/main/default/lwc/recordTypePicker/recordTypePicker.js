import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RecordTypePicker extends LightningElement {
    @api objectApiName;
    @track recordTypeOptions = [];
    @track selectedRecordTypeId;
    @track error;
    @track isLoading = true;

    
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            this.recordTypeOptions = Object.keys(rtInfos)
                .filter(rtId => rtInfos[rtId].available)
                .map(rtId => {
                    return {
                        label: rtInfos[rtId].name,
                        value: rtId,
                        checked: false
                    };
                });

            this.error = null;
            this.isLoading = false;
        } else if (error) {
            this.recordTypeOptions = [];
            this.error = 'Failed to load record types.';
            this.isLoading = false;
        }
    }

    handleChange(event) {
        this.selectedRecordTypeId = event.target.value;
        this.recordTypeOptions = this.recordTypeOptions.map(option => ({
            ...option,
            checked: option.value === this.selectedRecordTypeId
        }));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSubmit() {
        this.dispatchEvent(
            new CustomEvent('recordtypeselected', {
                detail: { recordTypeId: this.selectedRecordTypeId }
            })
        );
    }

    get isSubmitDisabled() {
        return !this.selectedRecordTypeId;
    }
}