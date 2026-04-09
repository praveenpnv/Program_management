import { LightningElement, api, wire } from 'lwc';
    import { NavigationMixin } from 'lightning/navigation';
    import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
    import { ShowToastEvent } from 'lightning/platformShowToastEvent';
    import cloneRecord from '@salesforce/apex/changeRequestController.cloneRecord';
    import getRecordTypeId from '@salesforce/apex/changeRequestController.getRecordTypeId';


    export default class ChangeRequestForm extends NavigationMixin(LightningElement) {
        @api recordId; //
        //newRecordTypeId = '0129X00000ACztCQAT';
        recordTypeId;
        @api jobtype;
        recordtypeName;


        connectedCallback() {
            let recordtypeName;
            if(this.jobtype =='Contract') {
             recordtypeName ='Change Request'
            }else if(this.jobtype =='Permanent') { 
              recordtypeName ='Change Request Permanent'
            }

            getRecordTypeId({ objectApiName: 'TR1__Closing_Report__c', recordTypeName: recordtypeName })
                .then(result => {
                    this.recordTypeId = result;
                    console.log('✅ Fetched Record Type ID:', this.recordTypeId);
                })
                .catch(error => {
                    console.error('❌ Error fetching Record Type ID:', error);
                });
            
        }

        handleClone(){
            console.log('✅ Cloning record:', this.recordId);

            if (!this.recordId || !this.recordTypeId) {
                console.error('❌ Record ID or Record Type ID is missing.');
                return;
            }

            cloneRecord({ recordId: this.recordId, newRecordTypeId: this.newRecordTypeId })
                .then(clonedRecord => {
                    console.log('✅ Cloned record ID:', clonedRecord);

                const defaultValues = encodeDefaultFieldValues(
                    clonedRecord
                    );
                    
                    console.log('✅ defaultValues:', defaultValues);

                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'TR1__Closing_Report__c',
                            actionName: 'new'
                        },
                        state: {
                            defaultFieldValues: defaultValues,
                            recordTypeId: this.recordTypeId
                        }
                         
                    })
                })
                .catch(error => {
                    console.error('❌ Error cloning record:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
                });
        }

    
    }