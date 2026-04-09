import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RecordDocumentsTable extends LightningElement {
    @api recordId;
    @track documents = [];
    @track isModalOpen = false;
    @track isReplaceMode = false;
    @track selectedDocId = null;
    @track isLoading = false;

    // Form fields
    @track documentName = '';
    @track documentType = '';
    @track selectedFile = null;

    // Document type picklist options
    documentTypeOptions = [
        { label: 'Resume', value: 'Resume' },
        { label: 'Offer Letter', value: 'Offer_Letter' },
        { label: 'Contract', value: 'Contract' },
        { label: 'Invoice', value: 'Invoice' },
        { label: 'Receipt', value: 'Receipt' },
        { label: 'Policy Document', value: 'Policy_Document' },
        { label: 'Other', value: 'Other' }
    ];

    // Table columns definition
    columns = [
        {
            label: 'Name',
            fieldName: 'fileUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'name' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Document Type',
            fieldName: 'documentType',
            type: 'text',
            sortable: true
        },
        {
            label: 'Actions',
            type: 'action',
            typeAttributes: {
                rowActions: this.getRowActions
            }
        }
    ];

    connectedCallback() {
        this.loadDocuments();
    }

    loadDocuments() {
        // Mock data for POC - Replace with Apex call in production
        this.isLoading = true;
        
        setTimeout(() => {
            this.documents = [
                {
                    id: '1',
                    name: 'Resume_v3.pdf',
                    documentType: 'Resume',
                    driveFileId: 'mock-drive-id-1',
                    fileUrl: 'https://drive.google.com/file/d/mock-drive-id-1/view'
                },
                {
                    id: '2',
                    name: 'Offer_Letter.pdf',
                    documentType: 'Offer Letter',
                    driveFileId: 'mock-drive-id-2',
                    fileUrl: 'https://drive.google.com/file/d/mock-drive-id-2/view'
                }
            ];
            this.isLoading = false;
        }, 500);
    }

    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'Replace', name: 'replace' },
            { label: 'Delete', name: 'delete' }
        ];
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'replace':
                this.handleReplace(row);
                break;
            case 'delete':
                this.handleDelete(row);
                break;
            default:
        }
    }

    handleAddDocument() {
        console.log('Add Document clicked');
        this.isReplaceMode = false;
        this.selectedDocId = null;
        this.documentName = '';
        this.documentType = '';
        this.selectedFile = null;
        this.isModalOpen = true;
        console.log('Modal should be open:', this.isModalOpen);
    }

    handleReplace(row) {
        this.isReplaceMode = true;
        this.selectedDocId = row.id;
        this.documentName = row.name;
        this.documentType = row.documentType.replace(' ', '_');
        this.selectedFile = null;
        this.isModalOpen = true;
    }

    handleDelete(row) {
        if (confirm(`Are you sure you want to delete "${row.name}"?`)) {
            this.isLoading = true;
            
            // Mock deletion - Replace with Apex call in production
            setTimeout(() => {
                this.documents = this.documents.filter(doc => doc.id !== row.id);
                this.isLoading = false;
                
                this.showToast('Success', `Document "${row.name}" deleted successfully`, 'success');
            }, 500);
        }
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.documentName = '';
        this.documentType = '';
        this.selectedFile = null;
    }

    handleNameChange(event) {
        this.documentName = event.target.value;
    }

    handleTypeChange(event) {
        this.documentType = event.target.value;
    }

    handleFileChange(event) {
        const files = event.target.files;
        if (files.length > 0) {
            this.selectedFile = files[0];
        }
    }

    handleSave() {
        console.log('Save clicked');
        // Validation
        if (!this.documentName) {
            this.showToast('Error', 'Please enter a document name', 'error');
            return;
        }
        if (!this.documentType) {
            this.showToast('Error', 'Please select a document type', 'error');
            return;
        }
        if (!this.selectedFile && !this.isReplaceMode) {
            this.showToast('Error', 'Please select a file to upload', 'error');
            return;
        }

        console.log('Validation passed, saving document...');
        this.isLoading = true;
        this.isModalOpen = false;

        // Mock save/upload - Replace with Apex call and Drive integration in production
        setTimeout(() => {
            if (this.isReplaceMode) {
                // Update existing document
                this.documents = this.documents.map(doc => {
                    if (doc.id === this.selectedDocId) {
                        return {
                            ...doc,
                            name: this.documentName,
                            documentType: this.documentType.replace('_', ' '),
                            fileUrl: doc.fileUrl // Would be updated from Drive in production
                        };
                    }
                    return doc;
                });
                this.showToast('Success', 'Document replaced successfully', 'success');
            } else {
                // Add new document
                const newDoc = {
                    id: String(this.documents.length + 1),
                    name: this.documentName,
                    documentType: this.documentType.replace('_', ' '),
                    driveFileId: `mock-drive-id-${this.documents.length + 1}`,
                    fileUrl: `https://drive.google.com/file/d/mock-drive-id-${this.documents.length + 1}/view`
                };
                this.documents = [...this.documents, newDoc];
                this.showToast('Success', 'Document added successfully', 'success');
            }
            
            this.isLoading = false;
            this.documentName = '';
            this.documentType = '';
            this.selectedFile = null;
        }, 1000);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get hasDocuments() {
        return this.documents && this.documents.length > 0;
    }

    get modalTitle() {
        return this.isReplaceMode ? 'Replace Document' : 'Add Document';
    }

    get saveButtonLabel() {
        return this.isReplaceMode ? 'Replace' : 'Save';
    }
}