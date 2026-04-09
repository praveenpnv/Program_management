import { LightningElement, track } from 'lwc';

export default class SuperViewBoard extends LightningElement {

    @track selectedUserId;
    handleSelect(event) {
        const user = event.detail.selectedRecord;
        if (user) {
            this.selectedUserId = user.Id;
        }
    }
}