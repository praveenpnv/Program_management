import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFileCount from '@salesforce/apex/ContentFileController.getFileCount';
import { refreshApex } from '@salesforce/apex';

export default class ContentFileBanner extends NavigationMixin(LightningElement) {
    @api recordId;
    @api fileCategory;

    fileCount = 0;
    noFilesFound = false;
    recordPageUrl;

     @wire(getFileCount, { linkedEntityId: '$recordId', fileCategory: '$fileCategory' })
    wiredFileCount(result) {
        this.wiredFileData = result; // Store wire result for refreshing later
        const { data, error } = result;
        if (data !== undefined) {
            this.fileCount = data;
            this.noFilesFound = this.fileCount === 0;
        } else if (error) {
            console.error('Error fetching file count:', error);
            this.noFilesFound = true;
        }
    }
     @track isModalOpen = false;

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
         refreshApex(this.wiredFileData); 
    }
    
}