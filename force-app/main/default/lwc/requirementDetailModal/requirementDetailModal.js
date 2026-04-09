import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import UserId from '@salesforce/user/Id';
import NAME_FIELD  from '@salesforce/schema/User.Name';
import getActivitiesForRecord from '@salesforce/apex/ProjectPlatformController.getActivitiesForRecord';
import addActivity            from '@salesforce/apex/ProjectPlatformController.addActivity';
import saveRequirement        from '@salesforce/apex/ProjectPlatformController.saveRequirement';

const S_CLS = {
    Approved:'rdm-badge rdm-green', Rejected:'rdm-badge rdm-red',
    'In Progress':'rdm-badge rdm-blue', Delivered:'rdm-badge rdm-teal',
    Submitted:'rdm-badge rdm-amber', 'Under Review':'rdm-badge rdm-purple',
    Draft:'rdm-badge rdm-grey',
};
const P_CLS = {
    Critical:'rdm-badge rdm-red', High:'rdm-badge rdm-amber',
    Medium:'rdm-badge rdm-blue',  Low:'rdm-badge rdm-grey',
};
const STORY_S_CLS = {
    Done:'rdm-badge rdm-green','In Development':'rdm-badge rdm-blue',
    Review:'rdm-badge rdm-purple', QA:'rdm-badge rdm-amber',
    Backlog:'rdm-badge rdm-grey',  Ready:'rdm-badge rdm-sky',
};

const REQ_STATUSES = ['Draft','Under Review','Approved','Rejected'];

export default class RequirementDetailModal extends LightningElement {
    _req = {};
    @track activityItems = [];
    @track isLoadingActivity = false;
    @track commentDraft = '';
    @track isSavingComment = false;
    @track isEditing = false;
    @track _editData = {};
    @track isSaving = false;

    userId = UserId;
    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    wiredUser;

    get userName()    { return getFieldValue(this.wiredUser.data, NAME_FIELD) || ''; }
    get userInitials(){ const n = this.userName; return n ? n.split(' ').map(p=>p[0]).join('').substring(0,2).toUpperCase() : 'Me'; }

    get requirement() { return this._req; }

    @api
    set requirement(val) {
        this._req = val || {};
        if (this._req.Id) this._loadActivity();
    }

    _loadActivity() {
        if (!this._req.Id) return;
        this.isLoadingActivity = true;
        getActivitiesForRecord({ recordId: this._req.Id })
            .then(data => {
                this.activityItems = (data || []).map(t => ({
                    id:       t.Id,
                    who:      t.Who?.Name || t.Owner?.Name || 'Unknown',
                    initials: (t.Who?.Name || t.Owner?.Name || 'U').split(' ').map(p=>p[0]).join('').substring(0,2).toUpperCase(),
                    body:     t.Description || t.Subject || '',
                    when:     t.CreatedDate ? new Date(t.CreatedDate).toLocaleDateString() : '',
                }));
            })
            .catch(() => { this.activityItems = []; })
            .finally(() => { this.isLoadingActivity = false; });
    }

    get assignedName()     { return this._req?.Assigned_To__r?.Name || '—'; }
    get featureName()      { return this._req?.Feature__r?.Name || '—'; }
    get statusCls()        { return S_CLS[this._req?.Status__c] || 'rdm-badge rdm-grey'; }
    get priCls()           { return P_CLS[this._req?.Priority__c] || 'rdm-badge rdm-grey'; }
    get noActivity()       { return !this.isLoadingActivity && this.activityItems.length === 0; }

    
    get hasLinkedStory()   { return !!this._req?.Auto_Story_Created__c && !!this._req?.Linked_Story__c; }
    get linkedStoryId()    { return this._req?.Linked_Story__c || null; }
    get linkedStoryName()  { return this._req?.Linked_Story__r?.Name || 'View Story'; }
    get linkedStoryStatus(){ return this._req?.Linked_Story__r?.Status__c || ''; }
    get linkedStoryCls()   { return STORY_S_CLS[this._req?.Linked_Story__r?.Status__c] || 'rdm-badge rdm-grey'; }

    get canApprove() {
        return !this._req?.Auto_Story_Created__c &&
               ['Draft','Under Review'].includes(this._req?.Status__c);
    }

    
    get statusOptions() {
        const current = this._req?.Status__c;
        const idx = REQ_STATUSES.indexOf(current);
        return REQ_STATUSES.map((s, i) => ({
            status: s,
            label: (i < idx && s !== 'Rejected') ? '✓' : s,
            isCurrent: i === idx,
            isDone: i < idx && s !== 'Rejected',
            cls: 'rdm-path-btn' +
                 (i < idx && s !== 'Rejected' ? ' rdm-path-done'    : '') +
                 (i === idx                   ? ' rdm-path-current'  : '') +
                 (i > idx && s !== 'Rejected' ? ' rdm-path-future'   : '') +
                 (s === 'Rejected' && i !== idx ? ' rdm-path-reject' : ''),
        }));
    }

    
    get editTitle()    { return this._editData.Name || ''; }
    get editDesc()     { return this._editData.Description__c || ''; }
    get editPriHigh()  { return (this._editData.Priority__c || '') === 'High'; }
    get editPriMed()   { return (this._editData.Priority__c || 'Medium') === 'Medium'; }
    get editPriLow()   { return (this._editData.Priority__c || '') === 'Low'; }
    get editPriCrit()  { return (this._editData.Priority__c || '') === 'Critical'; }
    get editCatNew()   { return (this._editData.Category__c || 'New Request') === 'New Request'; }
    get editCatCR()    { return (this._editData.Category__c || '') === 'Change Request'; }

    handleEditToggle() { this._editData = { ...this._req }; this.isEditing = true; }
    handleEditCancel() { this.isEditing = false; }
    handleEditField(e) { this._editData = { ...this._editData, [e.target.dataset.field]: e.target.value }; }
    async handleEditSave() {
        this.isSaving = true;
        try {
            await saveRequirement({ requirementJson: JSON.stringify({
                id:          this._req.Id,
                name:        this._editData.Name,
                description: this._editData.Description__c,
                priority:    this._editData.Priority__c,
                category:    this._editData.Category__c,
                requestor:   this._editData.Requestor__c,
                projectId:   this._req.Project__c,
                featureId:   this._req.Feature__c,
                status:      this._req.Status__c,
            })});
            this._req = { ...this._req, ...this._editData };
            this.isEditing = false;
            this.dispatchEvent(new CustomEvent('requirementupdated', { bubbles:true, composed:true }));
        } catch(e) { console.error(e); }
        finally { this.isSaving = false; }
    }

    handleStatusChange(e) {
        const newStatus = e.currentTarget.value;
        if (!newStatus || newStatus === this._req?.Status__c) return;
        this.dispatchEvent(new CustomEvent('statuschange', { bubbles:true, composed:true,
            detail: { reqId: this._req.Id, newStatus } }));
        this._req = { ...this._req, Status__c: newStatus };
    }

    handleClose()   { this.dispatchEvent(new CustomEvent('close')); }
    stop(e)         { e.stopPropagation(); }
    handleBdClick() { this.handleClose(); }

    handleApprove() {
        this.dispatchEvent(new CustomEvent('approve', { bubbles:true, composed:true, detail: this._req.Id }));
    }

    handleNav() {
        this.dispatchEvent(new CustomEvent('navigate', { bubbles:true, composed:true,
            detail:{ recordId: this._req.Id, objectApiName:'Requirement__c' } }));
    }

    handleStoryOpen(e) {
        const storyId = e.currentTarget.value;
        
        this.dispatchEvent(new CustomEvent('storylink', { bubbles:true, composed:true,
            detail: storyId }));
    }

    handleCommentChange(e) { this.commentDraft = e.target.value; }
    handleCancelComment()  { this.commentDraft = ''; }

    handleAddComment() {
        const body = (this.commentDraft || '').trim();
        if (!body) return;
        this.isSavingComment = true;
        addActivity({ recordId: this._req.Id, body })
            .then(() => {
                this.commentDraft = '';
                this._loadActivity();
            })
            .catch(e => console.error(e))
            .finally(() => { this.isSavingComment = false; });
    }
}