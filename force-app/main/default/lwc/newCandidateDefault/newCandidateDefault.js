import { LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import USER_ID from '@salesforce/user/Id';

export default class NewCandidateDefault extends NavigationMixin(LightningElement) {
    objectApiName = CONTACT_OBJECT;
    recordTypeOptions = [];
    selectedRecordTypeId;
    currentUserId = USER_ID;
        isModalOpen = false;


    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            this.recordTypeOptions = Object.keys(rtInfos)
                .filter((rtId) => rtInfos[rtId].available && (rtInfos[rtId].name === 'Candidate' || rtInfos[rtId].name === 'Client'))
                .map((rtId) => {
                     if (rtInfos[rtId].name === 'Candidate') {
                    this.selectedRecordTypeId = rtId; // Set Candidate as default
                }
                return{
                    label: rtInfos[rtId].name,
                    value: rtId
                };
                });
        }
    }

    connectedCallback() {
        this.isModalOpen=true;
    }
 openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        console.log('OUTPUT : ');
        this.isModalOpen = false;
    }
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.target.value;
    }

    handleCreate() {
        const defaultValues = encodeDefaultFieldValues({
            Responsible_recruiter__c: this.currentUserId
        });


        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.selectedRecordTypeId,
                defaultFieldValues: defaultValues
            }
            
        });
                this.closeModal();

    }
    handleCancel(){
 this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
            objectApiName: 'Contact',
            actionName: 'list'
        },
        state: {
            filterName: 'Recent' // or 'AllContacts' or another named list view
        }
    });
    }

}