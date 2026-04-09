/**
 * @description       : ATS Create Email
 * @author            : Raga Viswanathan
 * @last modified on  : 08-21-2024
 * @last modified by  : Raga Viswanathan
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   -            Raga Viswanathan           Initial Version
 **/
import { LightningElement, wire, api, track } from "lwc";
import {
    MessageContext,
    publish
} from 'lightning/messageService';

import ATSGenericModal from '@salesforce/messageChannel/ATSGenericModal__c';
//import CreateMessageLabel from "@salesforce/label/c.ATS_Modal_CreateEmail";

export default class AtsEmailModal extends LightningElement {
    @api recordId;
    @api appStageName;
    @api appStage;
    @api isReadOnly;
    @api emailPageType;
    
    @wire(MessageContext)
    messageContext;
    // Labels
 /*   labels = {
        CreateMessageLabel
    }*/

    // Open BH Propose to Client Email Modal
    handleEmail() {
                console.log('Inside Handleemail');
        const payload = {
            // Application Id
            recordId: this.recordId,

            // Modal to Open
            modal: this.appStage,
            emailPageType:this.emailPageType
        };
        // Publish to the LMS
        publish(this.messageContext, ATSGenericModal, payload);
    }}