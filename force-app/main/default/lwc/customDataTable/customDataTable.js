import LightningDatatable from 'lightning/datatable';
import customComboboxTemplate from './customComboboxCell.html';
import customCellDisplay from './customCellDisplay.html'
export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        customCombobox: {
            template: customCellDisplay,
            editTemplate: customComboboxTemplate, // THIS IS REQUIRED
            standardCellLayout: true,
            typeAttributes: [
                'options',
                'rowId',
                'fieldName',
                'context',
                'value', // ✅ You need this!
                'celllabel'
            ]
        }
    };
}