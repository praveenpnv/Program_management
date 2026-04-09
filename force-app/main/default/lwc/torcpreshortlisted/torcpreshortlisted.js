import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

import getMatches from '@salesforce/apex/JobMatchController.getMatches';
import addToList from '@salesforce/apex/JobMatchController.addToList';
import getOrgId from '@salesforce/apex/JobMatchController.getOrgId';
import getJobCreatedDate from '@salesforce/apex/JobMatchController.getJobCreatedDate';

import { getRecord } from 'lightning/uiRecordApi';
import TORC_ID_FIELD from '@salesforce/schema/TR1__Job__c.Torc_Id__c';

export default class Torcpreshortlisted extends NavigationMixin(LightningElement) {
    @api recordId;
    @track matches = [];
    @track selectedIds = [];
    @track jobCreatedDate;
    @track showStandardMessage = false;
    orgId;
    error;
    torcId;

    wiredJobResult;
    wiredResult;

    hasStartedPolling = false;
    hasStartedMatchPolling = false;
    refreshInterval;
    matchPollingInterval;

    @wire(getJobCreatedDate, { jobRecordId: '$recordId' })
    wiredJobCreatedDate({ data, error }) {
        if (data) {
            this.jobCreatedDate = new Date(data);
            this.evaluateMatchMessage();
        } else if (error) {
            console.error('Error fetching CreatedDate:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [TORC_ID_FIELD] })
    wiredJob(result) {
        this.wiredJobResult = result;
        if (result.data) {
            const field = result.data.fields.Torc_Id__c;
            if (field && field.value) {
                this.torcId = field.value;
                clearInterval(this.refreshInterval);
            }
        } else if (result.error) {
            console.error('Error fetching Torc_Id__c:', result.error);
        }
    }

    @wire(getOrgId)
    wiredOrgId({ error, data }) {
        if (data) {
            this.orgId = data;
        } else if (error) {
            console.error('Error fetching Org ID:', error);
        }
    }

    @wire(getMatches, { torcId: '$recordId' }) // update if needed to use torcId
    wiredMatches(result) {
        this.wiredResult = result;
        if (result.data) {
            this.matches = result.data.map(item => ({
                Id: item.Id,
                UserFullName: item.User_Full_Name__c,
                selected: false,
                recordUrl: '/' + item.Contact__c
            }));
            if (this.matches.length > 0) {
                this.error = undefined;
            }
        } else if (result.error) {
            this.error = result.error.body?.message || result.error.message;
        }
    }

    renderedCallback() {
        if (!this.hasStartedPolling) {
            this.hasStartedPolling = true;
            this.refreshInterval = setInterval(() => {
                if (!this.torcId) {
                    refreshApex(this.wiredJobResult);
                    console.log('Waiting.......');
                }
                else
                {
                   console.log('Got Torc ID.......'); 
                }
            }, 4000); // Poll every 4 seconds
        }

        if (this.torcId && !this.hasStartedMatchPolling) {
            this.hasStartedMatchPolling = true;
            this.startMatchPolling();
        }
    }

    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        if (this.matchPollingInterval) {
            clearInterval(this.matchPollingInterval);
        }
    }

    startMatchPolling() {
        console.log('starting match polling');
        this.error = '⏳ Fetching candidates...';
        this.matchPollingInterval = setInterval(() => {
            refreshApex(this.wiredResult).then(() => {
                const now = new Date();
                const diffInMs = now - this.jobCreatedDate;
                const diffInMinutes = diffInMs / 60000;

                if (this.matches.length === 0) {
                    if (diffInMinutes < 3) {
                        this.error = '⏳ Taking some time to find candidates...';
                    } else {
                        this.error = '⚠️ No candidates found.';
                        clearInterval(this.matchPollingInterval);
                    }
                } else {
                    this.error = undefined;
                    clearInterval(this.matchPollingInterval);
                }
            }).catch(error => {
                this.error = error.body?.message || error.message;
                clearInterval(this.matchPollingInterval);
            });
        }, 7000); // Poll every 7 seconds
    }

    evaluateMatchMessage() {
        if (!this.jobCreatedDate) return;
        const now = new Date();
        const diffInMs = now - this.jobCreatedDate;
        const diffInMinutes = diffInMs / 60000;
        this.showStandardMessage = diffInMinutes > 3;
    }

    handleCheckboxChange(event) {
        const id = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.matches = this.matches.map(match => ({
            ...match,
            selected: match.Id === id ? isChecked : match.selected
        }));
        this.selectedIds = this.matches.filter(m => m.selected).map(m => m.Id);
    }

    handleAdd() {
        if (this.selectedIds.length === 0) return;
        addToList({ matchIds: this.selectedIds })
            .then(() => {
                this.selectedIds = [];
                return refreshApex(this.wiredResult);
            })
            .then(() => {
                this.matches = this.matches.map(m => ({ ...m, selected: false }));
            })
            .catch(err => {
                this.error = err.body.message;
            });
    }

    handleResync() {
        if (this.wiredResult) {
            refreshApex(this.wiredResult)
                .then(() => {
                    this.selectedIds = [];
                    this.matches = this.matches.map(m => ({ ...m, selected: false }));
                })
                .catch(error => {
                    this.error = error.body?.message || error.message;
                });
        }
    }

    handleRedirectToTorc() {
        if (this.torcId) {
            const url = `/lightning/n/torcSearch?c__torcjobid=${this.torcId}&c__torcjobsfdcid=${this.recordId}`;
            window.location.href = url;
        }
    }

    handleRedirectToTorcFederated() {
        if (this.torcId) {
            const url = `/lightning/n/torcSearch?c__torcjobid=${this.torcId}&c__torcjobsfdcid=${this.recordId}&c__fedrated=1`;
            window.location.href = url;
        }
    }

    handleTextKernelClick() {
        if (this.orgId) {
            const matchQuery = `jobId=${this.orgId}_${this.recordId}&selectedTab=candidateSearch`;
            const encodedQuery = encodeURIComponent(matchQuery);
            const url = `/lightning/n/Textkernel1__TextkernelPortal?Textkernel1__match_query=${encodedQuery}`;
            window.open(url, '_blank');
        }
    }

    handleRefreshMatches() {
        if (this.wiredResult) {
            refreshApex(this.wiredResult)
                .then(() => {
                    this.selectedIds = [];
                    this.matches = this.matches.map(m => ({ ...m, selected: false }));
                    const now = new Date();
                    const diffInMs = now - this.jobCreatedDate;
                    const diffInMinutes = diffInMs / 60000;
                    this.showStandardMessage = diffInMinutes > 4;
                })
                .catch(error => {
                    this.error = error.body?.message || error.message;
                });
        }
    }
}