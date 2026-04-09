import { LightningElement, wire, api, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import OBJECT_API_NAME from '@salesforce/schema/TR1__Send_Out_Schedule_V2__c';
import getInterviewSchedules from '@salesforce/apex/InterviewListController.getInterviewSchedules';
import getRSVPStatusesBySendOut  from '@salesforce/apex/InterviewListController.getRSVPStatusesBySendOut';

export default class InterviewList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api appStage;

    @track columns = [];
    @track tableData = [];
    @track draftValues = [];

    SosId=[];
    fieldLabels = {};
    sendOutRecordTypeExternalId;
    sendOutRecordTypeInternalId;
    userTimeZone;
    @track showInterviewList = true;
    APP_STAGE= "Application";

    connectedCallback() {
        this.userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }

    get shouldFetchRelatedList() {
        return this.recordId && (
            (this.appStage === 'Application' && this.sendOutRecordTypeInternalId) ||
            (this.appStage === 'Send Out' && this.sendOutRecordTypeExternalId)
        );
    }

    get toggleIcon() {
        return this.showInterviewList ? 'utility:chevrondown' : 'utility:chevronright';
    }

    toggleInterviewList() {
        this.showInterviewList = !this.showInterviewList;
    }

    getRsvpIcon(status) {
        if (!status) return 'action:question_post_action';
        const lowerStatus = status.toLowerCase();
        if (lowerStatus === 'accepted') return 'action:approval';
        if (lowerStatus === 'declined') return 'action:close';
        return 'action:question_post_action';
    }

    @wire(getObjectInfo, { objectApiName: OBJECT_API_NAME })
    objectInfo({ data, error }) {
        if (data) {
            const fields = data.fields;
            const rtInfos = data.recordTypeInfos;

            for (const rtId in rtInfos) {
                if (rtInfos[rtId].name === 'Internal interview') {
                    this.sendOutRecordTypeInternalId = rtId;
                }
                if (rtInfos[rtId].name === 'External Interview') {
                    this.sendOutRecordTypeExternalId = rtId;
                }
            }

            this.columns = [
                {
                    label: fields?.Interview_Level__c?.label || 'Interview Level',
                    fieldName: 'Interview_Level__c',                    
                    hideDefaultActions: true
                },
                {
                    label: fields?.TR1__Interview_Date_Time__c?.label || 'Interview Date Time',
                    fieldName: 'TR1__Interview_Date_Time__c',
                    hideDefaultActions: true,
                    type: 'date',
                    typeAttributes: {
                        year: "numeric",
                        month: "2-digit",
                        day: "2-digit",
                        hour: "2-digit",
                        minute: "2-digit",
                        hour12: true,
                        timeZone: this.userTimeZone
                    }
                },
                {
                    label: fields?.TR1__Interviewee_Name__c?.label || 'Interviewee Name',
                    fieldName: 'TR1__Interviewee_Name__c',
                    type: 'text',
                    hideDefaultActions: true
                },
                {
                    label: fields?.Interview_Feedback__c?.label || 'Interview Feedback',
                    fieldName: 'Interview_Feedback__c',
                    type: 'text',
                    editable: true,
                    hideDefaultActions: true
                },
                {
                    label: 'Video Call',
                    fieldName: 'videoCallUrl',
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: 'videoCallLabel' },
                        target: '_blank'
                    },
                    hideDefaultActions: true
                },
                {
                    label: 'RSVP Status',
                    fieldName: 'RSVP_Status__c',
                    type: 'text',
                    hideDefaultActions: true,
                    cellAttributes: {
                        iconName: { fieldName: 'rsvpIcon' },
                        iconPosition: 'right'
                    }
                }
            ];
        } else if (error) {
            console.error('Error in getObjectInfo:', error);
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'TR1__Send_Out_Schedules1__r',
        fields: [
            'TR1__Send_Out_Schedule_V2__c.Interview_Level__c',
            'TR1__Send_Out_Schedule_V2__c.TR1__Interview_Date_Time__c',
            'TR1__Send_Out_Schedule_V2__c.TR1__Interviewee_Name__c',
            'TR1__Send_Out_Schedule_V2__c.Interview_Feedback__c',
            'TR1__Send_Out_Schedule_V2__c.VideoCallid__c'
        ],
        where: '$whereCls',
        pageSize: 100
    })
    listInfo({ error, data }) {
        if (!this.shouldFetchRelatedList) return;

        if (data) {
            console.log('Related List Records:', JSON.stringify(data)); 
            this.tableData = data.records.map(row => {
                const videoCallId = row.fields?.VideoCallid__c?.value || '';
                  console.log('Processing row ID:', row.id, 'VideoCallId:', videoCallId); // <-- log each row
                return {
                    Id: row.id,
                    Interview_Level__c: row.fields?.Interview_Level__c?.value || '',
                    TR1__Interview_Date_Time__c: row.fields?.TR1__Interview_Date_Time__c?.value || '',
                    TR1__Interviewee_Name__c: row.fields?.TR1__Interviewee_Name__c?.value || '',
                    Interview_Feedback__c: row.fields?.Interview_Feedback__c?.value || '',
                    RSVP_Status__c: '',
                    videoCallUrl: videoCallId ? '/' + videoCallId : '',
                    videoCallLabel: videoCallId ? 'Open Video Call' : ''
                };
            });
      console.log('Final tableData with Video Call URL:', JSON.stringify(this.tableData)); // <-- log final table data

            this.fetchRSVPStatuses();
        } else if (error) {
            console.error('Error fetching related list records:', error);
        }
    }

    fetchRSVPStatuses() {
        const sendOutIds = this.tableData.map(row => row.Id).filter(id => id);
        if (sendOutIds.length > 0) {
            getRSVPStatusesBySendOut({ sendOutIds })
                .then(rsvpMap => {
                    this.tableData = this.tableData.map(row => {
                        const status = rsvpMap[row.Id] || '';
                        return {
                            ...row,
                            RSVP_Status__c: status,
                            rsvpIcon: this.getRsvpIcon(status)
                        };
                    });
                })
                .catch(error => {
                    console.error('RSVP status fetch error:', error);
                });
        }
    }

    get whereCls() {
        if (this.appStage === 'Application' && this.sendOutRecordTypeInternalId) {
            return JSON.stringify({ RecordTypeId: { eq: this.sendOutRecordTypeInternalId } });
        } else if (this.appStage === 'Send Out' && this.sendOutRecordTypeExternalId) {
            return JSON.stringify({ RecordTypeId: { eq: this.sendOutRecordTypeExternalId } });
        }
        return JSON.stringify({});
    }

    handleSave(event) {
        const updates = event.detail.draftValues.map(draft => ({
            fields: {
                Id: draft.Id,
                Interview_Feedback__c: draft.Interview_Feedback__c
            }
        }));
    
        const promises = updates.map(updateRecord);
    
        Promise.all(promises)
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Interview Feedback updated successfully',
                    variant: 'success'
                }));
                this.draftValues = [];
    
                return getInterviewSchedules({
                    recordId: this.recordId,
                    recordTypeId: this.appStage === 'Internal Interview'
                        ? this.sendOutRecordTypeInternalId
                        : this.sendOutRecordTypeExternalId
                }).then(data => {
                    this.tableData = data.map(row => ({
                        Id: row.Id,
                        Interview_Level__c: row.Interview_Level__c,
                        TR1__Interview_Date_Time__c: row.TR1__Interview_Date_Time__c,
                        Interview_Feedback__c: row.Interview_Feedback__c
                    }));
                });
            })
            .catch(error => {
                console.error('Update error:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error updating records',
                    message: error.body?.message || 'Unknown error',
                    variant: 'error'
                }));
            });
    }
}