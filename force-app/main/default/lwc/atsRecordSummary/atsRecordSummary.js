import { LightningElement, wire, track, api } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import getSummaryByPicklistAndField from '@salesforce/apex/RecordSummaryController.getSummaryByPicklistAndField';
import getFilterIdsByPicklistValues from '@salesforce/apex/RecordSummaryController.getFilterIdsByPicklistValues';
import getRecordTypeId from '@salesforce/apex/RecordSummaryController.getRecordTypeId';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

// LMS
import { MessageContext, publish, subscribe, unsubscribe } from "lightning/messageService";
import atsv2FilterChange from "@salesforce/messageChannel/TR1__atsv2FilterChange__c";
import atsRefreshStarted from "@salesforce/messageChannel/TR1__atsv2RefreshStarted__c";

export default class AtsRecordSummary extends NavigationMixin(LightningElement) {
    @api sObjectName;       // API property to accept the sObject name
    @api picklistField;     // API property to accept the picklist field name
    @api fieldName;         // API property to accept the field name for filtering

    @api picklistFieldName;
    @track picklistValues = [];
    @track summary = [];
    @track error;

    recordTypeId;
    recordId;
    filterMap = {};

    @wire(CurrentPageReference)
    pageRef;

    @wire(MessageContext)
    messageContext;


    connectedCallback() {
        this.picklistFieldName = this.sObjectName + '.' + this.picklistField;

        if (this.pageRef) {
            console.log('Page Reference:', this.pageRef);

            // Extract recordId from pageRef state
            this.recordId = this.getRecordIdFromPageRef();
            console.log('Record ID:', this.recordId);

            if (this.recordId) {
                this.fetchRecordTypeId();
            } else {
                console.error('Record ID is undefined. Ensure that the URL contains recordId.');
            }
        } else {
            console.error('Page Reference is undefined.');
        }
    }

    getRecordIdFromPageRef() {
        // Extract recordId from the pageRef state
        if (this.pageRef && this.pageRef.attributes && this.pageRef.attributes.recordId) {
            return this.pageRef.attributes.recordId;
        }
        return undefined;
    }

    fetchRecordTypeId() {
        if (!this.recordId) {
            console.error('Cannot fetch Record Type ID. Record ID is not defined.');
            return;
        }

        getRecordTypeId({
            sObjectName: this.sObjectName,
            fieldName: this.fieldName,
            fieldValue: this.recordId
        })
            .then(recordTypeId => {
                this.recordTypeId = recordTypeId;
                console.log('Record Type ID:', this.recordTypeId);

                // Fetch the filter IDs by picklist values
                this.fetchFilterIdsByPicklistValues();
            })
            .catch(error => {
                this.error = error;
                this.recordTypeId = undefined;
                console.error('Error fetching Record Type ID:', error);
            });
    }

    fetchFilterIdsByPicklistValues() {
        const picklistValues = this.picklistValues.map(value => value.label);

        getFilterIdsByPicklistValues({ picklistValues })
            .then(filterMap => {
                this.filterMap = filterMap;
                console.log('Filter Map:', this.filterMap);

                // Fetch the summary count after getting the filter IDs
                this.fetchSummaryCount();
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching Filter IDs:', JSON.stringify(error));
            });
    }

    @wire(getObjectInfo, { objectApiName: '$sObjectName' })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$picklistFieldName' })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.picklistValues = data.values;
            console.log('Picklist Values:', this.picklistValues);

            // Initialize the summary map with zero values for each picklist value
            let initialSummary = {};
            this.picklistValues.forEach(value => {
                initialSummary[value.value] = { label: value.label, count: 0 };
            });

            // Store the initial summary
            this.initialSummary = initialSummary;

            // Fetch the filter IDs by picklist values
            this.fetchFilterIdsByPicklistValues();
        } else if (error) {
            this.error = error;
            this.picklistValues = undefined;
            console.error('Error fetching Picklist Values:', error);
        }
    }

    fetchSummaryCount() {
        if (!this.recordId) {
            console.error('Cannot fetch Summary Count. Record ID is not defined.');
            return;
        }

        getSummaryByPicklistAndField({
            sObjectName: this.sObjectName,
            picklistField: this.picklistField,
            fieldName: this.fieldName,
            fieldValue: this.recordId
        })
            .then(data => {
                if (data) {
                    console.log('Summary Data:', data);
                    // Merge the filterMap with the summary data
                    let finalSummary = {};
                    for (const [key, value] of Object.entries(this.initialSummary)) {
                        finalSummary[key] = {
                            label: value.label,
                            count: data[key] || 0,
                            filterId: this.filterMap[value.label] ? this.filterMap[value.label] : null
                        };
                    }

                    // Convert the summary object to an array for easier iteration in the template
                    this.summary = Object.entries(finalSummary).map(([key, value]) => ({
                        value: key,
                        label: value.label,
                        count: value.count,
                        filterId: value.filterId
                    }));
                    console.log('Final Summary:', JSON.stringify(this.summary));
                }
            })
            .catch(error => {
                this.error = error;
                this.summary = undefined;
                console.error('Error fetching Summary Count:', JSON.stringify(error));  // Enhanced error logging
            });
    }


    // Stage / SubStage Selection Handler
    handleOnselect(event) {
        console.log('event.detail :' + JSON.stringify(event.currentTarget.dataset));
        const selectedItemValue = event.currentTarget.dataset.name;

        // Show "Clear" button for the selected item
        this.summary = this.summary.map(item => {
            if (item.value === selectedItemValue) {
                return { ...item, showClear: true };
            }
            return { ...item, showClear: false };
        });


        console.log('selectedItemValue' + selectedItemValue);
        const selectedFilterId = this.summary.find(item => item.value === selectedItemValue)?.filterId;

        if (selectedFilterId) {
            const payload = {
                filterId: selectedFilterId
            };
            publish(this.messageContext, atsv2FilterChange, payload);
        } else {
            console.error('No filter ID found for the selected item:', selectedItemValue);
        }
    }

    handleClear(event) {
        event.stopPropagation(); // Prevent the "Clear" button from triggering the "handleOnselect" event

        // Clear the selection and hide the "Clear" button
        this.summary = this.summary.map(item => {
            return { ...item, showClear: false };
        });

        // Reset the selectedItemValue
        this.selectedItemValue = null;

        // Publish a clear event or perform any other action
        const payload = {
            // Pass an empty filter Id to clear filters
            filterId: ''
        };
        publish(this.messageContext, atsv2FilterChange, payload);
    }
}