import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import UserId from '@salesforce/user/Id';
import NAME_FIELD  from '@salesforce/schema/User.Name';
import PHOTO_FIELD from '@salesforce/schema/User.SmallPhotoUrl';

import getPrograms              from '@salesforce/apex/ProjectPlatformController.getPrograms';
import getProjects              from '@salesforce/apex/ProjectPlatformController.getProjects';
import getDashboardMetrics      from '@salesforce/apex/ProjectPlatformController.getDashboardMetrics';
import getFeaturesByProject     from '@salesforce/apex/ProjectPlatformController.getFeaturesByProject';
import getStoriesByProject      from '@salesforce/apex/ProjectPlatformController.getStoriesByProject';
import getSupportStories        from '@salesforce/apex/ProjectPlatformController.getSupportStories';
import getRequirementsByProject from '@salesforce/apex/ProjectPlatformController.getRequirementsByProject';
import getReleasesByProject     from '@salesforce/apex/ProjectPlatformController.getReleasesByProject';
import updateProjectStage       from '@salesforce/apex/ProjectPlatformController.updateProjectStage';
import updateStoryStatus        from '@salesforce/apex/ProjectPlatformController.updateStoryStatus';
import approveRequirement       from '@salesforce/apex/ProjectPlatformController.approveRequirement';
import saveRelease              from '@salesforce/apex/ProjectPlatformController.saveRelease';
import saveProject              from '@salesforce/apex/ProjectPlatformController.saveProject';
import saveProgram              from '@salesforce/apex/ProjectPlatformController.saveProgram';
import saveFeature              from '@salesforce/apex/ProjectPlatformController.saveFeature';
import saveStory                from '@salesforce/apex/ProjectPlatformController.saveStory';
import saveRequirement          from '@salesforce/apex/ProjectPlatformController.saveRequirement';

const STAGE_PILL = {
    Released:            'pp-rel-stage-pill pill-green',
    UAT:                 'pp-rel-stage-pill pill-blue',
    'Ready for Release': 'pp-rel-stage-pill pill-blue',
    'Code Freeze':       'pp-rel-stage-pill pill-amber',
    Development:         'pp-rel-stage-pill pill-amber',
    Planning:            'pp-rel-stage-pill pill-grey',
};

const NAV = [
    { id: 'dashboard',    label: 'Dashboard',      icon: 'utility:home' },
    { id: 'programmes',   label: 'Programmes',     icon: 'utility:layers' },
    { id: 'projects',     label: 'Projects',       icon: 'utility:cases' },
    { id: 'qaboard',      label: 'QA Board',       icon: 'utility:check' },
    { id: 'releaseboard', label: 'Release Board',  icon: 'utility:package' },
    { id: 'supportboard', label: 'Support Board',  icon: 'utility:service_contract' },
];

export default class ProjectPlatform extends NavigationMixin(LightningElement) {

    userId = UserId;

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD, PHOTO_FIELD] })
    wiredUser;

    get userName()  { return getFieldValue(this.wiredUser.data, NAME_FIELD)  || ''; }
    get userPhoto() { return getFieldValue(this.wiredUser.data, PHOTO_FIELD) || ''; }

    @track activeNav       = 'dashboard';
    @track selectedProject = null;
    @track isLoading       = false;

    get selectedProjectId() { return this.selectedProject?.id || null; }

    get navItems() {
        return NAV.map(n => ({
            ...n,
            cls: 'pp-nav-btn' + (this.activeNav === n.id && !this.selectedProjectId ? ' pp-nav-active' : ''),
        }));
    }

    get showDashboard()     { return !this.selectedProjectId && this.activeNav === 'dashboard'; }
    get showProgrammes()    { return !this.selectedProjectId && this.activeNav === 'programmes'; }
    get showProjectList()   { return !this.selectedProjectId && this.activeNav === 'projects'; }
    get showProjectDetail() { return !!this.selectedProjectId; }
    get showReleaseBoard()  { return !this.selectedProjectId && this.activeNav === 'releaseboard'; }
    get showQABoard()       { return this.activeNav === 'qaboard' && !this.selectedProjectId; }
    get showSupportBoard()  { return !this.selectedProjectId && this.activeNav === 'supportboard'; }

    @track metrics             = {};
    @track programList         = [];
    @track projectList         = [];
    @track featureList         = [];
    @track requestList         = [];
    @track requirementList     = [];
    @track _releases           = [];
    @track _initialTab         = 'kanban';
             _pendingReleaseId = null;
    @track releaseBoardRequests  = [];
    @track qaBoardRequests       = [];
    @track supportBoardRequests  = [];

    get recentProjects() { return (this.projectList || []).slice(0, 6); }

    get releaseList() {
        return (this._releases || []).map(r => ({
            ...r,
            stagePill: STAGE_PILL[r.Stage__c] || 'pp-rel-stage-pill pill-grey',
        }));
    }

    connectedCallback() {
        this._loadDashboard();
        this._loadProjects();
        this._loadPrograms();
    }

    _loadDashboard() {
        getDashboardMetrics()
            .then(d => { this.metrics = d || {}; })
            .catch(e => this._err(e));
    }

    _loadProjects() {
        getProjects()
            .then(p => { this.projectList = p || []; })
            .catch(e => this._err(e));
    }

    _loadPrograms() {
        getPrograms()
            .then(p => { this.programList = p || []; })
            .catch(e => this._err(e));
    }

    _loadProjectDetail(projectId) {
        this.isLoading = true;
        Promise.all([
            getFeaturesByProject({ projectId }),
            getStoriesByProject({ projectId }),
            getRequirementsByProject({ projectId }),
            getReleasesByProject({ projectId }),
        ]).then(([f, s, r, rel]) => {
            this.featureList     = f   || [];
            this.requestList     = s   || [];
            this.requirementList = r   || [];
            this._releases       = rel || [];
            if (this._pendingReleaseId) {
                const target = (rel || []).find(x => x.Id === this._pendingReleaseId);
                if (target) {
                    this.activeRelease   = target;
                    this.showReleaseModal = true;
                }
                this._pendingReleaseId = null;
            }
            this.isLoading = false;
        }).catch(e => { this._err(e); this.isLoading = false; });
    }

    _loadGlobalRequests() {
        this.isLoading = true;
        getStoriesByProject({ projectId: null })
            .then(s => { this.requestList = s || []; })
            .catch(() => { this.requestList = []; })
            .finally(() => { this.isLoading = false; });
    }

    _loadAllRequirements() {
        this.isLoading = true;
        getRequirementsByProject({ projectId: null })
            .then(r => { this.requirementList = r || []; })
            .catch(() => { this.requirementList = []; })
            .finally(() => { this.isLoading = false; });
    }

    _loadReleaseBoardRequests() {
        this.isLoading = true;
        getStoriesByProject({ projectId: null })
            .then(all => {
                this.releaseBoardRequests = (all || []).filter(s =>
                    ['QA Approved', 'UAT', 'UAT Approved', 'Production', 'Done'].includes(s.Status__c)
                );
            })
            .catch(() => { this.releaseBoardRequests = []; })
            .finally(() => { this.isLoading = false; });

            console.log('this.releaseBoardRequests==> ',this.releaseBoardRequests);
    }

    _loadQABoardRequests() {
        this.isLoading = true;
        const projectId = this.selectedProjectId || null;
        getStoriesByProject({ projectId })
            .then(all => {
                this.qaBoardRequests = (all || []).filter(s =>
                    ['Developed', 'QA Approved'].includes(s.Status__c)
                );
            })
            .catch(() => { this.qaBoardRequests = []; })
            .finally(() => { this.isLoading = false; });
    }

    _loadSupportBoardRequests() {
        this.isLoading = true;
        getSupportStories()
            .then(s => { this.supportBoardRequests = s || []; })
            .catch(() => { this.supportBoardRequests = []; })
            .finally(() => { this.isLoading = false; });
    }

    handleNavClick(event) {
        const nav = event.currentTarget.value;
        this.selectedProject = null;
        this._releases = [];
        this.activeNav = nav;
        if (nav === 'qaboard')      this._loadQABoardRequests();
        if (nav === 'releaseboard') this._loadReleaseBoardRequests();
        if (nav === 'supportboard') this._loadSupportBoardRequests();
        if (nav === 'programmes')   this._loadPrograms();
    }

    handleGoToProjects() {
        this.activeNav = 'projects';
        this.selectedProject = null;
        this._releases = [];
    }

    handleBackToList() {
        this.selectedProject = null;
        this._releases = [];
        this._initialTab = 'kanban';
        this.activeNav = 'projects';
        this._loadProjects();
    }

    handleOpenProjectEvent(event) { this._openProject(event.detail); }

    handleDashboardReleaseOpen(event) {
        const { projectId, releaseId } = event.detail;
        const proj = (this.projectList || []).find(p => p.id === projectId)
                  || { id: projectId, name: '' };
        this._pendingReleaseId = releaseId;
        this._openProject(proj, 'releases');
    }

    _openProject(proj, tab) {
        this.selectedProject = proj;
        this._initialTab = tab || 'kanban';
        this._loadProjectDetail(proj.id);
        this._loadQABoardRequests();
    }

    handleProjectUpdated(event) {
        const d = event.detail;
        this.selectedProject = { ...this.selectedProject, ...d };
        this.projectList = this.projectList.map(p =>
            p.id === d.id ? { ...p, ...d } : p
        );
        this._toast('Project updated', 'success');
    }

    handleUpdateStage(event) {
        const { projectId, newStage } = event.detail;
        updateProjectStage({ projectId, newStage })
            .then(() => {
                this.selectedProject = { ...this.selectedProject, stage: newStage };
                this._toast('Stage updated to ' + newStage, 'success');
            })
            .catch(e => this._err(e));
    }

    handleStatusChange(event) {
        const { storyId, newStatus } = event.detail;
        const patch = s => s.Id === storyId ? { ...s, Status__c: newStatus } : s;
        this.requestList         = this.requestList.map(patch);
        this.qaBoardRequests     = this.qaBoardRequests.map(patch)
            .filter(s => ['Developed','QA Approved'].includes(s.Status__c));
        this.releaseBoardRequests= this.releaseBoardRequests.map(patch)
            .filter(s => ['QA Approved','UAT','UAT Approved','Production','Done'].includes(s.Status__c));
        this.supportBoardRequests= this.supportBoardRequests.map(patch);
        if (this.activeStory?.Id === storyId) {
            this.activeStory = { ...this.activeStory, Status__c: newStatus };
        }
        updateStoryStatus({ storyId, newStatus })
            .then(() => {
                if (newStatus === 'Done') this._toast('Request marked Done!', 'success');
                if (['Developed','QA Approved'].includes(newStatus)) this._loadQABoardRequests();
                if (['QA Approved','UAT','UAT Approved','Production','Done'].includes(newStatus)) this._loadReleaseBoardRequests();
                const modal = this.template.querySelector('c-story-detail-modal');
                if (modal) {
                    modal.refreshHistory();
                }
            })
            .catch(e => {
                this._err(e);
                if (this.selectedProjectId) this._loadProjectDetail(this.selectedProjectId);
            });
    }

    handleApproveReq(event) {
        const raw = event.detail;
        const reqId = typeof raw === 'string' ? raw : (raw?.Id || raw?.requirementId);
        this._doApprove(reqId);
    }

    handleModalApprove(event) {
        const raw = event.detail;
        const reqId = typeof raw === 'string' ? raw : (raw?.Id || raw?.requirementId);
        this._doApprove(reqId);
    }

    _doApprove(reqId) {
        if (!reqId) return;
        approveRequirement({ requirementId: reqId })
            .then(() => {
                this.activeRequirement = null;
                if (this.selectedProjectId) {
                    this._loadProjectDetail(this.selectedProjectId);
                } else {
                    this._loadAllRequirements();
                }
                this._toast('Requirement approved — Request created!', 'success');
            })
            .catch(e => this._err(e));
    }

    @track activeStory       = null;
    @track activeRequirement = null;
    @track activeFeatureId   = null;
    @track showReleaseModal  = false;
    @track activeRelease     = null;

    handleStoryOpen(event)   { this.activeStory = event.detail; }
    handleReqOpen(event)     { this.activeRequirement = event.detail; }

    handleReqOpenFromModal(event) {
        const raw = event.detail;
        const reqId = typeof raw === 'string' ? raw : (raw?.Id || raw?.id);
        const req = this.requirementList.find(r => r.Id === reqId);
        if (req) { this.activeRequirement = req; }
    }

    handleStoryLinkFromReq(event) {
        const storyId = event.detail;
        const story = this.requestList.find(s => s.Id === storyId)
                   || this.releaseBoardRequests.find(s => s.Id === storyId);
        if (story) {
            this.activeRequirement = null;
            this.activeStory = story;
        } else {
            getStoriesByProject({ projectId: null })
                .then(all => {
                    const s = (all || []).find(x => x.Id === storyId);
                    if (s) { this.activeRequirement = null; this.activeStory = s; }
                })
                .catch(e => this._err(e));
        }
    }

    handleReqStatusChange(event) {
        const { reqId, newStatus } = event.detail;
        if (this.activeRequirement && this.activeRequirement.Id === reqId) {
            this.activeRequirement = { ...this.activeRequirement, Status__c: newStatus };
        }
        saveRequirement({ requirementJson: JSON.stringify({ id: reqId, status: newStatus }) })
            .then(() => { if (this.selectedProjectId) this._loadProjectDetail(this.selectedProjectId); })
            .catch(e => this._err(e));
    }

    handleReqUpdated()    { if (this.selectedProjectId) this._loadProjectDetail(this.selectedProjectId); }
    handleStoryUpdated()  { if (this.selectedProjectId) this._loadProjectDetail(this.selectedProjectId); }

    handleFeatureOpen(event) {
        const raw = event.detail;
        this.activeFeatureId = typeof raw === 'string' ? raw : (raw?.Id || raw?.id);
    }

    handleReleaseOpen(event) {
        const raw   = event.detail;
        const relId = typeof raw === 'string' ? raw : (raw?.Id || raw?.id);
        this.activeRelease   = this._releases.find(r => r.Id === relId) || null;
        this.showReleaseModal = true;
    }

    handleAddRelease() {
        this.activeRelease   = null;
        this.showReleaseModal = true;
    }

    handleCloseModals() {
        this.activeStory       = null;
        this.activeRequirement = null;
        this.activeFeatureId   = null;
        this.showReleaseModal  = false;
        this.activeRelease     = null;
    }

    handleReleaseSave(event) {
        const payload = { ...event.detail, projectId: this.selectedProjectId };
        saveRelease({ releaseJson: JSON.stringify(payload) })
            .then(() => {
                this.handleCloseModals();
                if (this.selectedProjectId) this._loadProjectDetail(this.selectedProjectId);
                this._toast('Release saved', 'success');
            })
            .catch(e => this._err(e));
    }

    @track showCreateModal     = false;
    @track createModalType     = '';
    @track createAssignedUser  = null;
    @track createQaUser        = null;
    @track createRequestorUser = null;
    @track createTechOwner     = null;
    @track createFuncOwner     = null;
    @track createBizOwner      = null;
    @track createParentProject = null;
    @track createData          = {};
    @track isSaving            = false;

    get createModalTitle() {
        const titles = {
            project:     'New Project',
            programme:   'New Programme',
            feature:     'New Feature',
            request:     'New Request',
            requirement: 'New Requirement',
        };
        return titles[this.createModalType] || 'New Record';
    }
    get isCreateProject()     { return this.createModalType === 'project'; }
    get isCreateProgramme()   { return this.createModalType === 'programme'; }
    get isCreateFeature()     { return this.createModalType === 'feature'; }
    get isCreateRequest()     { return this.createModalType === 'request'; }
    get isCreateRequirement() { return this.createModalType === 'requirement'; }
    get isNewRequest()          { return (this.createData?.category || 'New Request') === 'New Request'; }
    get isChangeRequestCreate() { return (this.createData?.category) === 'Change Request'; }
    get featureOptions()      { return this.featureList || []; }
    get programOptions()      { return this.programList || []; }
    get projectOptions()      { return (this.projectList || []).filter(p => ['On going','Active','Continues'].includes(p.status)); }
    get isTechSupportCreate() { return (this.createData?.projectType) === 'Technical Support'; }

    handleNewProject()     { this._openCreate('project',     { status: 'Not Started', ragStatus: 'Green', projectType: 'Major Projects' }); }
    handleNewProgramme()   { this._openCreate('programme',   { status: 'Not Started', ragStatus: 'Green', type: 'Major Projects' }); }
    handleNewFeature()     { this._openCreate('feature',     { status: 'Planning', priority: 'Medium' }); }
    handleNewRequest()     { this._openCreate('request',     { status: 'Backlog', priority: 'P3', storyType: 'Request', project: this.selectedProjectId }); }
    handleNewRequirement() { this._openCreate('requirement', { status: 'Draft', priority: 'Medium', category: 'New Request' }); }
    handleNewChangeRequest(){ this._openCreate('requirement', { status: 'Draft', priority: 'Medium', category: 'Change Request' }); }

    handleCreateRequestorSelect(e) { this.createRequestorUser = e.detail; }
    handleCreateRequestorClear()   { this.createRequestorUser = null; }
    handleCreateAssignedSelect(e)  { this.createAssignedUser = e.detail; }
    handleCreateAssignedClear()    { this.createAssignedUser = null; }
    handleCreateQaSelect(e)        { this.createQaUser = e.detail; }
    handleCreateQaClear()          { this.createQaUser = null; }
    handleCreateTechOwnerSelect(e) { this.createTechOwner = e.detail; }
    handleCreateTechOwnerClear()   { this.createTechOwner = null; }
    handleCreateFuncOwnerSelect(e) { this.createFuncOwner = e.detail; }
    handleCreateFuncOwnerClear()   { this.createFuncOwner = null; }
    handleCreateBizOwnerSelect(e)  { this.createBizOwner = e.detail; }
    handleCreateBizOwnerClear()    { this.createBizOwner = null; }

    _openCreate(type, defaults) {
        this.createModalType = type;
        this.createData      = { ...defaults };
        this.showCreateModal  = true;
    }

    handleCreateInput(event) {
        const field = event.target.dataset.field;
        this.createData = { ...this.createData, [field]: event.target.value };
    }

    handleCloseCreate() {
        this.createAssignedUser  = null;
        this.createQaUser        = null;
        this.createRequestorUser = null;
        this.createTechOwner     = null;
        this.createFuncOwner     = null;
        this.createBizOwner      = null;
        this.createParentProject = null;
        this.showCreateModal = false;
        this.createData      = {};
        this.createModalType = '';
    }

    stopProp(e) { e.stopPropagation(); }

    async handleSaveCreate() {
        const d = this.createData;
        if (!d.name || !d.name.trim()) {
            this._toast('Name is required', 'error');
            return;
        }
        const requestPayload = {
            ...d,
            assignedToId: this.createAssignedUser?.id || null,
            qaAssigneeId: this.createQaUser?.id        || null,
        };
        const reqPayload = {
            ...d,
            requestor: this.createRequestorUser?.name || d.requestor || '',
        };
        const projPayload = {
            ...d,
            technicalOwnerId:  this.createTechOwner?.id  || null,
            functionalOwnerId: this.createFuncOwner?.id  || null,
            businessOwnerId:   this.createBizOwner?.id   || null,
            parentProjectId:   this.createParentProject  || null,
            ownerId:           this.createTechOwner?.id  || null,
        };
        const progPayload = {
            ...d,
            ownerId: this.createTechOwner?.id || null,
        };
        this.isSaving = true;
        try {
            if (this.createModalType === 'project') {
                await saveProject({ projectJson: JSON.stringify(projPayload) });
                this._loadProjects();
                this._loadDashboard();
                this._loadPrograms();
            } else if (this.createModalType === 'programme') {
                await saveProgram({ programJson: JSON.stringify(progPayload) });
                this._loadPrograms();
                this._loadDashboard();
            } else if (this.createModalType === 'feature') {
                await saveFeature({ featureJson: JSON.stringify({ ...d, projectId: this.selectedProjectId }) });
                this._loadProjectDetail(this.selectedProjectId);
            } else if (this.createModalType === 'request') {
                await saveStory({ storyJson: JSON.stringify({ ...requestPayload, projectIds: [this.selectedProjectId] }) });
                this._loadProjectDetail(this.selectedProjectId);
            } else if (this.createModalType === 'requirement') {
                await saveRequirement({ requirementJson: JSON.stringify({ ...reqPayload, projectId: this.selectedProjectId }) });
                this._loadProjectDetail(this.selectedProjectId);
            }
            this._toast('Saved successfully', 'success');
            this.handleCloseCreate();
        } catch (e) {
            this._err(e);
        } finally {
            this.isSaving = false;
        }
    }

    handleNavigate(event) {
        const { recordId, objectApiName } = event.detail;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName, actionName: 'view' },
        });
    }

    handleReleaseBoardStatusChange(event) {
        const { storyId, newStatus } = event.detail;
        this.releaseBoardRequests = this.releaseBoardRequests.map(s =>
            s.Id === storyId ? { ...s, Status__c: newStatus } : s
        );
        updateStoryStatus({ storyId, newStatus })
            .then(() => { if (newStatus === 'Production') this._toast('Request moved to Production!', 'success'); })
            .catch(e => { this._err(e); this._loadReleaseBoardRequests(); });
    }

    _toast(msg, type) {
        this.dispatchEvent(new ShowToastEvent({ title: msg, variant: type }));
    }
    _err(e) {
        const msg = e?.body?.message || e?.message || 'An error occurred';
        this.dispatchEvent(new ShowToastEvent({ title: msg, variant: 'error' }));
        console.error(e);
    }
}