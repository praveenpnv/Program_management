import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import UserId from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import searchMentionUsers from '@salesforce/apex/ProjectPlatformController.searchMentionUsers';
import getActivitiesForRecord from '@salesforce/apex/ProjectPlatformController.getActivitiesForRecord';
import addActivity            from '@salesforce/apex/ProjectPlatformController.addActivity';
import getAuditsByStory       from '@salesforce/apex/ProjectPlatformController.getAuditsByStory';
import saveStory              from '@salesforce/apex/ProjectPlatformController.saveStory';
import getProjects from '@salesforce/apex/ProjectPlatformController.getProjects';
import getFeaturesByProject from '@salesforce/apex/ProjectPlatformController.getFeaturesByProject';
import getLinkedStories from '@salesforce/apex/ProjectPlatformController.getLinkedStories';
import linkStories from '@salesforce/apex/ProjectPlatformController.linkStories';
import deleteStoryLink from '@salesforce/apex/ProjectPlatformController.deleteStoryLink';
import searchStoriesToLink from '@salesforce/apex/ProjectPlatformController.searchStoriesToLink';
import getRequirementsByProjects from '@salesforce/apex/ProjectPlatformController.getRequirementsByProjects';
import STORY_OBJECT from '@salesforce/schema/Story__c';
import STATUS_FIELD from '@salesforce/schema/Story__c.Status__c';

//const STATUSES = ['Backlog','In Progress','Developed','QA Approved','UAT','UAT Approved','Production','Done'];
const S_LABELS = {
    'Backlog':'Backlog','In Progress':'In Progress','Developed':'Developed',
    'QA Approved':'QA Approved','UAT':'UAT',
    'UAT Approved':'UAT ✓','Production':'Production','Done':'Done'
};
const S_CLS = {
    'Backlog':'badge bg-grey','In Progress':'badge bg-blue','Developed':'badge bg-purple',
    'QA Approved':'badge bg-teal','UAT':'badge bg-indigo',
    'UAT Approved':'badge bg-sky','Production':'badge bg-orange','Done':'badge bg-green', 'On Hold':'badge bg-Red'
};
const P_CLS = {
    Critical:'badge bg-red',High:'badge bg-amber',Medium:'badge bg-blue',Low:'badge bg-grey',
};

export default class StoryDetailModal extends LightningElement {

    @track _story = {};
    @track activityItems = [];
    @track isLoadingActivity = false;
    @track commentDraft = '';
    @track isSavingComment = false;
    @track auditItems = [];
    @track isLoadingAudit = false;
    @track isEditing = false;
    @track _editData = {};
    @track isSavingEdit = false;
    @track dynamicStatuses = [];
    @track allProjects = [];
    @track projectFeatures = [];
    @track linkedStories = [];
    @track isLoadingLinks = false;
    @track isEditingLinks = false;
    @track isLinking = false;
    @track linkSearchTerm = '';
    @track selectedLinkType = 'Relates To';
    @track linkSearchTerm = '';
    @track selectedTargetStoryId = null;
    @track showStoryDropdown = false;
    @track storySearchResults = [];
    @track projectRequirements = [];

    userId = UserId;
    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    wiredUser;

    get userName()    { return getFieldValue(this.wiredUser.data, NAME_FIELD) || ''; }
    get userInitials(){ const n = this.userName; return n ? n.split(' ').map(p=>p[0]).join('').substring(0,2).toUpperCase() : 'Me'; }
    @wire(getObjectInfo, { objectApiName: STORY_OBJECT })
    storyInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$storyInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })

    wiredStatusValues({ data, error }) {
        if (data) {
            this.dynamicStatuses = data.values.map(val => val.value);
        } else if (error) {
            console.error('Error fetching status picklist values', error);
        }
    }
    connectedCallback() {
        getProjects()
            .then(data => { this.allProjects = data || []; })
            .catch(err => console.error('Error fetching projects', err));
    }
    get hasStoryResults() { return this.storySearchResults.length > 0; }
    @api
    refreshHistory() {
        console.log('refreshHistory called');
        this.isLoadingAudit = true;
        // Wait 500ms to guarantee the Salesforce database has fully committed the new Audit record
        setTimeout(() => {
            this._loadAudits();
        }, 500);
    }
    get story() { return this._story; }

    @api
    set story(val) {
        const isNewStory = (!this._story || this._story.Id !== val?.Id);
        this._story = val || {};
        console.log('getStories==> ', JSON.stringify(this._story));
        if (this._story.Id && isNewStory) {
            this._loadActivity();
            this._loadAudits();
            this._loadLinkedStories(); 
            
            // Gather ALL tagged project IDs into a single array
            const allProjectIds = [];
            
            if (this._story.Project__c) {
                allProjectIds.push(this._story.Project__c);
            } 
                
            if (this._story.Story_Projects__r) {
                this._story.Story_Projects__r.forEach(link => {
                    if (!allProjectIds.includes(link.Project__c)) {
                        allProjectIds.push(link.Project__c);
                    }
                });
            }

            if (allProjectIds.length > 0) {
                this._loadFeatures(allProjectIds); 
                this._loadRequirements(allProjectIds);
            }
        }
    }
    get requirementOptions() {
        const currentSelectedId = this._editData.requirement !== undefined ? this._editData.requirement : this._story?.Requirement__c;
        return this.projectRequirements.map(req => ({
            id: req.Id,
            name: req.Name,
            selected: req.Id === currentSelectedId
        }));
    }
    get projectNames() { 
        if (this._story?.Story_Projects__r && this._story.Story_Projects__r.length > 0) {
            return this._story.Story_Projects__r.map(link => link.Project__r.Name).join(', ');
        }
        return '—'; 
    }
    get taggedProjectsList() {
        if (this._story?.Story_Projects__r && this._story.Story_Projects__r.length > 0) {
            return this._story.Story_Projects__r.map(link => ({
                id: link.Project__c,
                name: link.Project__r.Name
            }));
        }
        return [];
    }
    
    get hasTaggedProjects() {
        return this.taggedProjectsList.length > 0;
    }
    // NEW: For Edit Mode - Projects already selected (shows as pills)
    get selectedProjectsList() {
        const ids = this._editData.projectIds || [];
        return this.allProjects.filter(p => ids.includes(p.id));
    }

    // NEW: For Edit Mode - Projects NOT YET selected (shows in the dropdown)
    get availableProjects() {
        const ids = this._editData.projectIds || [];
        return this.allProjects.filter(p => !ids.includes(p.id));
    }
    _loadFeatures(projectIdsArray) {
        if (!projectIdsArray || projectIdsArray.length === 0) {
            this.projectFeatures = [];
            return;
        }
        
        getFeaturesByProject({ projectIds: projectIdsArray })
            .then(data => {
                this.projectFeatures = (data || []).map(f => ({
                    Id: f.Id,
                    // Format it so they know which project the feature belongs to
                    Name: f.Project__r ? `${f.Project__r.Name} - ${f.Name}` : f.Name
                }));
            })
            .catch(err => console.error('Error fetching features', err));
    }
    _loadRequirements(projectIdsArray) {
        if (!projectIdsArray || projectIdsArray.length === 0) {
            this.projectRequirements = [];
            return;
        }
        
        getRequirementsByProjects({ projectIds: projectIdsArray })
            .then(data => {
                this.projectRequirements = (data || []).map(r => ({
                    Id: r.Id,
                    // Format: "Project A - Security Requirement"
                    Name: r.Project__r ? `${r.Project__r.Name} - ${r.Name}` : r.Name
                }));
            })
            .catch(err => console.error('Error fetching requirements', err));
    }
    // --- LINKED STORIES LOGIC ---
    get hasLinkedStories() { return this.linkedStories && this.linkedStories.length > 0; }

    _loadLinkedStories() {
        if (!this._story.Id) return;
        this.isLoadingLinks = true;
        getLinkedStories({ storyId: this._story.Id })
            .then(result => {
                this.linkedStories = (result || []).map(link => ({
                    ...link,
                    // Use your existing S_CLS dictionary for the badge colors
                    statusCls: S_CLS[link.Target_Story__r?.Status__c] || 'badge bg-grey' 
                }));
            })
            .catch(error => console.error('Error loading links', error))
            .finally(() => { this.isLoadingLinks = false; });
    }

    handleToggleLinkEdit() { 
        this.isEditingLinks = !this.isEditingLinks; 
        this.linkSearchTerm = '';
        this.selectedTargetStoryId = null;
        this.showStoryDropdown = false;
        this.selectedLinkType = 'Relates To';
    }
    
    handleLinkSearchChange(e) { this.linkSearchTerm = e.target.value; }
    handleLinkTypeChange(e) { this.selectedLinkType = e.target.value; }

    handleStorySearchKeyup(e) {
        this.linkSearchTerm = e.target.value;
        this.selectedTargetStoryId = null; // Clear the hidden ID if they start typing again
        
        if (this.linkSearchTerm.length >= 2) {
            this.showStoryDropdown = true;
            searchStoriesToLink({ searchTerm: this.linkSearchTerm, currentStoryId: this._story.Id })
                .then(results => {
                    this.storySearchResults = results || [];
                })
                .catch(err => console.error('Search error:', err));
        } else {
            this.showStoryDropdown = false;
            this.storySearchResults = [];
        }
    }

    handleStorySelect(e) {
        // Capture the ID behind the scenes, but show the Name in the input box!
        this.selectedTargetStoryId = e.currentTarget.dataset.id;
        this.linkSearchTerm = e.currentTarget.dataset.name;
        this.showStoryDropdown = false;
    }

    handleStorySearchFocus() {
        if (this.linkSearchTerm.length >= 2) this.showStoryDropdown = true;
    }

    handleStorySearchBlur() {
        // Small delay so the user's click on the dropdown registers before it hides
        setTimeout(() => { this.showStoryDropdown = false; }, 200);
    }

    handleSaveLink() {
        if (!this.selectedTargetStoryId) {
            // Optional: You could show a toast here saying "Please select a story from the list"
            return; 
        }
        
        this.isLinking = true;
        
        linkStories({ 
            sourceId: this._story.Id, 
            targetId: this.selectedTargetStoryId, 
            linkType: this.selectedLinkType 
        })
        .then(newLink => {
            const newLinkObj = {
                ...newLink,
                statusCls: S_CLS[newLink.Target_Story__r?.Status__c] || 'badge bg-grey'
            };
            this.linkedStories = [...this.linkedStories, newLinkObj];
            this.handleToggleLinkEdit();
        })
        .catch(err => console.error('Error linking story', err))
        .finally(() => { this.isLinking = false; });
    }

    handleUnlinkStory(event) {
        const linkId = event.currentTarget.value;
        // Remove instantly from UI for snappy feeling
        this.linkedStories = this.linkedStories.filter(l => l.Id !== linkId);
        
        deleteStoryLink({ linkId: linkId }).catch(err => {
            console.error('Error deleting link', err);
            this._loadLinkedStories(); // Revert on fail
        });
    }

    handleStoryNav(event) {
        const storyId = event.currentTarget.value;
        this.dispatchEvent(new CustomEvent('storylink', { bubbles:true, composed:true,
            detail: storyId }));
        this.dispatchEvent(new CustomEvent('storyopen', { 
            bubbles: true, composed: true, detail: { Id: event.currentTarget.value } 
        }));
    }

    _loadActivity() {
        if (!this._story.Id) return;
        this.isLoadingActivity = true;
        getActivitiesForRecord({ recordId: this._story.Id })
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
    _loadAudits() {
        if (!this._story.Id) return;
        this.isLoadingAudit = true;
        
        getAuditsByStory({ 
            storyId: this._story.Id, 
            cacheBuster: new Date().getTime().toString() // FORCES a server-side refresh!
        })
        .then(data => {
            this.auditItems = (data || []).map(a => {
                const fromColor = this._statusColor(a.From_Status__c);
                const toColor   = this._statusColor(a.To_Status__c);
                const when = a.Changed_At__c
                    ? new Date(a.Changed_At__c).toLocaleString('en-GB', { day:'2-digit', month:'short', year:'numeric', hour:'2-digit', minute:'2-digit' })
                    : '';
                return {
                    id:          a.Id,
                    fromStatus:  a.From_Status__c || 'Start',
                    toStatus:    a.To_Status__c,
                    who:         a.Changed_By__r ? a.Changed_By__r.Name : 'System',
                    when:        when,
                    fromStyle:   'background:' + fromColor + '18;color:' + fromColor + ';padding:2px 8px;border-radius:8px;font-size:11px;font-weight:700',
                    toStyle:     'background:' + toColor   + '18;color:' + toColor   + ';padding:2px 8px;border-radius:8px;font-size:11px;font-weight:700',
                    dotStyle:    'width:8px;height:8px;border-radius:50%;background:' + toColor + ';flex-shrink:0;margin-top:4px',
                };
            });
        })
        .catch(() => { this.auditItems = []; })
        .finally(() => { this.isLoadingAudit = false; });
    }
    _statusColor(status) {
        const map = {
            'Backlog':'#64748B','In Progress':'#3B82F6','Developed':'#8B5CF6',
            'QA Approved':'#F59E0B','UAT':'#0EA5E9','UAT Approved':'#10B981',
            'Production':'#EF4444','Done':'#22C55E'
        };
        return map[status] || '#64748B';
    }

    get hasAuditItems()  { return this.auditItems && this.auditItems.length > 0; }
    get qaAssigneeName() { return this._story.QA_Assignee__r ? this._story.QA_Assignee__r.Name : null; }

    get storyId()       { return this._story?.Story_Number__c || this._story?.Name || ''; }
    get assignedName()  { return this._story?.Assigned_To__r?.Name || '—'; }
    get releaseName()   { return this._story?.Release__r?.Name     || '—'; }
    get reqName()       { return this._story?.Requirement__r?.Name || '—'; }
    get hasLinkedReq()  { return !!this._story?.Requirement__c; }
    get statusCls()     { return S_CLS[this._story?.Status__c]   || 'badge bg-grey'; }
    get priCls()        { return P_CLS[this._story?.Priority__c] || 'badge bg-grey'; }
    get noActivity()    { return !this.isLoadingActivity && this.activityItems.length === 0; }
    get dueCls() {
        const d = this._story?.Due_Date__c;
        if (!d) return 'sdm-val';
        return new Date(d) < new Date() && this._story?.Status__c !== 'Done'
            ? 'sdm-val sdm-overdue' : 'sdm-val';
    }
    get projectName() { 
        if (this._story?.Project__r?.Name) {
            return this._story.Project__r.Name;
        }
        // If the relationship name is missing, find it dynamically using the ID
        if (this._story?.Project__c && this.allProjects.length > 0) {
            const foundProj = this.allProjects.find(p => p.id === this._story.Project__c);
            if (foundProj) return foundProj.name;
        }
        return '—'; 
    }
    get projectOptions() {
        const currentSelectedId = this._editData.project !== undefined ? this._editData.project : this._story?.Project__c;
        return this.allProjects.map(p => ({
            id: p.id,
            name: p.name,
            selected: p.id === currentSelectedId
        }));
    }

    get statusOptions() {
        const current = this._story?.Status__c;
        const STATUSES = this.dynamicStatuses.length ? this.dynamicStatuses : [];
        const idx     = STATUSES.indexOf(current);
        return STATUSES.map((s, i) => ({
            status:    s,
            label:     S_LABELS[s] || s,
            isCurrent: i === idx,
            isDone:    i < idx,
            cls: 'sdm-path-btn' +
                 (i < idx    ? ' sdm-path-done'    : '') +
                 (i === idx  ? ' sdm-path-current' : '') +
                 (i > idx    ? ' sdm-path-future'  : ''),
        }));
    }
    get editStatusOptions() {
        const currentSelected = this._editData.status ?? this._story?.Status__c;
        return this.dynamicStatuses.map(status => ({
            label: status,
            value: status,
            selected: status === currentSelected
        }));
    }
    get featureName() { 
        if (this._story?.Feature__r?.Name) {
            return this._story.Feature__r.Name;
        }
        if (this._story?.Feature__c && this.projectFeatures.length > 0) {
            const foundFeat = this.projectFeatures.find(f => f.Id === this._story.Feature__c);
            if (foundFeat) return foundFeat.Name;
        }
        return '—'; 
    }
    get featureOptions() {
        const currentSelectedId = this._editData.feature !== undefined ? this._editData.feature : this._story?.Feature__c;
        return this.projectFeatures.map(f => ({
            id: f.Id,
            name: f.Name,
            selected: f.Id === currentSelectedId
        }));
    }

    get editName()    { return this._editData.name    ?? (this._story?.Name || ''); }
    get editDesc()    { 
        console.log('storyDescription:- ', this._story.Description__c);
        return this._editData.description    ?? (this._story?.Description__c || ''); }
    get editBusDesc() { return this._editData.businessDescription ?? (this._story?.Business_Description__c || ''); }
    get editAC()      { return this._editData.acceptanceCriteria ?? (this._story?.Acceptance_Criteria__c || ''); }
    get editPoints()  { return this._editData.storyPoints ?? (this._story?.Story_Points__c ?? ''); }
    get editSprint()  { return this._editData.sprint  ?? (this._story?.Sprint__c || ''); }
    get editDueDate() { return this._editData.dueDate ?? (this._story?.Due_Date__c || ''); }
    
    // --- SIDEBAR EDIT GETTERS ---
    get editType()        { return this._editData.type       ?? (this._story?.Story_Type__c || ''); }
    get editProject()     { return this._editData.project    ?? (this._story?.Project__r?.Name || ''); }
    get editFeature()     { return this._editData.feature    ?? (this._story?.Feature__c || ''); }
    get editRelease()     { return this._editData.release    ?? (this._story?.Release__c || ''); }
    get editReporter()    { return this._editData.reporter   ?? (this._story?.Requestor__c || ''); }
    get editRequirement() { return this._editData.requirement?? (this._story?.Requirement__c || ''); }

    // Use specific getters for the lookup display names
    get editAssignedToName() { return this._editData.assignedToName ?? (this._story?.Assigned_To__r?.Name || ''); }
    get editQaAssigneeName() { return this._editData.qaAssigneeName ?? (this._story?.QA_Assignee__r?.Name || ''); }

    get editAssignedToObj() {
        const id = this._editData.assignedToId !== undefined ? this._editData.assignedToId : this._story?.Assigned_To__c;
        const name = this._editData.assignedToName !== undefined ? this._editData.assignedToName : this._story?.Assigned_To__r?.Name;
        
        return id ? { id: id, name: name } : null;
    }

    get editQaAssigneeObj() {
        const id = this._editData.qaAssigneeId !== undefined ? this._editData.qaAssigneeId : this._story?.QA_Assignee__c;
        const name = this._editData.qaAssigneeName !== undefined ? this._editData.qaAssigneeName : this._story?.QA_Assignee__r?.Name;
        
        return id ? { id: id, name: name } : null;
    }
    
    // get editStatBacklog()    { return (this._editData.status ?? this._story?.Status__c) === 'Backlog'; }
    // get editStatInProgress() { return (this._editData.status ?? this._story?.Status__c) === 'In Progress'; }
    // get editStatDeveloped()  { return (this._editData.status ?? this._story?.Status__c) === 'Developed'; }
    // get editStatQA()         { return (this._editData.status ?? this._story?.Status__c) === 'QA Approved'; }
    // get editStatUAT()        { return (this._editData.status ?? this._story?.Status__c) === 'UAT'; }
    // get editStatUATApp()     { return (this._editData.status ?? this._story?.Status__c) === 'UAT Approved'; }
    // get editStatProd()       { return (this._editData.status ?? this._story?.Status__c) === 'Production'; }
    // get editStatDone()       { return (this._editData.status ?? this._story?.Status__c) === 'Done'; }
    // get editStatHold()       { return (this._editData.status ?? this._story?.Status__c) === 'On Hold'; }
    get editPriCritical() { return (this._editData.priority ?? this._story?.Priority__c) === 'Critical'; }
    get editPriHigh()     { return (this._editData.priority ?? this._story?.Priority__c) === 'High'; }
    get editPriMed()      { return (this._editData.priority ?? this._story?.Priority__c) === 'Medium'; }
    get editPriLow()      { return (this._editData.priority ?? this._story?.Priority__c) === 'Low'; }

    // --- LOOKUP HANDLERS ---
    handleAssignedToSelect(e) { 
        this._editData = { 
            ...this._editData, 
            assignedToId: e.detail.id, 
            assignedToName: e.detail.name 
        };
    }
    handleAssignedToClear() { 
        this._editData = { ...this._editData, assignedToId: null, assignedToName: '' };
    }
    handleQaAssigneeSelect(e) {
        this._editData = { 
            ...this._editData, 
            qaAssigneeId: e.detail.id, 
            qaAssigneeName: e.detail.name 
        };
    }
    handleQaAssigneeClear() {
        this._editData = { ...this._editData, qaAssigneeId: null, qaAssigneeName: '' };
    }
    handleAddProject(e) {
        const projId = e.target.value;
        if (!projId) return;
        const updatedProjectIds = [...(this._editData.projectIds || []), projId];
        // Add the selected ID to the array
        this._editData = { ...this._editData, projectIds: updatedProjectIds };
        e.target.value = ''; // Reset the dropdown back to placeholder
        this._loadFeatures(updatedProjectIds);
        this._loadRequirements(allProjectIds);
    }

    handleRemoveProject(e) {
        const projId = e.currentTarget.dataset.id;
        const updatedProjectIds = this._editData.projectIds.filter(id => id !== projId);
        this._editData = { ...this._editData, projectIds: updatedProjectIds };
        this._loadFeatures(updatedProjectIds);
        this._loadRequirements(allProjectIds);
    }
    handleEditToggle() { 
        this._editData = {
            // Pre-load the array of project IDs when Edit is clicked
            projectIds: this.taggedProjectsList.map(p => p.id)
        }; 
        this.isEditing = !this.isEditing; 
    }
    handleEditCancel() { this._editData = {}; this.isEditing = false; }
    handleEditField(e) { 
        const field = e.target.dataset.field;
        const val = e.target.value;
        this._editData = { ...this._editData, [field]: val }; 
        if (field === 'project') {
            this._editData.feature = ''; // Clear the selected feature
            this._loadFeatures(val);     // Fetch new features for the newly selected project
        }
    }
    
    async handleEditSave() {
        this.isSavingEdit = true;
        try {
            // 1. Grab the latest project IDs (either the edited ones, or keep the existing ones)
            const updatedProjectIds = this._editData.projectIds !== undefined 
                ? this._editData.projectIds 
                : this.taggedProjectsList.map(p => p.id);

            const payload = {
                id:                  this._story.Id,
                name:                this._editData.name                ?? this._story.Name,
                description:         this._editData.description         ?? this._story.Description__c,
                businessDescription: this._editData.businessDescription ?? this._story.Business_Description__c,
                acceptanceCriteria:  this._editData.acceptanceCriteria  ?? this._story.Acceptance_Criteria__c,
                priority:            this._editData.priority            ?? this._story.Priority__c,
                storyPoints:         this._editData.storyPoints         ?? this._story.Story_Points__c,
                sprint:              this._editData.sprint              ?? this._story.Sprint__c,
                dueDate:             this._editData.dueDate             ?? this._story.Due_Date__c,
                status:              this._editData.status              ?? this._story.Status__c,
                type:                this._editData.type                ?? this._story.Story_Type__c,
                feature:             this._editData.feature             ?? this._story.Feature__c,
                release:             this._editData.release             ?? this._story.Release__c,
                reporter:            this._editData.reporter            ?? this._story.Requestor__c,
                requirement:         this._editData.requirement         ?? this._story.Requirement__c,
                assignedToId:        this._editData.assignedToId !== undefined ? this._editData.assignedToId : this._story.Assigned_To__c,
                qaAssigneeId:        this._editData.qaAssigneeId !== undefined ? this._editData.qaAssigneeId : this._story.QA_Assignee__c,
                blocked:             this._editData.blocked !== undefined ? this._editData.blocked : (this._story.Blocked__c || false),
                projectIds:          updatedProjectIds // The multi-select array!
            };

            await saveStory({ storyJson: JSON.stringify(payload) });
            console.log('handleEdit Payload==> ', JSON.stringify(payload));
            // Fetch the audits (using our new cache-busting method)
            this.refreshHistory(); 

            // 2. Reconstruct the junction object array for the UI Pills
            const newStoryProjects = updatedProjectIds.map(pId => {
                const proj = this.allProjects.find(p => p.id === pId);
                return {
                    Project__c: pId,
                    Project__r: { Name: proj ? proj.name : 'Unknown' }
                };
            });

            // 3. Reconstruct the story object so the read-only view updates immediately
            this._story = {
                ...this._story,
                Name:                    payload.name,
                Description__c:          payload.description,
                Business_Description__c: payload.businessDescription,
                Acceptance_Criteria__c:  payload.acceptanceCriteria,
                Priority__c:             payload.priority,
                Story_Points__c:         payload.storyPoints,
                Sprint__c:               payload.sprint,
                Due_Date__c:             payload.dueDate,
                Status__c:               payload.status,
                Story_Type__c:           payload.type,
                Feature__c:              payload.feature,
                Release__c:              payload.release,
                Requestor__c:            payload.reporter,
                Requirement__c:          payload.requirement,
                Blocked__c:              payload.blocked,

                // Lookups
                Assigned_To__c:          payload.assignedToId,
                Assigned_To__r:          { Name: this._editData.assignedToName !== undefined ? this._editData.assignedToName : this._story.Assigned_To__r?.Name },
                QA_Assignee__c:          payload.qaAssigneeId,
                QA_Assignee__r:          { Name: this._editData.qaAssigneeName !== undefined ? this._editData.qaAssigneeName : this._story.QA_Assignee__r?.Name },
                Feature__r:              { Name: this.projectFeatures.find(f => f.Id === payload.feature)?.Name || this._story.Feature__r?.Name },
                Story_Projects__r:       newStoryProjects,
                Requirement__c: payload.requirement,
                Requirement__r: { 
                    Name: this.projectRequirements.find(r => r.Id === payload.requirement)?.Name || this._story.Requirement__r?.Name 
                }
            };
            
            this._editData = {};
            this.isEditing = false;
            
            // Tell the parent component to refresh the Kanban board in the background
            this.dispatchEvent(new CustomEvent('storyupdated', { bubbles:true, composed:true, detail: this._story.Id }));
            
        } catch(e) { 
            console.error('Save story error', e); 
        } finally { 
            this.isSavingEdit = false; 
        }
    }

    handleClose()   { this.dispatchEvent(new CustomEvent('close')); }
    stop(e)         { e.stopPropagation(); }
    handleBdClick() { this.handleClose(); }

    handleStatusChange(event) {
        const newStatus = event.currentTarget.value;
        if (newStatus === this._story?.Status__c) return;
        this._story = { ...this._story, Status__c: newStatus };
        this.dispatchEvent(new CustomEvent('statuschange', {
            bubbles: true, composed: true,
            detail: { storyId: this._story.Id, newStatus },
        }));
    }
    get isBlocked() { return this._story?.Blocked__c === true; }
    get editBlocked() { return this._editData.blocked !== undefined ? this._editData.blocked : (this._story?.Blocked__c || false); }
    handleEditCheckbox(e) {
        this._editData = { ...this._editData, [e.target.dataset.field]: e.target.checked };
    }
    handleReqOpen(e) {
        const reqId = e.currentTarget.value;
        if (!reqId) return;
        this.dispatchEvent(new CustomEvent('reqopen', {
            bubbles: true, composed: true,
            detail: { Id: reqId }
        }));
    }

    handleNav() {
        this.dispatchEvent(new CustomEvent('navigate', {
            bubbles: true, composed: true,
            detail: { recordId: this._story.Id, objectApiName: 'Story__c' },
        }));
    }

    handleCommentChange(e) { this.commentDraft = e.target.value; }
    handleCancelComment() { 
        this.commentDraft = ''; 
        console.log('handleCancelComment'); 
        const textArea = this.template.querySelector('.sdm-comment-ta');
        if (textArea) {
            textArea.value = '';
        }
        this.savekeyUp = false; 
    }
    @track showMentionMenu = false;
    @track mentionUsers = [];
    @track mentionedIds = []; // Optional: keep track of IDs to send to Apex for notifications
    _mentionSearchTerm = '';
    savekeyUp = false;
    // Updated handleCommentChange (we handle the actual value setting here)
    handleCommentChange(e) { 
        this.commentDraft = e.target.value; 
    }

    // NEW: Listens as the user types to detect the @ symbol
    handleCommentKeyup(e) {
        this.commentDraft = e.target.value;
        const textarea = e.target;
        const cursorPos = textarea.selectionStart;
        this.savekeyUp = true;
        
        // Get the text right before the cursor
        const textBeforeCursor = this.commentDraft.substring(0, cursorPos);
        
        // UPDATED REGEX: Matches '@' and names, but specifically STOPS matching if there is a trailing space!
        const match = textBeforeCursor.match(/@([a-zA-Z0-9]*(?: [a-zA-Z0-9]+)*)$/);

        if (match) {
            this._mentionSearchTerm = match[1];
            this.showMentionMenu = true;
            this._fetchMentionUsers(this._mentionSearchTerm);
        } else {
            // Instantly closes the menu if the regex breaks (e.g., a space is typed after a name)
            this.showMentionMenu = false;
        }
    }

    _fetchMentionUsers(term) {
        searchMentionUsers({ searchTerm: term })
            .then(result => {
                this.mentionUsers = result || [];
            })
            .catch(error => {
                console.error('Error fetching mention users:', error);
                this.mentionUsers = [];
            });
    }

    get hasMentionUsers() { return this.mentionUsers.length > 0; }

    // NEW: Handles the user clicking a name in the dropdown
    handleMentionSelect(e) {
        e.preventDefault(); // Prevents the textarea from losing focus before the click registers

        const selectedName = e.currentTarget.dataset.name;
        const selectedId = e.currentTarget.dataset.id;

        const textarea = this.template.querySelector('.sdm-comment-ta');
        const cursorPos = textarea.selectionStart;

        const textBeforeCursor = this.commentDraft.substring(0, cursorPos);
        const textAfterCursor = this.commentDraft.substring(cursorPos);

        // Replace the search term with the selected name AND add a trailing space
        const newTextBefore = textBeforeCursor.replace(/@([a-zA-Z0-9]*(?: [a-zA-Z0-9]+)*)$/, '@' + selectedName + ' ');

        // Update the draft string
        this.commentDraft = newTextBefore + textAfterCursor;
        
        // Force the textarea UI to update immediately
        textarea.value = this.commentDraft;
        
        // Hard-close the menu
        this.showMentionMenu = false;

        // Keep track of who was mentioned
        if (!this.mentionedIds) this.mentionedIds = [];
        if (!this.mentionedIds.includes(selectedId)) {
            this.mentionedIds.push(selectedId);
        }

        // Set cursor position right after the newly inserted name and space
        const newCursorPos = newTextBefore.length;
        textarea.setSelectionRange(newCursorPos, newCursorPos);
        textarea.focus();
    }
    
    handleAddComment() {
        const body = (this.commentDraft || '').trim();
        if (!body) return;
        this.isSavingComment = true;
        addActivity({ recordId: this._story.Id, body })
            .then(() => {
                this.commentDraft = '';
                const textArea = this.template.querySelector('.sdm-comment-ta');
                if (textArea) {
                    textArea.value = '';
                }
                this._loadActivity();
                this.savekeyUp = false;
            })
            .catch(e => console.error(e))
            .finally(() => { this.isSavingComment = false; });
    }
}