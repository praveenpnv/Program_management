import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/EmailSender.sendEmail';

export default class SendEmailButton extends LightningElement {
    @api recordId; // The current Account's Id
    @track invoicingName = '';
    @track paymentTerms = '';
    @track graydonRating = '';
    @track contactPerson = '';
    @track comment = '';
    @track isButtonDisabled = true;

    graydonRatingOptions = [
        { label: 'AAA', value: 'AAA' },
        { label: 'AA', value: 'AA' },
        { label: 'A', value: 'A' },
        { label: 'BBB', value: 'BBB' },
        { label: 'BB', value: 'BB' },
        { label: 'B', value: 'B' },
        { label: 'CCC', value: 'CCC' },
        { label: 'CC', value: 'CC' },
        { label: 'C', value: 'C' },
        { label: 'D', value: 'D' },
    ];

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;
        this.isButtonDisabled = !(
            this.invoicingName &&
            this.paymentTerms &&
            this.graydonRating &&
            this.contactPerson
        );
    }

    handleSendEmail() {
        console.log('this.recordId'+this.recordId);
        sendEmail({
            recordId: this.recordId,
            invoicingName: this.invoicingName,
            paymentTerms: this.paymentTerms,
            graydonRating: this.graydonRating,
            contactPerson: this.contactPerson,
            comment: this.comment
        })
        .then(result => {
            this.showToast('Success', 'Email sent successfully', 'success');
        })
        .catch(error => {
            this.showToast('Error', 'Email send failed: ' + error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}