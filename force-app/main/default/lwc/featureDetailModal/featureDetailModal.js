import { LightningElement, api, wire, track } from 'lwc';
import getFeatureWithDetails from '@salesforce/apex/ProjectPlatformController.getFeatureWithDetails';
import saveFeature from '@salesforce/apex/ProjectPlatformController.saveFeature';

const R_CLS = {
    Approved:      'fdm-badge fdm-green',
    Rejected:      'fdm-badge fdm-red',
    'In Progress': 'fdm-badge fdm-blue',
    Delivered:     'fdm-badge fdm-teal',
    Submitted:     'fdm-badge fdm-amber',
    'Under Review':'fdm-badge fdm-purple',
    Draft:         'fdm-badge fdm-grey',
};
const S_CLS = {
    Done:             'fdm-badge fdm-green',
    'In Development': 'fdm-badge fdm-blue',
    Review:           'fdm-badge fdm-purple',
    QA:               'fdm-badge fdm-amber',
    Ready:            'fdm-badge fdm-sky',
    Backlog:          'fdm-badge fdm-grey',
};
const STATUS_CLS = {
    Active:'fdm-badge fdm-green', Planned:'fdm-badge fdm-blue',
    Completed:'fdm-badge fdm-grey', 'On Hold':'fdm-badge fdm-amber',
};

export default class FeatureDetailModal extends LightningElement {
    @api featureId;
    @track _feature = {};
    @track isEditing = false;
    @track _editData = {};
    @track isEditing = false;
    @track _editData = {};
    @track _reqs    = [];
    @track _stories = [];
    @track isLoading = true;

    @wire(getFeatureWithDetails, { featureId: '$featureId' })
    wired({ data, error }) {
        this.isLoading = false;
        if (data) {
            this._feature = data.feature || {};
            this._reqs    = (data.requirements || []).map(r => ({
                ...r,
                statusCls: R_CLS[r.Status__c] || 'fdm-badge fdm-grey',
            }));
            this._stories = (data.stories || []).map(s => ({
                ...s,
                statusCls:   S_CLS[s.Status__c] || 'fdm-badge fdm-grey',
                assigneeName: s.Assigned_To__r?.Name || null,
            }));
        }
        if (error) console.error('featureDetailModal wire error', error);
    }

    get featureName()    { return this._feature?.Name         || 'Feature Details'; }
    get featureDesc()    { return this._feature?.Description__c || ''; }
    get featureStatus()  { return this._feature?.Status__c    || ''; }
    get featurePriority(){ return this._feature?.Priority__c  || ''; }
    get statusCls()      { return STATUS_CLS[this._feature?.Status__c] || 'fdm-badge fdm-grey'; }
    get priCls()         {
        const p = this._feature?.Priority__c;
        return p === 'Critical' ? 'fdm-badge fdm-red'
             : p === 'High'     ? 'fdm-badge fdm-amber'
             : p === 'Medium'   ? 'fdm-badge fdm-blue'
             : 'fdm-badge fdm-grey';
    }
    get reqItems()      { return this._reqs; }
    get storyItems()    { return this._stories.map(s => ({
        ...s, requirementName: s.Requirement__r?.Name || null
    })); }
    get reqCount()      { return this._reqs.length; }
    get storyCount()    { return this._stories.length; }
    get hasReqs()       { return this._reqs.length > 0; }
    get hasStories()    { return this._stories.length > 0; }

    handleClose()    { this.dispatchEvent(new CustomEvent('close')); }

    get editName() { return this._editData.Name || ''; }
    get editDesc() { return this._editData.Description__c || ''; }
    get editStatusIs_Planning()  { return (this._editData.Status__c || '') === 'Planning'; }
    get editStatusIs_Active()    { return (this._editData.Status__c || '') === 'Active'; }
    get editStatusIs_OnHold()    { return (this._editData.Status__c || '') === 'On Hold'; }
    get editStatusIs_Completed() { return (this._editData.Status__c || '') === 'Completed'; }
    get editPriIs_Critical()     { return (this._editData.Priority__c || '') === 'Critical'; }
    get editPriIs_High()         { return (this._editData.Priority__c || '') === 'High'; }
    get editPriIs_Medium()       { return (this._editData.Priority__c || 'Medium') === 'Medium'; }
    get editPriIs_Low()          { return (this._editData.Priority__c || '') === 'Low'; }

    handleEditToggle() { this._editData = { ...this._feature }; this.isEditing = true; }
    handleEditCancel() { this.isEditing = false; }
    handleEditField(e) { this._editData = { ...this._editData, [e.target.dataset.field]: e.target.value }; }
    async handleEditSave() {
        try {
            await saveFeature({ featureJson: JSON.stringify({
                id: this._feature.Id, name: this._editData.Name,
                description: this._editData.Description__c,
                status: this._editData.Status__c, priority: this._editData.Priority__c,
                projectId: this._feature.Project__c,
            })});
            this._feature = { ...this._feature, ...this._editData };
            this.isEditing = false;
            this.dispatchEvent(new CustomEvent('featureupdated', { bubbles:true, composed:true }));
        } catch(e) { console.error('Save feature error', e); }
    }
    stop(e)          { e.stopPropagation(); }
    handleBdClick()  { this.handleClose(); }

    handleNav() {
        this.dispatchEvent(new CustomEvent('navigate', { bubbles:true, composed:true,
            detail:{ recordId: this.featureId, objectApiName:'Feature__c' } }));
    }
    handleReqOpen(e) {
        const id = e.currentTarget.value;
        const r  = this._reqs.find(x => x.Id === id);
        if (r) this.dispatchEvent(new CustomEvent('reqopen', { bubbles:true, composed:true, detail: r }));
    }
    handleReqNav(e) {
        this.dispatchEvent(new CustomEvent('navigate', { bubbles:true, composed:true,
            detail:{ recordId: e.currentTarget.value, objectApiName:'Requirement__c' } }));
    }
    handleStoryOpen(e) {
        const id = e.currentTarget.value;
        const s  = this._stories.find(x => x.Id === id);
        if (s) this.dispatchEvent(new CustomEvent('storyopen', { bubbles:true, composed:true, detail: s }));
    }
    handleStoryNav(e) {
        this.dispatchEvent(new CustomEvent('navigate', { bubbles:true, composed:true,
            detail:{ recordId: e.currentTarget.value, objectApiName:'Story__c' } }));
    }
}