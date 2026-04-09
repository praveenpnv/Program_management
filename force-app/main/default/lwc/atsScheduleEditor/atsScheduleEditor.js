import { LightningElement, wire,api } from 'lwc';
import {MessageContext,publish,subscribe} from 'lightning/messageService';
import atsv2RunAction from '@salesforce/messageChannel/TR1__atsv2RunAction__c';
import atsv2RunActionResult from '@salesforce/messageChannel/TR1__atsv2RunActionResult__c';
const SEND_OUT ='Send Out Schedules';
const INT_INTVWW='Internal Interviews';

export default class AtsScheduleEditor extends LightningElement {
    
    @api recordId;
    @api appStage;
    @api isReadOnly;
   @wire(MessageContext)
   messageContext;


openSendOutSchedules() {
        const appIdsArray = [this.recordId];
        const payload = {
            "action": this.appStage==='Application'?INT_INTVWW:SEND_OUT,
            "params": {
                "disableAppStatusChange": true,
                "applicationIds": appIdsArray,
                "eventsParams": [
                    {
                        "appId": this.recordId,
                        //"sendToInterviewer": true,
                        "sendToInterviewee": true,
                    }
                ]
            }
        };

        console.log('payload'+JSON.stringify(payload));
        publish(this.messageContext, atsv2RunAction, payload);

    }


connectedCallback() {
    subscribe(
        this.messageContext,
        atsv2RunActionResult,
        (message) => this.handleMessage(message),
    );
}


   // Handler for message received by component
   handleMessage(message) {
       // any custom logic to handle params from 'message' (which represents the result of running 'Send Out Schedules' action)
       console.log('message'+message);
   }


}