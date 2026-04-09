import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import FILE_CATEGORY_FIELD from '@salesforce/schema/ContentVersion.File_Category__c';
import getFiles from '@salesforce/apex/FileUploadHandler.getFiles'; // Apex method to fetch files
import updateFileCategory from '@salesforce/apex/FileUploadHandler.updateFileCategory';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class FileUpload extends LightningElement {
    @api recordId;
    @track category = '';
    @track categoryOptions = [];
    @track isUploadDisabled = true; // Disable upload until category is selected

    // Get Object Info
    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    objectInfo;

    // Get Picklist Values
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: FILE_CATEGORY_FIELD })
    wiredPicklist({ error, data }) {
        if (data) {
            this.categoryOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }
    @wire(getFiles, { recordId: '$recordId' })
    wiredFiles(result) {
        this.wiredFilesResult = result;
        if (result.data) {
            this.fileData = result.data.map(file => ({
                id: file.Id,
                title: file.Title,
                category: file.File_Category__c,
                url: `/lightning/r/ContentDocument/${file.ContentDocumentId}/view`
            }));
        } else if (result.error) {
            console.error('Error fetching files:', result.error);
        }
    }

    // Handle Category Change
    handleCategoryChange(event) {
        this.category = event.detail.value;
        this.isUploadDisabled = !this.category; // Enable upload button only when category is selected
    }

    handleUploadFinished(event) {
        if (!this.category) {
            this.showToast('Error', 'Please select a category before uploading.', 'error');
            return;
        }

        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length === 0) {
            return;
        }

        const contentVersionId = uploadedFiles[0].contentVersionId;

        // Call Apex to update File Category
        updateFileCategory({ contentVersionId,recordId:this.recordId, category: this.category })
            .then(() => {
                this.showToast('Success', 'File uploaded and category updated successfully!', 'success');
               // return refreshApex(this.wiredPicklist); // Refresh picklist values
            })
            .catch(error => {
                this.showToast('Error', 'Error updating file category', 'error');
                console.error(JSON.stringify(error));
            });
    }


    // Show Toast Message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    get columns() {
        return [
            { label: 'File Name', fieldName: 'title', type: 'text' },
            { label: 'Category', fieldName: 'category', type: 'text' },
            {
                label: 'View',
                fieldName: 'url',
                type: 'url',
                typeAttributes: { label: 'Open', target: '_blank' }
            }
        ];
    }
}