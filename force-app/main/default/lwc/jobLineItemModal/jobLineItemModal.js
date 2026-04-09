import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createJobsFromLineItems from '@salesforce/apex/JobPrefillHandler.createJobsFromLineItems';
export default class JobLineItemModal extends LightningModal {

    @api lineItemDetails = [];
    @track isLoading = false;
    @track allJobsCreated = false;
    connectedCallback() {

    }

    columns = [
        { label: 'Job Name', fieldName: 'Job_Name__c', type: 'text' },
        { label: 'Number of Positions', fieldName: 'Number_Of_Positions__c', type: 'number', cellAttributes: { alignment: 'left' } },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            cellAttributes: {
                iconName: { fieldName: 'iconName' },
                class: { fieldName: 'iconClass' },
                iconPosition: 'left',
                variant: { fieldName: 'iconVariant' },
                alternativeText: 'Status',
                title: 'Status'
            }
        }
    ];

    handleCreateJob() {
        this.isLoading = true;

        // Example: using first item for demo; expand as needed
        //const lineItemIds = this.lineItemDetails.map(item => item.Id);
        const lineItemIds = this.lineItemDetails
            .filter(item => !item.jobCreated) // Only those not already created
            .map(item => item.Id);
        console.log('lineItemIds' + this.lineItemDetails);

        createJobsFromLineItems({ lineItemIds })
            .then(result => {
                const createdJobMap = new Map(result.map(j => [j.lineItemId, j]));
                this.lineItemDetails = this.lineItemDetails.map(item => {
                    if (createdJobMap.has(item.Id)) {
                        return {
                            ...item,
                            Status: 'Success',
                            jobCreated: true,
                            iconName: 'utility:success',
                            iconVariant: 'success',
                            iconClass: 'slds-text-color_success'
                        };
                    }
                    return item;
                });

                this.checkAllJobsCreated();
                const createdJobs = result.map(j => `${j.jobName} (${j.jobId})`).join(', ');
                this.showToast('Success', `Successfully created: ${createdJobs}`, 'success');
            })
            .catch(error => {
                this.showToast('Error creating jobs', error.body?.message || error.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;

            });
    }

     checkAllJobsCreated() {
        this.allJobsCreated = this.lineItemDetails.length > 0 &&
            this.lineItemDetails.every(item => item.jobCreated); // ✅ Helper method
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }

}