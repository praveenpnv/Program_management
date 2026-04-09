import { LightningElement, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFilteredReports from '@salesforce/apex/ChangeRequestApprovalHandler.getFilteredReports';
import getTotalCount from '@salesforce/apex/ChangeRequestApprovalHandler.getTotalCount';

const COLUMNS = [
    {
        label: 'Name',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    { label: 'Status', fieldName: 'Request_Status__c' },
    { label: 'Request Type', fieldName: 'Request_Type__c' },
    { label: 'Requested By', fieldName: 'requestedBy' },
    { label: 'Candidate Name', fieldName: 'candidateName' },
    { label: 'Account Name', fieldName: 'accountName' },
    { label: 'Job Name', fieldName: 'jobName' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
];

export default class ChangeRequestApprovalDashboard extends LightningElement {
    @track data = [];
    @track columns = COLUMNS;
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track selectedRows = [];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getTotalCount().then(count => {
            this.totalRecords = count;
            this.totalPages = Math.ceil(count / this.pageSize);
        });

        getFilteredReports({ pageSize: this.pageSize, pageNumber: this.currentPage })
            .then(result => {
                this.data = result.map(row => ({
                    ...row,
                    jobName: row.TR1__Job__r?.Name,
                    accountName: row.TR1__Account__r?.Name,
                    candidateName: row.ParentPlacementId__r?.Candidate_Name__c,
                    requestedBy: row.Requested_by__c,
                    recordLink: `/lightning/r/TR1__Closing_Report__c/${row.Id}/view`
                }));
            })
            .catch(error => {
                console.error('Error fetching records:', error);
            });
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadData();
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadData();
        }
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get isPrevDisabled() {
        return this.currentPage <= 1;
    }

    handleAccept() {
        if (this.selectedRows.length === 0) {
            this.showToast('No records selected', 'Please select at least one record.', 'warning');
            return;
        }

        const updates = this.selectedRows.map(row => ({
            fields: {
                Id: row.Id,
                Request_Status__c: 'Approved'
            }
        }));

    Promise.all(updates.map(recordInput => updateRecord(recordInput)))
    .then(() => {
        this.showToast('Success', 'Selected records approved.', 'success');
        this.loadData(); // Refresh the data
    })
    .catch(error => {
        console.error('Error details:', JSON.stringify(error));

        let message = 'Error updating records.';

        try {
            const body = error?.body;
            const output = body?.output;

            let messages = [];

            // 1. Field-level validation errors
            const fieldErrors = output?.fieldErrors;
            if (fieldErrors && Object.keys(fieldErrors).length > 0) {
                Object.keys(fieldErrors).forEach(fieldName => {
                    const errs = fieldErrors[fieldName] || [];
                    errs.forEach(err => {
                        const label = err?.fieldLabel || fieldName;
                        const msg = err?.message || 'Unknown error';
                        messages.push(`${label}: ${msg}`);
                    });
                });
            }

            // 2. General record errors (like trigger failures, DML exceptions)
            const generalErrors = output?.errors;
            if (generalErrors && generalErrors.length > 0) {
                generalErrors.forEach(err => {
                    messages.push(err?.message || 'Unknown record error');
                });
            }

            // 3. Fallback to top-level message
            if (messages.length > 0) {
                message = messages.join(' • ');
            } else if (body?.message) {
                message = body.message;
            }
        } catch (e) {
            console.warn('Error while parsing error object:', e);
            message = error?.body?.message || 'An unexpected error occurred.';
        }

        this.showToast('Error', message, 'error');
    });

    }

    showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant
        })
    );
    }

}