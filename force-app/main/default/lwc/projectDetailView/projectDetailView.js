import { LightningElement, api, track } from 'lwc';
import saveProject from '@salesforce/apex/ProjectPlatformController.saveProject';
import HAS_QA_APPROVER_PERM from '@salesforce/customPermission/QA_Board_Approver';
import HAS_UAT_APPROVER_PERM from '@salesforce/customPermission/UAT_Board_Approver';

const PROJECT_STAGES  = ['Initiation','Planning','Execution','Monitoring','Closure'];
const RELEASE_STAGES  = ['Planning','Development','Code Freeze','UAT','Ready for Release','Released'];

const STORY_BOARD_COLS = [
    { status:'Backlog',      label:'Backlog',      hdrStyle:'background:#F1F5F9;color:#475569' },
    { status:'In Progress',  label:'In Progress',  hdrStyle:'background:#EFF6FF;color:#2563EB' },
    { status:'Developed',    label:'Developed',    hdrStyle:'background:#F5F3FF;color:#7C3AED' },
];

const QA_BOARD_COLS = [
    { status:'Developed',    label:'Developed',    hdrStyle:'background:#F5F3FF;color:#7C3AED' },
    { status:'QA Approved',   label:'QA Approved',   hdrStyle:'background:#F0FDF4;color:#16A34A' },
];

const ALL_STATUSES = ['Backlog','In Progress','Developed','QA Approved','UAT','UAT Approved','Production','Done'];

const KANBAN_STATUSES = ALL_STATUSES;

const TABS = [
    { id:'kanban',       label:'Request Board' },
    { id:'qaboard',      label:'QA Board' },
    { id:'features',     label:'Features' },
    { id:'requirements', label:'Requirements' },
    { id:'releases',     label:'Releases' },
    { id:'supportboard', label:'Support Board' },
];

const STATUS_CLS = {
    'On going':   'pdv-badge pdv-green',
    'Not Started':'pdv-badge pdv-blue',
    Pending:      'pdv-badge pdv-amber',
    'On Hold':    'pdv-badge pdv-red',
    Continues:    'pdv-badge pdv-sky',
    Delivered:    'pdv-badge pdv-teal',
    Active:       'pdv-badge pdv-green',
    Planning:     'pdv-badge pdv-blue',
    Completed:    'pdv-badge pdv-teal',
};
const METHOD_CLS = {
    Scrum:'pdv-badge pdv-purple', SAFe:'pdv-badge pdv-teal',
    Kanban:'pdv-badge pdv-blue', Waterfall:'pdv-badge pdv-grey',
};
const PRI_CLS = {
    Critical:'pdv-badge pdv-red', High:'pdv-badge pdv-orange',
    Medium:'pdv-badge pdv-amber', Low:'pdv-badge pdv-grey',
};
const REQ_STATUS_CLS = {
    Approved:'pdv-badge pdv-green', Rejected:'pdv-badge pdv-red',
    'In Progress':'pdv-badge pdv-blue', Delivered:'pdv-badge pdv-teal',
    Submitted:'pdv-badge pdv-amber', 'Under Review':'pdv-badge pdv-purple',
    Draft:'pdv-badge pdv-grey',
};
const STORY_STATUS_CLS = {
    Backlog:'pdv-badge pdv-grey',      'In Progress':'pdv-badge pdv-blue',
    Developed:'pdv-badge pdv-purple',  'QA Approved':'pdv-badge pdv-teal',
    UAT:'pdv-badge pdv-indigo',        'UAT Approved':'pdv-badge pdv-sky',
    Production:'pdv-badge pdv-orange', Done:'pdv-badge pdv-green',
};
const REL_STEP_CLS = {
    done:'pdv-rstep pdv-rstep-done', active:'pdv-rstep pdv-rstep-active', future:'pdv-rstep pdv-rstep-future',
};

export default class ProjectDetailView extends LightningElement {
    
    @api project = {};
    @api initialTab = 'kanban';
    @track activeTab = 'kanban';

    
    @track isEditingProject = false;
    @track _editProj = {};
    @track isSavingProject = false;

    get editProjName()             { return this._editProj.name             ?? (this.project?.name             || ''); }
    get editProjStatus()           { return this._editProj.status           ?? (this.project?.status           || ''); }
    get editProjMethodology()      { return this._editProj.methodology      ?? (this.project?.methodology      || ''); }
    get editProjRag()              { return this._editProj.ragStatus        ?? (this.project?.ragStatus        || ''); }
    get editProjTargetDate()       { return this._editProj.targetDate       ?? (this.project?.targetDate       || ''); }
    get editProjDescription()      { return this._editProj.description      ?? (this.project?.description      || ''); }
    get editProjType()             { return this._editProj.projectType      ?? (this.project?.projectType      || ''); }
    get editIsTechSupport()        { return this.editProjType === 'Technical Support'; }
    get editTypeMajor()            { return this.editProjType === 'Major Projects'; }
    get editTypeTechSupport()      { return this.editProjType === 'Technical Support'; }
    get editTypeAcceleration()     { return this.editProjType === 'Acceleration'; }
    get editTypeStabilization()    { return this.editProjType === 'Stabilization'; }
    get editTypeClientOnboarding() { return this.editProjType === 'Client Onboarding'; }

    get editStatusOngoing()     { return this.editProjStatus === 'On going'; }
    get editStatusNotStarted()  { return this.editProjStatus === 'Not Started'; }
    get editStatusPending()     { return this.editProjStatus === 'Pending'; }
    get editStatusOnHold()      { return this.editProjStatus === 'On Hold'; }
    get editStatusContinues()   { return this.editProjStatus === 'Continues'; }
    get editStatusDelivered()   { return this.editProjStatus === 'Delivered'; }
    get editMethodScrum()       { return this.editProjMethodology === 'Scrum'; }
    get editMethodKanban()      { return this.editProjMethodology === 'Kanban'; }
    get editMethodSAFe()        { return this.editProjMethodology === 'SAFe'; }
    get editMethodWaterfall()   { return this.editProjMethodology === 'Waterfall'; }
    get editRagGreen()          { return this.editProjRag         === 'Green'; }
    get editRagAmber()          { return this.editProjRag         === 'Amber'; }
    get editRagRed()            { return this.editProjRag         === 'Red'; }
    get editTechOwnerObj() {
        const id = this._editProj.technicalOwnerId !== undefined ? this._editProj.technicalOwnerId : this.project?.technicalOwnerId;
        const name = this._editProj.technicalOwnerName !== undefined ? this._editProj.technicalOwnerName : this.project?.technicalOwnerName;
        return id ? { id, name } : null;
    }

    get editFuncOwnerObj() {
        const id = this._editProj.functionalOwnerId !== undefined ? this._editProj.functionalOwnerId : this.project?.functionalOwnerId;
        const name = this._editProj.functionalOwnerName !== undefined ? this._editProj.functionalOwnerName : this.project?.functionalOwnerName;
        return id ? { id, name } : null;
    }

    get editBizOwnerObj() {
        const id = this._editProj.businessOwnerId !== undefined ? this._editProj.businessOwnerId : this.project?.businessOwnerId;
        const name = this._editProj.businessOwnerName !== undefined ? this._editProj.businessOwnerName : this.project?.businessOwnerName;
        return id ? { id, name } : null;
    }
    handleEditProjectToggle() { this._editProj = {}; this.isEditingProject = !this.isEditingProject; }
    handleEditProjectCancel() { this._editProj = {}; this.isEditingProject = false; }
    handleEditProjectField(e) { this._editProj = { ...this._editProj, [e.target.dataset.field]: e.target.value }; }
    // --- OWNER LOOKUP HANDLERS ---
    handleTechOwnerSelect(e) {
        this._editProj = { ...this._editProj, technicalOwnerId: e.detail.id, technicalOwnerName: e.detail.name };
    }
    handleTechOwnerClear() {
        this._editProj = { ...this._editProj, technicalOwnerId: null, technicalOwnerName: '' };
    }

    handleFuncOwnerSelect(e) {
        this._editProj = { ...this._editProj, functionalOwnerId: e.detail.id, functionalOwnerName: e.detail.name };
    }
    handleFuncOwnerClear() {
        this._editProj = { ...this._editProj, functionalOwnerId: null, functionalOwnerName: '' };
    }

    handleBizOwnerSelect(e) {
        this._editProj = { ...this._editProj, businessOwnerId: e.detail.id, businessOwnerName: e.detail.name };
    }
    handleBizOwnerClear() {
        this._editProj = { ...this._editProj, businessOwnerId: null, businessOwnerName: '' };
    }
    async handleEditProjectSave() {
        this.isSavingProject = true;
        try {
            const payload = {
                id:          this.project.id,
                name:        this._editProj.name        ?? this.project.name,
                status:      this._editProj.status      ?? this.project.status,
                methodology: this._editProj.methodology ?? this.project.methodology,
                ragStatus:   this._editProj.ragStatus   ?? this.project.ragStatus,
                targetDate:  this._editProj.targetDate  ?? this.project.targetDate,
                description: this._editProj.description ?? this.project.description,
                projectType: this._editProj.projectType ?? this.project.projectType,
                technicalOwnerId:  this._editProj.technicalOwnerId !== undefined ? this._editProj.technicalOwnerId : this.project.technicalOwnerId,
                functionalOwnerId: this._editProj.functionalOwnerId !== undefined ? this._editProj.functionalOwnerId : this.project.functionalOwnerId,
                businessOwnerId:   this._editProj.businessOwnerId !== undefined ? this._editProj.businessOwnerId : this.project.businessOwnerId,
            };
            await saveProject({ projectJson: JSON.stringify(payload) });
            this._editProj = {};
            this.isEditingProject = false;
            this.dispatchEvent(new CustomEvent('projectupdated', {
                bubbles: true, composed: true, detail: payload,
            }));
        } catch(e) { console.error('Save project error', e); }
        finally { this.isSavingProject = false; }
    }

    connectedCallback() {
        if (this.initialTab) this.activeTab = this.initialTab;
    }

    _features      = [];
    _stories       = [];
    _requirements  = [];
    _releases      = [];

    @api set features(val) {
        this._features = (val || []).map(f => ({
            ...f,
            priCls:    PRI_CLS[f.Priority__c]  || 'pdv-badge pdv-grey',
            statusCls: STATUS_CLS[f.Status__c] || 'pdv-badge pdv-grey',
            ownerName: f.Feature_Owner__r?.Name || f.Owner_Name__c || null,
        }));
    }
    get features() { return this._features; }

    @api set stories(val) {
        const today = new Date();
        today.setHours(0,0,0,0);
        this._stories = (val || []).map(s => {
            const colIdx  = KANBAN_STATUSES.indexOf(s.Status__c);
            const hasPrev = colIdx > 0;
            const hasNext = colIdx < KANBAN_STATUSES.length - 1;
            const overdue = s.Due_Date__c && new Date(s.Due_Date__c) < today && s.Status__c !== 'Done';
            return {
                ...s,
                priCls:       PRI_CLS[s.Priority__c]        || 'pdv-badge pdv-grey',
                statusCls:    STORY_STATUS_CLS[s.Status__c] || 'pdv-badge pdv-grey',
                assigneeName:   s.Assigned_To__r?.Name  || null,
                qaAssigneeName: s.QA_Assignee__r?.Name   || null,
                isOverdue:    overdue,
                isBlocked:    s.Blocked__c === true,
                canMovePrev:  hasPrev,
                canMoveNext:  hasNext,
                prevStatusKey: hasPrev ? (KANBAN_STATUSES[colIdx-1] + '|' + s.Id) : '',
                nextStatusKey: hasNext ? (KANBAN_STATUSES[colIdx+1] + '|' + s.Id) : '',
                //cardCls: 'pdv-card' + (overdue ? ' pdv-card--overdue' : ''),
                cardCls: 'pdv-card' + (s.Blocked__c ? ' pdv-card--blocked' : (overdue ? ' pdv-card--overdue' : '')),
            };
        });
    }
    get stories() { return this._stories; }

    @api set requirements(val) {
        this._requirements = (val || []).map(r => ({
            ...r,
            statusCls: REQ_STATUS_CLS[r.Status__c] || 'pdv-badge pdv-grey',
            canApprove: !r.Auto_Story_Created__c &&
                        ['Draft','Submitted','Under Review'].includes(r.Status__c),
        }));
    }
    get requirements() { return this._requirements; }

    @api set releases(val) {
        this._releases = (val || []).map(rel => {
            const cur = RELEASE_STAGES.indexOf(rel.Stage__c);
            return {
                ...rel,
                stageSteps: RELEASE_STAGES.map((label, i) => ({
                    label,
                    cls: REL_STEP_CLS[i < cur ? 'done' : i === cur ? 'active' : 'future'],
                })),
            };
        });
    }
    get releases() { return this._releases; }


    
    get featureItems()  { return this._features; }
    get isEmbedded() { return true; }

    get allRequirements() {
        return this._requirements || [];
    }

    get reqItems() {
        return this._requirements;
    }
    get storyItems()        { return this._stories; }
    get relItems()          { return this._releases; }
    get isReleaseEmbedded() { return true; }
    get releaseTabStories() {
        return this._stories.filter(s =>
            ['QA Approved','UAT','UAT Approved','Production','Done'].includes(s.Status__c)
        );
    }
    get hasFeatures()     { return this._features.length > 0; }
    get hasRequirements() { return this._requirements.length > 0; }
    get hasStories()      { return this._stories.length > 0; }
    get hasReleases()     { return this._releases.length > 0; }
    get reqCount()    { return this._requirements.length; }
    get storyCount()  { return this._stories.length; }
    get relCount()    { return this._releases.length; }
    get supportStories() {
        return this._stories.filter(s => this.project?.projectType === 'Technical Support');
    }

    get statusCls() { return STATUS_CLS[this.project?.status]     || 'pdv-badge pdv-grey'; }
    get methodCls() { return METHOD_CLS[this.project?.methodology] || 'pdv-badge pdv-grey'; }
    get ragBadgeCls() {
        const r = this.project?.ragStatus;
        if (r === 'Red')   return 'pdv-badge pdv-red';
        if (r === 'Amber') return 'pdv-badge pdv-amber';
        if (r === 'Green') return 'pdv-badge pdv-green';
        return 'pdv-badge pdv-grey';
    }

    
    get stageSteps() {
        const cur = this.project?.stage || 'Initiation';
        const ci  = PROJECT_STAGES.indexOf(cur);
        return PROJECT_STAGES.map((name, i) => ({
            name,
            cls: 'pdv-stage-btn'
               + (i < ci   ? ' pdv-stage-done'   : '')
               + (i === ci ? ' pdv-stage-active'  : '')
               + (i > ci   ? ' pdv-stage-future'  : ''),
        }));
    }

    
    get tabItems() {
        return TABS.map(t => ({
            ...t,
            cls: 'pdv-tab' + (t.id === this.activeTab ? ' pdv-tab-active' : ''),
        }));
    }
    get isKanban()        { return this.activeTab === 'kanban'; }
    get isQaBoard()       { return this.activeTab === 'qaboard'; }
    get isFeatures()      { return this.activeTab === 'features'; }
    get isRequirements()  { return this.activeTab === 'requirements'; }
    get isReleases()      { return this.activeTab === 'releases'; }
    get isSupportBoard()  { return this.activeTab === 'supportboard'; }
    handleTabClick(e) { this.activeTab = e.currentTarget.value; }

    
    _dragOverCol = null;
    get kanbanCols() {
        return STORY_BOARD_COLS.map(col => {
            const cards = this._stories.filter(s => s.Status__c === col.status);
            const isDragOver = this._dragOverCol === col.status;
            return { ...col, cards, count: cards.length, hasCards: cards.length > 0,
                colCls: 'pdv-col' + (isDragOver ? ' pdv-col--dragover' : '') };
        });
    }

    
    _qaOverCol = null;
    get qaBoardCols() {
        return QA_BOARD_COLS.map(col => {
            // First filter the stories, then map over them to add the button logic
            const cards = this._stories
                .filter(s => s.Status__c === col.status)
                .map(s => ({
                    ...s,
                    // NEW: Show button if user has permission AND story is in 'Developed'
                    canApprove: HAS_QA_APPROVER_PERM && s.Status__c === 'Developed',
                    //canMoveNext: s.Status__c === 'Developed' ? false : s.canMoveNext
                    canMoveNext: s.Status__c === 'Developed' ? false : (s.Status__c === 'QA Approved' ? HAS_UAT_APPROVER_PERM : s.canMoveNext)
                }));
                
            const isDragOver = this._qaOverCol === col.status;
            
            return { 
                ...col, 
                cards, 
                count: cards.length, 
                hasCards: cards.length > 0,
                colCls: 'pdv-col' + (isDragOver ? ' pdv-col--dragover' : '') 
            };
        });
    }
    handleQaApprove(event) {
        const storyId = event.currentTarget.value;
        const targetStatus = 'QA Approved';
        
        // Dispatch the status change event so the board updates and the trigger fires
        this.dispatchEvent(new CustomEvent('statuschange', {
            bubbles: true, 
            composed: true,
            detail: { storyId: storyId, newStatus: targetStatus }
        }));
    }
    
    handleStageClick(e) {
        this.dispatchEvent(new CustomEvent('updatestage', { bubbles:true, composed:true,
            detail: { projectId: this.project.id, newStage: e.currentTarget.value } }));
    }
    handleOpenRecord() { this._nav(this.project.id, 'Project__c'); }

    handleStoryOpen(e) {
        const id = e.currentTarget.value;
        const s  = this._stories.find(x => x.Id === id);
        if (s) this.dispatchEvent(new CustomEvent('storyopen', { bubbles:true, composed:true, detail: s }));
    }
    handleStoryNav(e)   { this._nav(e.currentTarget.value, 'Story__c'); }

    handleFeatureOpen(e) {
        this.dispatchEvent(new CustomEvent('featureopen', { bubbles:true, composed:true,
            detail: e.currentTarget.value }));
    }
    handleFeatureNav(e) { this._nav(e.currentTarget.value, 'Feature__c'); }

    handleReqOpen(e) {
        const id = e.currentTarget.value;
        const r  = this._requirements.find(x => x.Id === id);
        if (r) this.dispatchEvent(new CustomEvent('reqopen', { bubbles:true, composed:true, detail: r }));
    }
    handleReqNav(e) { this._nav(e.currentTarget.value, 'Requirement__c'); }
    handleApproveReq(e) {
        this.dispatchEvent(new CustomEvent('approvereq', { bubbles:true, composed:true,
            detail: e.currentTarget.value }));
    }

    handleReleaseOpen(e) {
        const id  = e.currentTarget.value;
        const rel = this._releases.find(x => x.Id === id);
        this.dispatchEvent(new CustomEvent('releaseopen', { bubbles:true, composed:true,
            detail: rel?.Id || id }));
    }
    handleReleaseNav(e) { this._nav(e.currentTarget.value, 'Release__c'); }
    handleAddRelease()  {
        this.dispatchEvent(new CustomEvent('addrelease', { bubbles:true, composed:true }));
    }

    
    handleNewFeature()     { this.dispatchEvent(new CustomEvent('newfeature',     { bubbles:true, composed:true })); }
    handleNewStory()       { this.dispatchEvent(new CustomEvent('newstory',       { bubbles:true, composed:true })); }
    handleNewRequirement()    { this.dispatchEvent(new CustomEvent('newrequirement',    { bubbles:true, composed:true })); }
    handleReleaseStatusChange(e) { this.dispatchEvent(new CustomEvent('statuschange',     { bubbles:true, composed:true, detail: e.detail })); }
    handleStoryOpenFromRelease(e){ this.dispatchEvent(new CustomEvent('storyopen',         { bubbles:true, composed:true, detail: e.detail })); }
    handleReqStatusChange(e)  { this.dispatchEvent(new CustomEvent('reqstatuschange',  { bubbles:true, composed:true, detail: e.detail })); }
    handleNewChangeRequest()  { this.dispatchEvent(new CustomEvent('newchangerequest',  { bubbles:true, composed:true })); }

    
    handleCardMove(event) {
        const val     = event.currentTarget.value;
        const sepIdx  = val.indexOf('|');
        if (sepIdx === -1) return;
        const newStatus = val.substring(0, sepIdx);
        const storyId   = val.substring(sepIdx + 1);
        this._doStatusChange(storyId, newStatus);
    }

    
    _draggingId     = null;
    _draggingStatus = null;

    handleDragStart(event) {
        this._draggingId     = event.currentTarget.dataset.id;
        this._draggingStatus = event.currentTarget.dataset.status;
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this._draggingId);
    }
    handleDragEnd(event) {
        event.currentTarget.classList.remove('pdv-card--dragging');
        this._draggingId     = null;
        this._draggingStatus = null;
        this._dragOverCol    = null;
        this._qaOverCol      = null;
    }
    handleDragOver(event) {
        const col = event.currentTarget.dataset.status;
        if (col === 'QA Approved' && !HAS_QA_APPROVER_PERM) {
            event.dataTransfer.dropEffect = 'none';
            return; 
        }

        event.preventDefault(); 
        event.dataTransfer.dropEffect = 'move';
        
        if (this.activeTab === 'qaboard') { 
            if (this._qaOverCol !== col) this._qaOverCol = col; 
        } else { 
            if (this._dragOverCol !== col) this._dragOverCol = col; 
        }
    }
    handleDragLeave(event) {
        const col     = event.currentTarget;
        const related = event.relatedTarget;
        if (!col.contains(related)) { this._dragOverCol = null; this._qaOverCol = null; }
    }
    handleDrop(event) {
        event.preventDefault();
        const targetStatus = event.currentTarget.dataset.status;
        
        this._dragOverCol  = null;
        this._qaOverCol    = null;
        
        if (!this._draggingId || !targetStatus) return;
        if (targetStatus === this._draggingStatus) return;
        if (targetStatus === 'QA Approved' && !HAS_QA_APPROVER_PERM) {
            return; 
        }

        this._doStatusChange(this._draggingId, targetStatus);
    }

    _doStatusChange(storyId, newStatus) {
        const today = new Date(); today.setHours(0,0,0,0);
        this._stories = this._stories.map(s => {
            if (s.Id !== storyId) return s;
            const colIdx  = ALL_STATUSES.indexOf(newStatus);
            const hasPrev = colIdx > 0;
            const hasNext = colIdx < ALL_STATUSES.length - 1;
            const overdue = s.Due_Date__c && new Date(s.Due_Date__c) < today && newStatus !== 'Done';
            return { ...s, Status__c: newStatus,
                canMovePrev: hasPrev, canMoveNext: hasNext,
                prevStatusKey: hasPrev ? (ALL_STATUSES[colIdx-1]+'|'+s.Id) : '',
                nextStatusKey: hasNext ? (ALL_STATUSES[colIdx+1]+'|'+s.Id) : '',
                cardCls: 'pdv-card' + (overdue ? ' pdv-card--overdue' : ''),
                statusCls: STORY_STATUS_CLS[newStatus] || 'pdv-badge pdv-grey',
            };
        });
        this.dispatchEvent(new CustomEvent('statuschange', {
            bubbles:true, composed:true, detail:{ storyId, newStatus },
        }));
    }

    _nav(recordId, objectApiName) {
        this.dispatchEvent(new CustomEvent('navigate', { bubbles:true, composed:true,
            detail: { recordId, objectApiName } }));
    }
}