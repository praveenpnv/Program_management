import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord,updateRecord ,getFieldValue} from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class UserContactLookup extends LightningElement {
    @track searchKey = '';
    @track results = [];
    @track selectedRecords = [];
    @track hasFocus = false;
    @api recordId;
    @api idsFieldApiName;   // e.g., 'Custom_Field_Ids__c'
    @api namesFieldApiName;
    @track storedIds = [];
    @api isReadOnly = false;

    maxSelections = 5;

    get gqlVariables() {
        return {
            search: `%${this.searchKey}%`
        };
    }

    @track isEditMode = false;

    enableEdit() {
        this.isEditMode = true;
    }


    get noSelectedRecords() {
        return this.selectedRecords.length === 0;
    }
@wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
wiredRecord({ data, error }) {
     console.log('recordId:', this.recordId);
    console.log('idsFieldApiName:', this.idsFieldApiName);
    console.log('recordFields:', this.recordFields);
    if (data) {
        console.log('data'+JSON.stringify(data))
        
        const idsRaw = getFieldValue(data,this.idsFieldApiName);
this.storedIds = idsRaw?.split(';').filter(id => id) || [];
            console.log('this.storedIds'+this.storedIds)
           } else if (error) {
        console.error('Error loading record:', error);
    }
}
// -- Extract Object API Name and Field API Name
    get objectApiName() {
        return this.idsFieldApiName?.includes('.') ? this.idsFieldApiName.split('.')[0] : null;
    }

    get fieldApiNameOnly() {
        return this.idsFieldApiName?.includes('.') ? this.idsFieldApiName.split('.')[1] : this.idsFieldApiName;
    }

    // -- Fetch Object Info
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    // -- Field Label Getter
    get fieldLabel() {
        if (
            this.objectInfo?.data &&
            this.fieldApiNameOnly &&
            this.objectInfo.data.fields[this.fieldApiNameOnly]
        ) {
            return this.objectInfo.data.fields[this.fieldApiNameOnly].label;
        }
        return '';
    }


get gqlStoredVariables() {
    console.log('this.storedIds'+this.storedIds)
    return {
        ids: this.storedIds
    };
}

@wire(graphql, {
    query: gql`
        query FetchStoredUsersAndContacts($ids: [ID!]) {
            uiapi {
                query {
                    User(where: { Id: { in: $ids } }) {
                        edges { node { Id, Name { value } } }
                    }
                    Contact(where: { Id: { in: $ids } }) {
                        edges { node { Id, Name { value } } }
                    }
                }
            }
        }
    `,
    variables: '$gqlStoredVariables'
})
wiredStoredResults({ data, errors }) {
    if (data) {
        const users = data?.uiapi?.query?.User?.edges || [];
        const contacts = data?.uiapi?.query?.Contact?.edges || [];

        this.selectedRecords = [
            ...users.map(edge => ({
                type: 'icon',
                name: edge.node.Id,
                label: edge.node.Name.value,
                iconName: 'standard:user',
                url: `/${edge.node.Id}`
            })),
            ...contacts.map(edge => ({
                type: 'icon',
                name: edge.node.Id,
                label: edge.node.Name.value,
                iconName: 'standard:contact',
                url: `/${edge.node.Id}`
            }))
        ];
    } else if (errors) {
        console.error('GraphQL wire error for stored records:', errors);
    }
}


get recordFields() {
  console.log('Returning recordFields:', this.idsFieldApiName ? [this.idsFieldApiName] : []);
  return this.idsFieldApiName ? [this.idsFieldApiName] : [];
}


    @wire(graphql, {
        query: gql`
            query SearchUsersAndContacts($search: String!) {
                uiapi {
                    query {
                        User(where: { Name: { like: $search } }, first: 5) {
                            edges { node { Id, Name { value } } }
                        }
                        Contact(where: { Name: { like: $search } }, first: 5) {
                            edges { node { Id, Name { value } } }
                        }
                    }
                }
            }
        `,
        variables: '$gqlVariables'
    })
    wiredResults({ data, errors }) {
        if (this.searchKey.length < 2) {
            this.results = [];
            return;
        }

        if (data) {
            const users = data?.uiapi?.query?.User?.edges || [];
            const contacts = data?.uiapi?.query?.Contact?.edges || [];

            const selectedIds = new Set(this.selectedRecords.map(r => r.name));

            const userResults = users.map(edge => ({
                id: edge.node.Id,
                name: edge.node.Name.value,
                type: 'User',
                iconName: 'standard:user'
            }));

            const contactResults = contacts.map(edge => ({
                id: edge.node.Id,
                name: edge.node.Name.value,
                type: 'Contact',
                iconName: 'standard:contact'
            }));

            this.results = [...userResults, ...contactResults].filter(
                result => !selectedIds.has(result.id)
            );
        } else if (errors) {
            console.error('GraphQL wire error:', errors);
        }
    }

    get comboboxClasses() {
        const base = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        return this.hasFocus && this.results.length ? `${base} slds-is-open` : base;
    }
    get inputClasses() {
        return this.disableInput ? 'slds-input slds-hide' : 'slds-input';
    }

    get placeholder() {
        return this.hasSelections ? 'Search...' : 'Type at least 2 characters';
    }

    get hasSelections() {
        return this.selectedRecords.length > 0;
    }

    get disableInput() {
        return this.selectedRecords.length >= this.maxSelections;
    }

    handleFocus() {
        this.hasFocus = true;
    }

    handleBlur() {
        setTimeout(() => {
            this.hasFocus = false;
        }, 200);
    }

    handleSearch(event) {
        this.searchKey = event.target.value.trim();
    }



    get computedDisabled() {
        return !this.isEditMode || this.selectedRecords.length >= this.maxSelections;
    }

    get inputClasses() {
        return this.computedDisabled ? 'slds-input slds-hide' : 'slds-input';
    }

    get placeholder() {
        return this.computedDisabled
            ? 'Read Only'
            : 'Type at least 2 characters';
    }


    handleSelect(event) {
        const id = event.currentTarget.dataset.id;
        const type = event.currentTarget.dataset.type;

        const selected = this.results.find(r => r.id === id && r.type === type);

        if (
            selected &&
            !this.selectedRecords.some(r => r.name === selected.id) &&
            this.selectedRecords.length < this.maxSelections
        ) {
            this.selectedRecords = [
                ...this.selectedRecords,
                {
                    type: 'icon',
                    name: selected.id,        // unique ID for lightning-pill-container
                    label: selected.name,     // display name
                    iconName: selected.iconName,
                     url: `/${selected.id}` ,   // ✅ Add the record URL once
                    alternativeText: selected.name
                }
            ];
        }

        // Clear input & results
        this.results = [];
        this.searchKey = '';

        // Blur input to close dropdown
        //this.template.querySelector('input')?.blur();
    }

    handleRemove(event) {
        const idToRemove = event.detail.item.name;
        this.selectedRecords = this.selectedRecords.filter(r => r.name !== idToRemove);
    }

handleSave() {
    const ids = this.selectedRecords.map(r => r.name).join(';');
    const names = this.selectedRecords.map(r => r.label).join(';');

    const fields = {};
    fields['Id'] = this.recordId;
    const fieldName = this.idsFieldApiName.split('.').pop(); // "Collaborator__c"

    fields[fieldName] = ids;
   // fields[this.namesFieldApiName] = names;

    const recordInput = { fields };

    updateRecord(recordInput)
        .then(() => {
            this.isEditMode = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Fields updated successfully!',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.error(error);
            let errorMessage = 'An unknown error occurred while trying to update the record. Please try again.';
            let errorTitle = 'Error updating record';

            if (error.body && error.body.output && error.body.output.fieldErrors) {
                const fieldErrors = error.body.output.fieldErrors;
                const errorMessages = [];

                for (const fieldApiName in fieldErrors) {
                    if (Object.prototype.hasOwnProperty.call(fieldErrors, fieldApiName)) {
                        const errors = fieldErrors[fieldApiName];
                        errors.forEach(err => {
                            if (err.message) {
                                errorMessages.push(err.message);
                            }
                        });
                    }
                }
                
                if (errorMessages.length > 0) {
                    errorMessage = errorMessages.join('; ');
                    errorTitle = 'Validation Error';
                }
            } else if (error.body && error.body.message) {
                 errorMessage = error.body.message;
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: errorTitle,
                    message: errorMessage,
                    variant: 'error',
                     mode: 'sticky'
                })
            );
        });
}

    handleCancel() {
        this.isEditMode = false;
        this.searchKey = '';
        this.results = [];
        // Optionally: reload original selectedRecords if you want to reset changes
    }

}