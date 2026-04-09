import { LightningElement, api } from 'lwc';

export default class ColoredCell extends LightningElement {
    @api value;
    connectedCallback() {
        console.log('Value:', this.value);
    }

    get cellClass() {
        if (this.value >= 70) {
            return 'green-text';
        } else if (this.value < 35) {
            return 'red-text';
        } else if (this.value){
            return 'yellow-text';
        }else {
            return '';
        }
    }
}