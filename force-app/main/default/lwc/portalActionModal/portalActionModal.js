import  LightningModal  from 'lightning/modal';
import { api,track } from 'lwc';

export default class PortalActionModal extends LightningModal {

    @api columns = [];
    @api showSpinner = false;
    @api addToJob;
    @api addToLongList;
    @api addToCallList;
    

    get hasData() {
        return this.contactData.length > 0;
    }
    
    /*handleSave() {
        if (this.addToJob) {
            this.addToJob();
        }
    }*/
async handleSave() {
    if (this.addToJob) {
        this.showSpinner = true; // Show spinner while saving
        try {
            await this.addToJob(); // Wait for the job to complete
            console.log('Save operation completed successfully.');
        } catch (error) {
            console.error('Error in handleSave:', error);
        } finally {
            this.showSpinner = false; // Hide spinner after operation
            this.close('Reopen'); // Close modal after completion
        }
    }
}
async  saveLonglist(){
    if (this.addToLongList) {
        this.showSpinner = true; // Show spinner while saving
        try {
            await this.addToLongList(); // Wait for the job to complete
            console.log('Save operation completed successfully.');
        } catch (error) {
            console.error('Error in addToLongList:', error);
        } finally {
            this.showSpinner = false; // Hide spinner after operation
            this.close('Reopen'); // Close modal after completion
        }
    }

}
saveCallList(){
    if (this.addToCallList) {
        this.showSpinner = true; // Show spinner while saving
        try {
         this.addToCallList(); // Wait for the job to complete
            console.log('Save operation completed successfully.');
        } catch (error) {
            console.error('Error in addToCallList:', error);
        } finally {
            this.showSpinner = false; // Hide spinner after operation
            this.close(); // Close modal after completion
        }
    }

}

    handleClose() {
        this.close(); // Ensure this method is present
    }
   @track _contactData = []; // Private variable to store contact data

@api
set contactData(newData) {
    this._contactData = [...newData]; // Spread operator ensures a fresh reference
}

get contactData() {
    return this._contactData;
}
}