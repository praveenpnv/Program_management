import { LightningElement, track, api } from 'lwc';
import getRecruiterJobs from '@salesforce/apex/JobDatatableController.getRecruiterJobs';
import getRecruiterJobCount from '@salesforce/apex/JobDatatableController.getRecruiterJobCount';
import getRecruiterPlacements from '@salesforce/apex/JobDatatableController.getRecruiterPlacements';
import getRecruiterPlacementCount from '@salesforce/apex/JobDatatableController.getRecruiterPlacementCount';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import userId from '@salesforce/user/Id';

export default class RecruiterJobsDatatable extends LightningElement {
    @api type; // "job" or "placement"
    @api selectedUserId;

    @track records = [];
    @track draftValues = [];
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;

    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    subscription = {};
    channelName;

    get columns() {
        if (this.type === 'Placement') {
            return [
                { label: 'Placement Name', fieldName: 'placementUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, sortable: true },
                { label: 'Candidate Name', fieldName: 'CandidateName', type: 'text', sortable: true },
                { label: 'Client Name', fieldName: 'ClientName', type: 'text', sortable: true },
                { label: 'Start Date', fieldName: 'TR1__Start_Date__c', type: 'date', sortable: true },
                { label: 'Status', fieldName: 'Status_US__c', type: 'text' },
                { label: 'Scheduled End', fieldName: 'Scheduled_End__c', type: 'date' },
                { label: 'Job Owner', fieldName: 'JobOwner', type: 'text' },
                { label: 'Recruiter', fieldName: 'RecruiterName', type: 'text' },
                { label: 'Record Type', fieldName: 'RecordType', type: 'text' },
                { label: 'End in Days', fieldName: 'End_Date_In_Days__c', type: 'coloredCell', initialWidth: 150,
                     typeAttributes: { 
                        value: { 
                            fieldName: 'End_Date_In_Days__c' } 
                        },
                        sortable: true },
                                        

            ];
        }
        return [
            { label: 'Job Name', fieldName: 'jobUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } ,sortable: true  },
            { label: 'Job ID', fieldName: 'TR1__Job_Number__c', type: 'text', sortable: true },
            { label: 'Job Owner', fieldName: 'JobOwnerName', type: 'text', sortable: true },
            { label: 'Responsible Recruiter', fieldName: 'Responsible_Recruiter_Label', type: 'text' },
            { label: 'Open Date', fieldName: 'TR1__Open_Date__c', type: 'date' },
            { label: 'Priority', fieldName: 'Job_priority__c', type: 'text', sortable: true },
            { label: 'Status', fieldName: 'TR1__Status__c', type: 'text' },
            { label: 'Record Type', fieldName: 'RecordType', type: 'text' },
            { label: 'Stage', fieldName: 'TR1__Job_Stage_Banner__c', type: 'image', editable: false, sortable: true },
                    {
                        label: 'Timer',
                        fieldName: 'Id',
                        type: 'jobTimer',
                        editable: false,
                        sortable: true,
                        typeAttributes: {
                            recordId: { fieldName: 'Id' }
                        }
                    }
        ];
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }
    get isFirstPage() {
        return this.currentPage === 1;
    }
    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get typeTitle() {
         return this.type === 'Placement' ? 'Placements' : 'Jobs';
    }   

    // computed userId → if parent didn’t set, fallback to logged-in user
    get effectiveUserId() {
        return this.selectedUserId || userId;
    }

    connectedCallback() {
        this.setupSubscription();
        this.handleSubscribe();
        //this.registerErrorListener();
        this.loadData();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    setupSubscription() {
        if (this.type === 'Placement') {
            this.channelName = '/data/TR1__Placement__ChangeEvent';
        } else {
            // Default to Job events
            this.channelName = '/data/TR1__Job__ChangeEvent';
        }
    }

    handleSubscribe() {
        if (!this.channelName) return;

        const messageCallback = (response) => {
            console.log(`CDC event received for ${this.channelName}:`, JSON.stringify(response));
            this.loadData();
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log(`Successfully subscribed to channel: ${response.channel}`);
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        if (this.subscription && Object.keys(this.subscription).length) {
            unsubscribe(this.subscription, response => {
                console.log('Unsubscribed from channel: ', response.subscription);
            });
        }
    }

    registerErrorListener() {
        onError(error => {
            console.error('Streaming API error: ', JSON.stringify(error));
        });
    }

    loadData() {
        if (this.type === 'Placement') {
            getRecruiterPlacementCount({ currentUserId: this.effectiveUserId })
                .then(result => this.totalRecords = result);

            getRecruiterPlacements({ pageSize: this.pageSize, pageNumber: this.currentPage, currentUserId: this.effectiveUserId })
                .then(result => {
                    this.records = result.map(pl => ({
                            ...pl,
                            placementUrl: '/' + pl.Id,
                            CandidateName: pl.TR1__Person_Placed__r ? pl.TR1__Person_Placed__r.Name : '',
                            ClientName: pl.TR1__Account__r?.Name,
                            RecruiterName: pl.TR1__Candidate_Credit__r ? pl.TR1__Candidate_Credit__r.Name : '',
                            JobOwner: pl.TR1__Job__r?.Owner?.Name,
                            Responsible_Recruiter_Label: pl.TR1__Job__r?.Responsible_Recruiter__r?.Name || '',
                            RecordType: (pl.RecordType?.Name === 'Consulting') 
                                            ? 'Contract' 
                                            : (pl.RecordType ? pl.RecordType.Name : '')
                    }));
                });
              console.log('Placements Loaded'+ JSON.stringify(this.records));  
        } else {
            getRecruiterJobCount({ currentUserId: this.effectiveUserId })
                .then(result => this.totalRecords = result);

            getRecruiterJobs({ pageSize: this.pageSize, pageNumber: this.currentPage, currentUserId: this.effectiveUserId })
                .then(result => {
                    this.records = result.map(job => {
                        let recordTypeName = job.RecordType ? job.RecordType.Name : '';
                        if (recordTypeName === 'Consulting') {
                            recordTypeName = 'Contract';
                        }
                        let bannerUrl = job.TR1__Job_Stage_Banner__c;
                        if (bannerUrl) {
                            const match = bannerUrl.match(/src="([^"]+)"/);
                            if (match) {
                                bannerUrl = match[1];
                                if (!bannerUrl.startsWith('http')) {
                                    bannerUrl = window.location.origin + bannerUrl;
                                }
                            }
                        }
                        return { ...job, jobUrl: '/' + job.Id, Responsible_Recruiter_Label: job.Responsible_Recruiter__r ? job.Responsible_Recruiter__r.Name : '', RecordType: recordTypeName, JobOwnerName: job.Owner ? job.Owner.Name : '', TR1__Job_Stage_Banner__c: bannerUrl };
                    });
                });
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadData();
        }
    }

    prevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadData();
        }
    }

    onHandleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortDirection);
    }
 
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.records));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.records = parseData;
    } 
}