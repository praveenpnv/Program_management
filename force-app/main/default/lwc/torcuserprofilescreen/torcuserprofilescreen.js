import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import TORC_USER_REF_FIELD from '@salesforce/schema/Contact.Torc_User_ref__c';
const FIELDS = ['Contact.FirstName', 'Contact.LastName','Contact.Torc_Email__c','Contact.Email', 'Contact.Description', TORC_USER_REF_FIELD];

import getSearchURL from '@salesforce/apex/JobMatchController.getSearchURL';


export default class TorcUserDisplay extends LightningElement {
    @api recordId;
    torcUserId;
    wiredContactResult;
    refreshInterval;
    hasStartedPolling = false;
    @api canvasUrl; //Not Used
    contact;
    error;
    isModalOpen = false;
    @track debugURL;

    @wire(getSearchURL)
    baseURL;



    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    contact(result) {
        this.wiredContactResult = result;
        console.log('Initial call');
        if (result.data) {
            console.log('Data Exists1');
            const ref = result.data.fields.Torc_User_ref__c;
            console.log(ref);
            console.log('Data Exists2');
            this.contact = result.data.fields;
            if (ref && ref.value) {
                console.log('Data Exists3');
                console.log(ref.value);
                this.torcUserId = ref.value;
                // Stop polling once the lookup is set
                clearInterval(this.refreshInterval);
                this.refreshInterval = null;
            }
        } else if (result.error) {
            console.error('Error loading contact:', result.error);
        }
    }

    renderedCallback() {
        this.setIframe();
        if (!this.hasStartedPolling) {
            this.hasStartedPolling = true;

            // Start polling every 3 seconds
            this.refreshInterval = setInterval(() => {
                console.log('Polling...');

                if (!this.torcUserId) {
                    console.log('Stop Polling...');
                    refreshApex(this.wiredContactResult);
                }
            }, 4000);
        }
    }

    disconnectedCallback() {
        // Cleanup interval if component is removed
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }


    computedCanvasUrl() {
        const email =  this.contact?.Torc_Email__c?.value;
        return `${this.baseURL?.data}/#/usermanager?autoGoogleSignIn=true&search=${encodeURIComponent(email)}`;
    }

    setIframe() {
        const iframe = this.template.querySelector('.myframe');
        if (iframe) {
            console.log('*****')
            console.log(this.computedCanvasUrl());
            console.log('*****')
            iframe.src = this.computedCanvasUrl(); // Sets DOM property directly; bypasses HTML encoding
            this.debugURL = iframe.src;
        }
    }

    handleEdit() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }
}