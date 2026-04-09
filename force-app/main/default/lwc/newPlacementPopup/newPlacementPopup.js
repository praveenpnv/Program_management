import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getClosingReportPrefillMaps from '@salesforce/apex/EngagementPrefillHandler.getClosingReportPrefillMaps';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class NewPlacementPopup extends NavigationMixin(LightningElement) {
    @api recordid; // Application_V2__c ID
    recordTypeId;
    showSpinner = false; 
    originalUrl;

    connectedCallback() {
        console.log('✅ recordid:', this.recordid);
        // Save current flow URL
        this.originalUrl = window.location.href;
        console.log('Original URL:', this.originalUrl);
        this.showSpinner = true; // Show spinner before call
        getClosingReportPrefillMaps({ applicationRecordId: this.recordid })
            .then(result => {
                // ✅ Convert mapping array to object with field-value pairs
                const defaultFields = {};
                result.forEach(item => {
                    if (item.value) {
                        defaultFields[item.closingField] = item.value;
                    }
                });
                this.showSpinner = false; 
                this.openNewClosingReport(defaultFields); // pass to method
            })
            .catch(error => {
                console.error('❌ Error fetching default values:', error);
                this.showToast('Error', 'Could not fetch field mappings for Closing Report.', 'error');
                this.showSpinner = false;
            });
            this.startWatchingUrlChange();
    }

    // ✅ Accept dynamic default field values
    openNewClosingReport(dynamicDefaults) {
        const defaultValues = encodeDefaultFieldValues({
            ...dynamicDefaults, // ✅ from Apex
        });
        console.log('✅ dynamicDefaults->', dynamicDefaults);      
        
        this.recordTypeId = dynamicDefaults.RecordTypeId;

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'TR1__Closing_Report__c',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.recordTypeId,
                defaultFieldValues: defaultValues
            }
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

        startWatchingUrlChange() {
        this.urlWatcher = setInterval(() => {
            const currentUrl = window.location.href;
            console.log('Current URL:', currentUrl);
            // User is back on the flow screen (original URL)
            if (currentUrl != this.originalUrl) {
                clearInterval(this.urlWatcher);
                
                // Dispatch FlowNavigationFinishEvent to exit the flow
                this.dispatchEvent(new FlowNavigationFinishEvent());
                console.log('Flow navigation finished event dispatched.');
            }
        }, 500); // Check every second
    }

    disconnectedCallback() {
        if (this.urlWatcher) {
            clearInterval(this.urlWatcher);
        }
    }
}