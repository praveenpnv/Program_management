import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

const FIELDS = ['Account.RecordTypeId'];
const GLOBAL_ACCOUNT_RT_NAME = 'Global Account';
const MARKET_ACCOUNT_RT_NAME = 'Market Account';
const LOCAL_ACCOUNT_RT_NAME = 'Local Account';

export default class GlobalAccountStructure extends NavigationMixin(LightningElement) {
    @api recordId; // parent Account Id
    recordTypeIdToNavigate;
    hasNavigated = false;

    currentRecordTypeId;
    recordTypeInfosMap;

    // Get current record's RecordTypeId
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            this.currentRecordTypeId = data.fields.RecordTypeId.value;
            this.tryNavigate(); // Check conditions once both wires run
        } else if (error) {
            console.error('Error fetching Account record:', error);
        }
    }

    // Get all Account object metadata, including record types
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.recordTypeInfosMap = data.recordTypeInfos;
            this.tryNavigate(); // Check conditions once both wires run
        } else if (error) {
            console.error('Error loading object info:', error);
        }
    }

    tryNavigate() {
        if (!this.currentRecordTypeId || !this.recordTypeInfosMap || this.hasNavigated) return;

        const recordTypes = Object.values(this.recordTypeInfosMap);
        const currentRt = recordTypes.find(rt => rt.recordTypeId === this.currentRecordTypeId);

        if (!currentRt) return;

        console.log('Current RecordType Name:', currentRt.name);

        // Logic for navigation decision
        if (currentRt.name === GLOBAL_ACCOUNT_RT_NAME) {
            const marketAccountRT = recordTypes.find(rt => rt.name === MARKET_ACCOUNT_RT_NAME);
            if (marketAccountRT) {
                this.recordTypeIdToNavigate = marketAccountRT.recordTypeId;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.navigateToNewAccount();
            }
        } else if (currentRt.name === MARKET_ACCOUNT_RT_NAME) {
            const localAccountRT = recordTypes.find(rt => rt.name === LOCAL_ACCOUNT_RT_NAME);
            if (localAccountRT) {
                this.recordTypeIdToNavigate = localAccountRT.recordTypeId;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.navigateToNewAccount();
            }
        }
    }
    navigateToNewAccount() {
        if (!this.recordTypeIdToNavigate || !this.recordId || this.hasNavigated) return;

        const defaultValues = encodeDefaultFieldValues({
        ParentId: this.recordId
        });

        console.log('defaultValues'+defaultValues);

        this.hasNavigated = true;

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.recordTypeIdToNavigate,
                defaultFieldValues:defaultValues
            }
        });
        
        console.log('Navigating to new Account with RT:', this.recordTypeIdToNavigate);
    }
}