import LightningDatatable from "lightning/datatable";
import userLookupTemplate from './userLookup.html';
import userLookupEditTemplate from './userLookupEdit.html';
import imageTableControl from './imageTableControl.html';
import timerComponent from './timerComponent.html';
import coloredCellTemplate from './coloredCell.html';
//import coloredCellTemplate from 'c/coloredCell';

export default class JobDataTable extends LightningDatatable {

    get editedValue(){
        return this.typeAttributes.value;
    }

    static customTypes = {
        userLookup: {
            template: userLookupTemplate,        
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name' ,'placeholder', 'disabled']
        },
        image: {
            template: imageTableControl
        },
        jobTimer: {
            template: timerComponent,
            typeAttributes: ['recordId']

        },
        coloredCell: {
            template: coloredCellTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        }
    };


}