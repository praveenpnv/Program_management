import { LightningElement, track } from 'lwc';

const STEPS = [
    { id:'E1',  role:'exec', roleLabel:'Executive',       phase:1, phaseName:'Initiation', icon:'💼', shortLabel:'Business Case',   title:'Business Case & Budget Approval',           body:'EXEC reviews the business case, approves the budget envelope, sets strategic priority (Critical / High / Medium / Low), and nominates a Product Owner sponsor. This creates the formal project mandate and starts the clock.',                                                  obj:'Project__c created · Stage__c = Initiation · RAG_Status__c = Green · Budget__c set' },
    { id:'P1',  role:'po',   roleLabel:'Product Owner',   phase:1, phaseName:'Initiation', icon:'🚀', shortLabel:'Project Setup',   title:'Project Setup — Project Command Centre',    body:'PO creates the project record in ProTrack. Sets methodology (Scrum / Kanban / SAFe / Waterfall), target completion date, description, and initial RAG = Green. The project appears immediately on the Executive Portfolio Dashboard.',                                    obj:'saveProject() → Project__c upsert · Dashboard KPI ribbon refreshes' },
    { id:'B1',  role:'ba',   roleLabel:'Business Analyst',phase:1, phaseName:'Initiation', icon:'🔍', shortLabel:'Discovery',       title:'Requirements Discovery',                    body:'BA facilitates discovery workshops, documents business needs, and maps stakeholders. Works with EXEC and PO to define measurable success criteria. the ProTrack project Stage path tracks progression from Initiation through to Closure.',                                    obj:'Project__c.Stage__c field · Stage path bar visible in Project Detail view' },
    { id:'E2',  role:'exec', roleLabel:'Executive',       phase:1, phaseName:'Initiation', icon:'📋', shortLabel:'Charter Sign-Off',title:'Project Charter Sign-Off',                  body:'EXEC formally approves the project charter alongside the PO. The charter defines scope, success criteria, go-live date, and key stakeholders. PO advances the project Stage from Initiation to Planning — unlocking the Features and Requirements tabs.',                  obj:'Project__c.Stage__c = Planning · Stage path bar advances in Project Detail' },
    { id:'P2',  role:'po',   roleLabel:'Product Owner',   phase:2, phaseName:'Planning',   icon:'🧩', shortLabel:'Feature Decomposition',title:'Feature Decomposition — Features Tab', body:'PO breaks approved scope into Features in the Features tab. Each Feature has priority, status, description, and an optional Feature Owner. Features group requirements and stories together and appear as filter options in story and requirement forms.',              obj:'saveFeature() → Feature__c inserts · linked to Project__c · featureDetailModal for edit' },
    { id:'B2',  role:'ba',   roleLabel:'Business Analyst',phase:2, phaseName:'Planning',   icon:'📝', shortLabel:'Capture Requirements',title:'Requirement Capture — Requirements Workspace',body:'BA logs requirements in the Requirements tab kanban. Each requirement has: title, description, category (New Request or Change Request), priority, requestor, and optional feature link. Status starts as Draft. BA drags to Under Review when ready for PO sign-off.',    obj:'saveRequirement() → Requirement__c · Status__c = Draft · Category__c = New Request or Change Request' },
    { id:'BZ1', role:'biz',  roleLabel:'Business User',   phase:2, phaseName:'Planning',   icon:'📤', shortLabel:'Submit Request',  title:'Business User Submits a Request',           body:'BIZ submits a business request via the + Requirement button in the project. The form captures title, description, category, priority, and requestor name. On save, a Requirement__c is created with Status = Draft and is immediately visible to BA on the Requirements kanban board.',  obj:'saveRequirement() → Requirement__c.Status__c = Draft · appears in Draft column of Requirements kanban' },
    { id:'P3',  role:'po',   roleLabel:'Product Owner',   phase:2, phaseName:'Planning',   icon:'✅', shortLabel:'Requirement Approval',title:'Requirement Approval Gate — Requirement Modal',body:'PO opens a requirement and reviews it in the Requirement Detail Modal. The SF-path pipeline shows Draft → Under Review → Approved / Rejected. PO clicks "Approve & Create Story" to approve and auto-create a linked story in one action. Rejected requirements stay visible for reference.', obj:'approveRequirement() · Requirement__c.Status__c = Approved → RequirementApprovalService fires' },
    { id:'S1',  role:'sys',  roleLabel:'System',          phase:2, phaseName:'Planning',   icon:'⚡', shortLabel:'Auto-Story Created',title:'RequirementApprovalService — Auto-Story',   body:'On approval, RequirementApprovalService creates a Story__c with Status = Backlog, pre-fills name and description from the requirement, sets the Requirement__c lookup, and marks Auto_Story_Created__c = true. A linked story chip appears immediately on the requirement card.', obj:'RequirementApprovalService.cls → Story__c insert · Requirement__c.Auto_Story_Created__c = true · Linked_Story__c set' },
    { id:'P4',  role:'po',   roleLabel:'Product Owner',   phase:2, phaseName:'Planning',   icon:'📌', shortLabel:'Sprint Planning', title:'Story Assignment & Sprint Planning',         body:'PO assigns stories to engineers via the Assigned Engineer user lookup. Sets story points, sprint label, due date, and links each story to a feature and release. Stories appear on the Story Board in Backlog, ready to be picked up.',                         obj:'saveStory() with assignedToId, sprint, storyPoints, dueDate, releaseId' },
    { id:'D1',  role:'dev',  roleLabel:'Engineer',        phase:3, phaseName:'Execution',  icon:'📋', shortLabel:'Story Backlog',   title:'Story Board — Backlog Column',              body:'Auto-created and manually added stories land in Backlog. The Story Board shows: story type badge, priority (Critical / High / Medium / Low), feature tag, story points, assignee name, and an overdue indicator (red border when past due date). DEV sees all their assigned work at a glance.',     obj:'getStoriesByProject() · storyBoardView · Backlog / In Progress / Developed columns' },
    { id:'D2',  role:'dev',  roleLabel:'Engineer',        phase:3, phaseName:'Execution',  icon:'🖱️', shortLabel:'Kanban Flow',    title:'Move Story — Drag & Drop',                  body:'DEV drags a card to the target column. The drop zone highlights in blue on hover. On drop: the card moves instantly (optimistic UI), then updateStoryStatus() Apex is called. If Apex fails, the card rolls back. Status flow: Backlog → In Progress → Developed.',              obj:'updateStoryStatus(storyId, newStatus) · StoryStatusTrigger → StoryStatusService validates' },
    { id:'D3',  role:'dev',  roleLabel:'Engineer',        phase:3, phaseName:'Execution',  icon:'💬', shortLabel:'Story Modal',     title:'Story Detail Modal — Edit & Status Path',   body:'DEV clicks View to open the Story Detail Modal. The SF-path bar at top shows all 8 statuses: done stages show ✓, current stage is the filled dark pill, future stages are faded. DEV clicks the next stage to advance. The pencil opens inline edit for Title, Priority, Points, Sprint, Due Date, Description, and Acceptance Criteria.', obj:'storyDetailModal · handleStatusChange event · saveStory() for inline edits · storyupdated fires to refresh board' },
    { id:'D4',  role:'dev',  roleLabel:'Engineer',        phase:3, phaseName:'Execution',  icon:'🔬', shortLabel:'QA Board',        title:'Developed → QA Approved — QA Board',        body:'When DEV moves a story to Developed, it appears on the QA Board. The global QA Board (main nav) shows stories across all projects. The project QA Board tab shows stories for the selected project only. QA engineer approves by dragging to QA Approved. Approved stories then flow to the Release Board.',   obj:'qaBoardView · Status__c IN (Developed, QA Approved) · drag-drop fires statuschange' },
    { id:'S2',  role:'sys',  roleLabel:'System',          phase:3, phaseName:'Execution',  icon:'🔔', shortLabel:'Done Notification',title:'Story Done — Notification & Release Advance',body:'When any story reaches Done status, StoryCompletionService fires: (1) sends a branded HTML email to the requirement requestor, (2) checks if all Release stories are Done. If yes, the Release Stage auto-advances to UAT. Notification includes story name, feature, release version, and a direct Salesforce record link.', obj:'StoryCompletionService.cls → Messaging.sendEmail() to Requestor__c · Release__c.Stage__c auto = UAT when all Done' },
    { id:'E3',  role:'exec', roleLabel:'Executive',       phase:4, phaseName:'Monitoring', icon:'📊', shortLabel:'Portfolio Dashboard',title:'Portfolio Dashboard — Executive View',     body:'EXEC sees all active projects on the Portfolio Dashboard. The KPI ribbon shows totals for projects, stories in flight, overdue items, and next release. The portfolio table shows each project with its stage path, RAG status badge, story progress, and team. RAG is Green (on track), Amber (at risk), or Red (overdue or blocked).', obj:'getDashboardMetrics() · Project__c.RAG_Status__c · Story__c counts · nextReleases' },
    { id:'P5',  role:'po',   roleLabel:'Product Owner',   phase:4, phaseName:'Monitoring', icon:'📦', shortLabel:'Release Board',   title:'Release Board — UAT to Production',         body:'The Release Board (main nav) shows all stories in the UAT-to-Done pipeline across all projects. The project-level Releases tab shows the same kanban scoped to the current project. Columns: QA Approved → UAT → UAT Approved → Production → Done. PO advances stories after UAT sign-off via drag-drop.',   obj:'releaseBoardView · Status__c IN (QA Approved, UAT, UAT Approved, Production, Done) · project tab uses embedded=true' },
    { id:'B3',  role:'ba',   roleLabel:'Business Analyst',phase:4, phaseName:'Monitoring', icon:'📬', shortLabel:'Delivery Tracking',title:'Requirement Delivery Tracking',             body:'BA monitors delivery via the Requirements kanban. When a linked story moves to Done, the Auto_Story_Created badge on requirement cards confirms active delivery. BA can open the linked story chip directly from the requirement card to see real-time story status and audit history.',   obj:'Requirement__c.Auto_Story_Created__c chip · Linked_Story__c lookup · requirementDetailModal STORY CREATED badge' },
    { id:'BZ2', role:'biz',  roleLabel:'Business User',   phase:4, phaseName:'Monitoring', icon:'📩', shortLabel:'Delivery Email',  title:'Business User — Delivery Email',            body:'BIZ receives a branded HTML email when the story linked to their requirement is marked Done by the engineer. Email includes project name, story title, feature, completion date, and a link to the Salesforce record. BIZ can verify delivery by checking the requirement status on the kanban board.',   obj:'StoryCompletionService → email sent to Requirement__c.Requestor__c' },
    { id:'P6',  role:'po',   roleLabel:'Product Owner',   phase:5, phaseName:'Closure',    icon:'🎉', shortLabel:'Release Sign-Off', title:'Release Sign-Off — Release Modal',          body:'PO opens the Release Detail Modal to advance the release lifecycle. Stage goes from UAT → UAT Approved → Production → Done. Each change is reflected immediately on the sidebar release chips and on the Release Board. Release notes can be authored directly in the modal before sign-off.',    obj:'releaseDetailModal · saveRelease() → Release__c.Stage__c update · sidebar chips refresh' },
    { id:'E4',  role:'exec', roleLabel:'Executive',       phase:5, phaseName:'Closure',    icon:'🏁', shortLabel:'Project Closure', title:'Final Sign-Off & Project Closure',          body:'EXEC performs final stakeholder review and signs off on project closure. PO advances Project Stage to Closure. All stories are either Done or deferred to a future release. The project archives on the Dashboard and the portfolio KPI counts update automatically.',    obj:'Project__c.Stage__c = Closure · Dashboard KPI refreshes · RAG archived' },
];

const SLIDES = (function() {
    const transitions = {
        2: { type:'transition', nextPhase:2, color:'ph2', from:'Initiation', to:'Planning',   summary:'Charter signed. Project record is live. Team assembled.' },
        3: { type:'transition', nextPhase:3, color:'ph3', from:'Planning',   to:'Execution',  summary:'Features defined. Requirements approved. Stories assigned to sprints.' },
        4: { type:'transition', nextPhase:4, color:'ph4', from:'Execution',  to:'Monitoring', summary:'Stories in flight. Notifications flowing. Releases auto-advancing.' },
        5: { type:'transition', nextPhase:5, color:'ph5', from:'Monitoring', to:'Closure',    summary:'All stories done. RAG green. Release pipeline complete.' }
    };
    var slides = [{ type: 'intro' }];
    var lastPhase = 1;
    for (var i = 0; i < STEPS.length; i++) {
        var step = STEPS[i];
        if (step.phase > lastPhase && transitions[step.phase]) {
            slides.push(transitions[step.phase]);
            lastPhase = step.phase;
        }
        slides.push({ type: 'step', step: step });
    }
    slides.push({ type: 'swimlane' });
    return slides;
}());

const ROLE_ORDER  = ['exec','po','ba','dev','biz','sys'];
const ROLE_LABELS = { exec:'Executive', po:'Product Owner', ba:'Business Analyst', dev:'Engineer', biz:'Business User', sys:'System' };
const PHASE_COLS  = [1,2,3,4,5];

export default class ProtrackWalkthrough extends LightningElement {
    @track isOpen       = false;
    @track currentIndex = 0;

    get totalSlides()  { return SLIDES.length; }
    get isFirstSlide() { return this.currentIndex === 0; }
    get isLastSlide()  { return this.currentIndex === SLIDES.length - 1; }
    get currentSlide() { return SLIDES[this.currentIndex] || SLIDES[0]; }

    get isIntroSlide()      { return this.currentSlide.type === 'intro'; }
    get isStepSlide()       { return this.currentSlide.type === 'step'; }
    get isTransitionSlide() { return this.currentSlide.type === 'transition'; }
    get isSwimlaneSlide()   { return this.currentSlide.type === 'swimlane'; }

    get currentStep()          { return this.isStepSlide       ? this.currentSlide.step : null; }
    get transitionFrom()       { return this.isTransitionSlide ? this.currentSlide.from    : ''; }
    get transitionTo()         { return this.isTransitionSlide ? this.currentSlide.to      : ''; }
    get transitionNextPhase()  { return this.isTransitionSlide ? this.currentSlide.nextPhase : ''; }
    get transitionSummary()    { return this.isTransitionSlide ? this.currentSlide.summary  : ''; }

    get slideIndexDisplay() { return this.currentIndex + 1; }

    get progressStyle() {
        var pct = Math.round((this.currentIndex / (SLIDES.length - 1)) * 100);
        return 'width:' + pct + '%';
    }

    get nextLabel() {
        if (this.currentIndex === 0)                 return 'Start';
        if (this.isLastSlide)                        return 'Finish';
        if (this.currentIndex === SLIDES.length - 2) return 'See Full Lifecycle →';
        if (this.isTransitionSlide)                  return 'Enter ' + this.currentSlide.to;
        return 'Next';
    }

    get nextBtnCls() {
        var cls = 'pt-nav-btn pt-nav-next';
        if (this.currentIndex === SLIDES.length - 2) cls += ' pt-nav-finale';
        return cls;
    }

    get currentPhaseLabel() {
        if (this.isIntroSlide)      return 'Overview';
        if (this.isSwimlaneSlide)   return 'Full Lifecycle';
        if (this.isTransitionSlide) return 'Phase ' + this.currentSlide.nextPhase + ' — ' + this.currentSlide.to;
        var s = this.currentStep;
        return s ? 'Phase ' + s.phase + ' — ' + s.phaseName : '';
    }

    get phaseTagCls() {
        if (this.isStepSlide && this.currentStep)        return 'pt-phase-tag pt-ph-tag-' + this.currentStep.phase;
        if (this.isTransitionSlide && this.currentSlide) return 'pt-phase-tag pt-ph-tag-' + this.currentSlide.nextPhase;
        return 'pt-phase-tag';
    }

    get slidePanelCls() {
        var cls = 'pt-panel';
        if (this.isSwimlaneSlide)   cls += ' pt-panel-wide';
        if (this.isTransitionSlide) cls += ' pt-panel-transition';
        return cls;
    }

    get slideCls() {
        if (!this.currentStep) return 'pt-slide';
        return 'pt-slide pt-slide-step pt-slide-role-' + this.currentStep.role;
    }

    get transitionColorCls() {
        return this.isTransitionSlide ? 'pt-transition-inner pt-tr-' + this.currentSlide.color : 'pt-transition-inner';
    }

    get stepRoleCls()     { return this.currentStep ? 'pt-role-badge pt-role-' + this.currentStep.role : 'pt-role-badge'; }
    get stepPhaseDotCls() { return this.currentStep ? 'pt-phase-dot pt-ph-dot-' + this.currentStep.phase : 'pt-phase-dot'; }

    get connectorDots() {
        var stepSlides = [];
        for (var i = 0; i < SLIDES.length; i++) {
            if (SLIDES[i].type === 'step') stepSlides.push(i);
        }
        var curPos = stepSlides.indexOf(this.currentIndex);
        return stepSlides.map(function(slideIdx, pos) {
            var cls = 'pt-conn-dot';
            if (pos === curPos)      cls += ' pt-conn-active';
            else if (pos < curPos)   cls += ' pt-conn-done';
            return { key: 'c' + slideIdx, cls: cls };
        });
    }

    get dotItems() {
        var total = SLIDES.length;
        var cur   = this.currentIndex;
        var indices = [];
        if (total <= 14) {
            for (var i = 0; i < total; i++) indices.push(i);
        } else {
            var shown = {};
            shown[0] = true;
            shown[total - 1] = true;
            for (var j = Math.max(0, cur - 2); j <= Math.min(total - 1, cur + 2); j++) shown[j] = true;
            indices = Object.keys(shown).map(Number).sort(function(a,b){return a-b;});
        }
        return indices.map(function(i) {
            return { key: 'd' + i, index: i, cls: 'pt-dot' + (i === cur ? ' pt-dot-active' : '') };
        });
    }

    get swimlaneRows() {
        return ROLE_ORDER.map(function(role) {
            var roleSteps = STEPS.filter(function(s) { return s.role === role; });
            var steps = PHASE_COLS.map(function(ph) {
                var matches = roleSteps.filter(function(s) { return s.phase === ph; });
                if (!matches.length) return { id: role + '-' + ph, icon: '', shortLabel: '', cellCls: 'pt-sw-cell pt-sw-cell-empty' };
                return { id: matches[0].id, icon: matches[0].icon, shortLabel: matches[0].shortLabel, cellCls: 'pt-sw-cell pt-sw-cell-ph' + ph };
            });
            return { role: role, roleLabel: ROLE_LABELS[role], labelCls: 'pt-sw-lane-label pt-sw-label-' + role, steps: steps };
        });
    }

    openWalkthrough()  { this.currentIndex = 0; this.isOpen = true; }
    closeWalkthrough() { this.isOpen = false; }

    nextSlide() {
        if (this.isLastSlide) { this.closeWalkthrough(); return; }
        this.currentIndex = Math.min(SLIDES.length - 1, this.currentIndex + 1);
    }

    prevSlide() {
        this.currentIndex = Math.max(0, this.currentIndex - 1);
    }

    handleDotClick(event) {
        var idx = parseInt(event.currentTarget.dataset.index, 10);
        if (!isNaN(idx)) this.currentIndex = idx;
    }
}