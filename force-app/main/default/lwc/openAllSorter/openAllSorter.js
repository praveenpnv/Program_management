import { LightningElement, wire, track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class OpenAllSorter extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        console.log('this.recordId---------',this.recordId);
        // Redirect outside the modal as soon as component loads
        setTimeout(() => {
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'Test_Allsorter'
                },
                state: {
                    c__recordId: this.recordId
                }
            });
        }, 10);
    }
}