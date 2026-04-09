import { LightningElement, api } from 'lwc';

export default class JobAdResultViewer extends LightningElement {
    // This is essential for placing the component on a Record Page
    @api recordId;
}