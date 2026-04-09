import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import getBaseRIGURL from '@salesforce/apex/RIG_LinkController.getBaseRIGURL';


export default class RigLink extends LightningElement {
    @api recordId;
    @api objectApiName;

    entityLabel; //entity Name
    url; //Url received from backend apex
    actionCompleted; //wired functions have been called
    urlText = '';


    @wire(getObjectInfo, { objectApiName: '$objectApiName' }) 
    objectInfo({ data, error }) {
        if (data) {
            this.entityLabel = data.label;
        }
    }
    
    @wire(getBaseRIGURL, { recordId: '$recordId' })
    wiredBaseRIGURL({ error, data }) {
        if (data) {
            this.url = data;
            this.urlText = `Click here to view / change the back office ${this.entityLabel} data`
        }
        else if (error) {
            console.error('Error retrieving base Url', error);
            this.showErrorAlert(error)
        }
        this.actionCompleted = true;
    }

    showErrorAlert(msg) {
        const toastEvent = new ShowToastEvent({
            title: 'Error retrieving record, try again...',
            message: msg,
            variant: 'error'
        })
        this.dispatchEvent(toastEvent)
    }


    //mark the rig sync date
    async handleClick(e) {
    }

}