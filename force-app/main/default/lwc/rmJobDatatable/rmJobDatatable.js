import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getJobs from '@salesforce/apex/JobDatatableController.getJobs';
import updateJobs from '@salesforce/apex/JobDatatableController.updateJobs';
import getTotalJobCount from '@salesforce/apex/JobDatatableController.getTotalJobCount';
import getTeamRecruiters from '@salesforce/apex/JobDatatableController.getTeamRecruiters';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
// import the new datatable
import jobDataTable from 'c/jobDataTable';

const USER_FIELDS = ['User.Dashboard_Role__c'];

export default class RmJobDatatable extends LightningElement {
    @track jobs = [];
    @track draftValues = [];
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalJobs = 0;
    @track userOptions = [];
    @track isSalesManager = false;
    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    subscription = {};
    jobChangeEventChannel = '/data/TR1__Job__ChangeEvent';

    @api selectedUserId; // SUPER USER selected user from parent
    @track isLoading = false;
    
    // computed userId → if parent didn’t set, fallback to logged-in user
    get effectiveUserId() {
        return this.selectedUserId || userId;
    }

    @wire(getRecord, { recordId: userId, fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            const role = data.fields.Dashboard_Role__c.value;
            this.isSalesManager = (role === 'Sales Manager' || role === 'Sales Leader');
        } else if (error) {
            console.error('Error getting user role:', error);
        }
    }

    get columns() {
        return [
            {
                label: 'Job Name',
                fieldName: 'jobUrl',
                type: 'url',
                editable: false,
                sortable: true,
                typeAttributes: {
                    label: { fieldName: 'Name' },
                    target: '_blank'
                }
            },
            { label: 'Job ID', fieldName: 'TR1__Job_Number__c', type: 'text', sortable: true },
            { label: 'Job Owner', fieldName: 'JobOwnerName', type: 'text', sortable: true },
            { 
                label: 'Responsible Recruiter', 
                fieldName: 'Responsible_Recruiter_Label', 
                type: 'userLookup', 
                //editable: !this.isSalesManager,
                typeAttributes: { 
                    value: { fieldName: 'Responsible_Recruiter__c' },
                    label: { fieldName: 'Responsible_Recruiter_Label' },
                    name:  'Responsible_Recruiter__c', // Pass the API name of the field to update
                    options: { fieldName: 'userOptions' }, 
                    placeholder: 'Select Recruiter', 
                    context: { fieldName: 'Id' },
                    variant: 'label-hidden'

                } 
            },
            { label: 'Open Date', fieldName: 'TR1__Open_Date__c', type: 'date', editable: true , sortable: true},
            { label: 'Priority', fieldName: 'Job_priority__c', type: 'text', sortable: true },
            { label: 'Status', fieldName: 'TR1__Status__c', type: 'text', editable: false , sortable: true},
            { label: 'Record Type', fieldName: 'RecordType', type: 'text', editable: false , sortable: true},
            { label: 'Stage Banner', fieldName: 'TR1__Job_Stage_Banner__c', type: 'image', editable: false , sortable: true},
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
        return Math.ceil(this.totalJobs / this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    connectedCallback() {
        //this.registerErrorListener();
        this.handleSubscribe();
        // load users first (so options exist) then jobs
        this.loadUsers()
            .then(() => this.loadJobs())
            .catch(err => {
                console.error('Init error', err);
            });
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('Job change event received: ', JSON.stringify(response));
            // A job record has changed, reload the job data
            this.loadUsers()
            .then(() => this.loadJobs())
            .catch(err => {
                console.error('Init error', err);
            });
        };

        subscribe(this.jobChangeEventChannel, -1, messageCallback).then(response => {
            console.log('Successfully subscribed to channel: ', response.channel);
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        if (this.subscription && Object.keys(this.subscription).length > 0) {
            unsubscribe(this.subscription, response => {
                console.log('Unsubscribed from channel: ', response.subscription);
            });
        }
    }

    async loadUsers() {
        // return promise so caller can chain
        return getTeamRecruiters({ currentUserId: this.effectiveUserId })
            .catch(this )
            .then(result => {
                this.userOptions = result.map(user => ({
                    label: user.Name,
                    value: user.Id
                }));
            })
            .catch(error => {
                console.error('getTeamRecruiters error', error);
                // still resolve to allow jobs load to run
                this.userOptions = [];
            });
    }

 async loadJobs() {
    try {
        // refresh total count
        this.totalJobs = await getTotalJobCount({ currentUserId: this.effectiveUserId });

        // refresh job list
        const result = await getJobs({ pageSize: this.pageSize, pageNumber: this.currentPage, currentUserId: this.effectiveUserId });

        // always create a brand-new array
        this.jobs = result.map(job => {
            // Extract Stage Banner src if present
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

            // let recruiterId = job.Responsible_Recruiter__c;
            // const recruiterInTeam = this.userOptions.some(opt => opt.value === recruiterId);
            // const disableLookup = recruiterId && !recruiterInTeam;

            let recordTypeName = job.RecordType ? job.RecordType.Name : '';
            if (recordTypeName === 'Consulting') {
                recordTypeName = 'Contract';
            }

            return {
                ...job,
                jobUrl: '/' + job.Id,
                Responsible_Recruiter_Label: job.Responsible_Recruiter__r ? job.Responsible_Recruiter__r.Name : '',
                RecordType: recordTypeName,
                JobOwnerName: job.Owner ? job.Owner.Name : '',
                TR1__Job_Stage_Banner__c: bannerUrl,
                userOptions: this.userOptions,
                CollaboratorName: job.Collaborator__r ? job.Collaborator__r.Name : ''
                // disableLookup: disableLookup
            };
        });

        // 🔑 force reactivity by cloning
        this.jobs = [...this.jobs];
        console.log('Jobs loaded', this.jobs);
    } catch (error) {
        console.error(error);
    }
}



       handleSave(event) {
    this.isLoading = true; // 🔵 show loader

    // Merge datatable draft values and custom lookup draft values
    let combinedDrafts = [...event.detail.draftValues];

    this.draftValues.forEach(customDraft => {
        const idx = combinedDrafts.findIndex(d => d.Id === customDraft.Id);
        if (idx > -1) {
            combinedDrafts[idx] = { ...combinedDrafts[idx], ...customDraft };
        } else {
            combinedDrafts.push(customDraft);
        }
    });

    const updatedFields = combinedDrafts.map(draft => {
        return { 
            Id: draft.Id,
            Responsible_Recruiter__c: draft.Responsible_Recruiter__c,
            TR1__Open_Date__c: draft.TR1__Open_Date__c
        };
    });

    if (updatedFields.length === 0) {
        this.isLoading = false; //  hide loader
        return;
    }

    console.log('Records to update', updatedFields);
    updateJobs({ jobsToUpdate: updatedFields })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Jobs updated successfully',
                variant: 'success'
            }));

            const recordIds = updatedFields.map(row => ({ recordId: row.Id }));
            notifyRecordUpdateAvailable(recordIds);

            this.draftValues = [];                
            return this.loadJobs();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error updating jobs',
                message: error.body?.message || error.message,
                variant: 'error'
            }));
        })
        .finally(() => {
            this.isLoading = false; //  always hide loader after finish
        });
}



    handleRefresh() {
        this.draftValues = [];
        this.loadUsers().then(() => this.loadJobs());
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadJobs();
        }
    }

    prevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadJobs();
        }
    }

    onHandleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortDirection);
    }
 
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.jobs));
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
        this.jobs = parseData;
    } 

    registerErrorListener() {
        onError(error => {
            console.error('Received error from server: ', JSON.stringify(error));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Streaming API Error',
                message: 'A real-time update error occurred. Please refresh the page.',
                variant: 'error'
            }));
        });
    }

    handleLookupChange(event) {
        // The event detail comes from the c-userpicklist component
        const eventData = event.detail.data;
        const rowId = eventData.context;
        const fieldName = eventData.name; // This is 'Responsible_Recruiter__c'
        const selectedId = eventData.value;

        // Find the job record in the main data array to update its display label
        const job = this.jobs.find(j => j.Id === rowId);
        if (job) {
            const selectedOption = this.userOptions.find(opt => opt.value === selectedId);
            if (selectedOption) {
                job.Responsible_Recruiter_Label = selectedOption.label;
                // Force the datatable to re-render the row
                this.jobs = [...this.jobs];
            }
        }

        // Find if a draft for this row already exists (e.g., from editing another cell)
        const existingDraft = this.draftValues.find(draft => draft.Id === rowId);

        if (existingDraft) {
            // If it exists, merge the new change into it to prevent data loss
            existingDraft[fieldName] = selectedId;
            // Re-assign to trigger reactivity for the datatable
            this.draftValues = [...this.draftValues];
        } else {
            // Otherwise, create a new draft entry for this row
            const newDraft = { Id: rowId, [fieldName]: selectedId };
            this.draftValues = [...this.draftValues, newDraft];
        }
    }
}