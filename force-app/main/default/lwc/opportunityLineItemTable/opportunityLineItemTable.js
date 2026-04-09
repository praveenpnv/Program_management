import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import datatableOverrides from '@salesforce/resourceUrl/datatableOverrides';
import getLineItems from '@salesforce/apex/OpportunityLineItemTableController.getLineItems';
import jobPortalModal from 'c/jobLineItemModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OpportunityLineItemTable extends LightningElement {
    @api recordId;
    @track rawTreeData = [];
    @track flattenedData = [];
    @track expandedLineItems = new Set();

    selectedDetails = [];
    disabledIds = new Set();
    selectedRowIds = [];
    isCssLoad = false;

    columns = [
        {
        label: '',
        type: 'button-icon',
        initialWidth: 50,
        typeAttributes: {
            iconName: { fieldName: 'toggleIcon' },
            alternativeText: 'Toggle Row',
            title: 'Toggle Row',
            variant: 'bare',
            class: 'slds-m-left_x-small'
        },
        cellAttributes: { alignment: 'left' },
        fieldName: 'toggleIcon',
        name: 'toggle'
    },
    {
        label: 'Name',
        fieldName: 'url',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'displayName' },
            target: '_blank'
        },
        cellAttributes: {
            class: { fieldName: 'nameCellClass' }
        }
    },
     {
        label: 'Number Of Positions',
        fieldName: 'Number_Of_Positions__c',
        type: 'number'
    },
    {
        label: 'Job Status',
        fieldName: 'Job_Status__c',
        type: 'text'
    },
    {
        label: 'Job Type',
        fieldName: 'Job_Type__c',
        type: 'text'
    },
    {
        label: 'Job Count',
        fieldName: 'Job_Count__c',
        type: 'number',
        cellAttributes: {
        alignment: 'center'
        }
    },
    {
        label: 'Status',
        fieldName: 'status',
        type: 'text',
        cellAttributes: {
            iconName: { fieldName: 'iconName' },
            iconPosition: 'left',
            class: { fieldName: 'iconClass' }
        },
        typeAttributes: {
            variant: { fieldName: 'iconVariant' }
        }
    }
];

    connectedCallback() {
        this.loadData();
        this.loadCustomStyles();
    }

    loadCustomStyles() {
        if (this.isCssLoad) return;
        this.isCssLoad = true;
        loadStyle(this, datatableOverrides)
            .then(() => {
                console.log('Custom datatable header styles applied');
            })
            .catch(error => {
                console.error('Error loading datatable styles:', error);
            });
    }

    loadData() {
        getLineItems({ opportunityId: this.recordId })
            .then(data => {
                this.disabledIds = new Set();
                this.rawTreeData = data;
                this.flattenedData = this.flattenTreeData(data);
            })
            .catch(error => {
                console.error('Error fetching line items:', error);
            });
    }
    

    flattenTreeData(data) {
    const flat = [];

    data.forEach(parent => {
        const jobCount = parent.Job_Count__c || 0;
        const isDisabled = jobCount > 0;

        if (isDisabled) {
            this.disabledIds.add(parent.name);
        }

        let rowAttrs = {};
        if (isDisabled) {
            rowAttrs.class = 'disabled-row slds-text-color_weak';
        }

        let statusInfo = {
            status: 'Pending',
            iconName: 'utility:clock',
            iconVariant: 'warning',
            iconClass: 'slds-text-color_default'
        };
        if (jobCount > 0) {
            statusInfo = {
                status: 'Success',
                iconName: 'utility:check',
                iconVariant: 'success',
                iconClass: 'slds-text-color_success'
            };
        }

        flat.push({
            ...parent,
            displayName: parent.LineItem_Name__c,
            url: parent.LineItem_Url__c,
            nameCellClass: 'no-pointer',
            level: 0,
            isParent: parent._children && parent._children.length > 0,
            toggleIcon: parent._children && parent._children.length > 0
                ? (this.expandedLineItems.has(parent.name) ? 'utility:chevrondown' : 'utility:chevronright')
                : '',
            visible: true,
            jobCount: jobCount,
            rowAttributes: rowAttrs,
            ...statusInfo
        });

        if (this.expandedLineItems.has(parent.name)) {
            parent._children.forEach(child => {
                flat.push({
                    ...child,
                    displayName: '↳ ' + child.Job_Name__c,
                    url: child.Job_Url__c,
                    nameCellClass: '',
                    level: 1,
                    isChild: true,
                    visible: true,
                    jobName: child.Job_Name__c,
                    jobStatus: child.Job_Status__c,
                    jobUrl: child.Job_Url__c,
                    jobType: child.Job_Type__c,
                });
            });
        }
    });

    return flat.filter(row => row.visible);
}

    handleRowAction(event) {
        const row = event.detail.row;

        if (row.isParent) {
            const isExpanded = this.expandedLineItems.has(row.name);

            if (isExpanded) {
                this.expandedLineItems.delete(row.name);
            } else {
                this.expandedLineItems.add(row.name);
            }

            this.flattenedData = this.flattenTreeData(this.rawTreeData);
        }
    }

    @api refreshTable() {
        console.log('refreshTable() called');
        this.loadData();
    }

    
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        const validSelectedRows = selectedRows.filter(row => !this.disabledIds.has(row.name));

        this.selectedDetails = validSelectedRows.map(row => {
            return {
                Id: row.name,
                Job_Name__c: row.LineItem_Name__c,
                Number_Of_Positions__c: row.Number_Of_Positions__c,
                Status: 'Pending',
                iconName: 'utility:clock',
                iconVariant: 'warning',
                iconClass: 'slds-text-color_default',
                jobCreated: row.jobCount > 0
            };
        });
        this.selectedRowIds = validSelectedRows.map(row => row.name);
        if (selectedRows.length !== validSelectedRows.length) {
            this.showToast('Some rows ignored', 'Jobs were already created for selected line items.', 'info');
        }

        console.log('selectedDetails: ' + JSON.stringify(this.selectedDetails));
    }

    @api async openModal() {
        try {
            if (this.selectedDetails.length === 0) {
                this.showToast('No records selected', 'Please select at least one line item.', 'warning');
                return;
            }

            const createdLineItemIds = await jobPortalModal.open({
                size: 'small',
                lineItemDetails: this.selectedDetails
            });
        this.refreshTable();
        } catch (error) {
            console.error('Error opening modal:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
            this.showToast('Error', 'Failed to open modal.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}