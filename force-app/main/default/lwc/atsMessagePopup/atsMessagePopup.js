import { LightningElement,wire } from 'lwc';
import LightningAlert from 'lightning/alert';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { subscribe, unsubscribe, publish,  MessageContext } from "lightning/messageService";

import atsAccessError from '@salesforce/label/c.atsAccessError';



export default class MyApp extends LightningElement {
     label = {
        atsAccessError
    };
    
    @wire(MessageContext)
    messageContext;

    async connectedCallback() {
        //code
    
   
        await LightningAlert.open({
            message: this.label.atsAccessError,
            theme: 'error', // a red theme intended for error states
            label: 'Error!', // this is the header text
        });
                    // Dispatch FlowNavigationFinishEvent to exit the flow
                    this.dispatchEvent(new FlowNavigationFinishEvent());
        //Alert has been closed
    }
    
}