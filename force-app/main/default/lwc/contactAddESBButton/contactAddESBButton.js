import { LightningElement,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ESBSFSubmitContact from '@salesforce/apex/AddContactESB.ESBSFSubmitContact';

export default class ContactAddESBButton extends LightningElement {
    @api recordId;

    handleClick() {
        ESBSFSubmitContact({ contactId: this.recordId })
            .then(() => {
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Contact added to Mpleo',
                    variant: 'success'
                });
                this.dispatchEvent(evt);
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
    }

}