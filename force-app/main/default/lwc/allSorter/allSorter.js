//import { LightningElement, api, wire } from 'lwc';
import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCorporationId from '@salesforce/apex/AllSorterController.getCorporationId';
export default class AllSorter extends LightningElement {

corporationId;
recordId;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.c__recordId) {
            this.recordId = pageRef.state.c__recordId;
            console.log('Received recordId from URL-:', this.recordId);
        }
    }

        @wire(getCorporationId)
    wiredCorpId({ error, data }) {
        if (data) {
            this.corporationId = data;
            console.log('Custom Setting Corporation ID:', this.corporationId);
        } else if (error) {
            console.error('Error fetching Corporation ID:', error);
        }
    }

    get urlAllsorter() {
        if (!this.recordId || !this.corporationId) return '';
        return `https://members.allsorter.com/public/initiate-reformatting?ats=salesforce&accountId=${this.corporationId}&candidateId=${this.recordId}`;
    }
}