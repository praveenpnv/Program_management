import { LightningElement, api, track } from 'lwc';

const SWIMLANE_ORDER = ['Acceleration','Business Expansion','Major Projects','Run','Sanitization','Stabilization'];

const SWIMLANE_STYLE = {
    'Acceleration':      { header: 'background:#D1FAE5;color:#065F46;border-left:4px solid #10B981', dot: '#10B981' },
    'Business Expansion':{ header: 'background:#DBEAFE;color:#1E3A8A;border-left:4px solid #3B82F6', dot: '#3B82F6' },
    'Major Projects':    { header: 'background:#FEE2E2;color:#7F1D1D;border-left:4px solid #EF4444', dot: '#EF4444' },
    'Run':               { header: 'background:#F3F4F6;color:#1F2937;border-left:4px solid #6B7280', dot: '#6B7280' },
    'Sanitization':      { header: 'background:#FEF9C3;color:#713F12;border-left:4px solid #EAB308', dot: '#EAB308' },
    'Stabilization':     { header: 'background:#EDE9FE;color:#4C1D95;border-left:4px solid #7C3AED', dot: '#7C3AED' },
};

const STATUS_CLS = {
    'On going':    'epv-status epv-status-ongoing',
    'Not Started': 'epv-status epv-status-notstarted',
    'Pending':     'epv-status epv-status-pending',
    'On Hold':     'epv-status epv-status-hold',
    'Continues':   'epv-status epv-status-continues',
    'Delivered':   'epv-status epv-status-delivered',
    'Active':      'epv-status epv-status-ongoing',
    'Completed':   'epv-status epv-status-delivered',
    'Planning':    'epv-status epv-status-notstarted',
};

const RAG_CLS = {
    Green: 'epv-rag epv-rag-green',
    Amber: 'epv-rag epv-rag-amber',
    Red:   'epv-rag epv-rag-red',
};

const PRI_CLS = {
    P1: 'epv-pri epv-pri-p1',
    P2: 'epv-pri epv-pri-p2',
    P3: 'epv-pri epv-pri-p3',
    P4: 'epv-pri epv-pri-p4',
};

export default class ExecutiveProgramView extends LightningElement {

    @api programs  = [];
    @api projects  = [];
    
    @track _filter = '';
    @track _statusFilter = '';
    @track activeProgramId = 'all';

    get filterTerm() { return this._filter.toLowerCase(); }

    get programTabs() {
        const tabs = [{ id: 'all', label: 'All Programmes' }];
        (this.programs || []).forEach(p => {
            tabs.push({ id: p.id, label: p.name });
        });
        return tabs.map(t => ({
            ...t,
            cls: 'epv-tab' + (t.id === this.activeProgramId ? ' epv-tab-active' : '')
        }));
    }

    handleTabClick(e) {
        this.activeProgramId = e.currentTarget.value;
    }

    get filteredProjects() {
        let projs = this.projects || [];
        if (this.activeProgramId !== 'all') {
            projs = projs.filter(p => p.programId === this.activeProgramId);
            console.log('stabilizationProjects==> ',projs);
        }
        return projs;
    }

    get isStabilizationTab() {
        const activeProg = (this.programs || []).find(p => p.id === this.activeProgramId);
        return activeProg && activeProg.name === 'Stabilization';
    }

    get stabilizationProjects() {
        return this.filteredProjects.map(p => {
            const done    = p.storiesDone || 0;
            const inProg  = p.storiesInProgress || 0;
            const overdue = p.storiesOverdue || 0;
            const total   = p.storiesTotal || 0;
            
            let grad = 'conic-gradient(#F1F5F9 0deg 360deg)';
            let pct = 0;
            
            if (total > 0) {
                pct = Math.round((done / total) * 100);
                const doneDeg = (done / total) * 360;
                const inProgDeg = doneDeg + ((inProg / total) * 360);
                const overdueDeg = inProgDeg + ((overdue / total) * 360);
                
                grad = `conic-gradient(
                    #16A34A 0deg ${doneDeg}deg, 
                    #3B82F6 ${doneDeg}deg ${inProgDeg}deg, 
                    #DC2626 ${inProgDeg}deg ${overdueDeg}deg, 
                    #F1F5F9 ${overdueDeg}deg 360deg
                )`;
            }

            return {
                ...p,
                storiesDone: done,
                storiesInProgress: inProg,
                storiesOverdue: overdue,
                storiesTotal: total,
                completePct: pct,
                donutStyle: `background: ${grad};`
            };
        });
    }

    get swimlanes() {
        const term   = this.filterTerm;
        const sfilt  = this._statusFilter;

        const byType = {};
        SWIMLANE_ORDER.forEach(t => { byType[t] = []; });

        this.filteredProjects.forEach(p => {
            const lane = p.projectType || 'Major Projects';
            if (!byType[lane]) byType[lane] = [];

            if (term && !p.name.toLowerCase().includes(term)) return;
            if (sfilt && p.status !== sfilt) return;

            const today    = new Date();
            const target   = p.targetDate ? new Date(p.targetDate) : null;
            const start    = p.startDate  ? new Date(p.startDate)  : null;
            let progress   = 0;
            if (start && target && target > start) {
                const total   = target - start;
                const elapsed = Math.min(today - start, total);
                progress = Math.round((elapsed / total) * 100);
                progress = Math.max(0, Math.min(100, progress));
            }

            byType[lane].push({
                ...p,
                statusCls:   STATUS_CLS[p.status]   || 'epv-status epv-status-notstarted',
                ragCls:      RAG_CLS[p.ragStatus]   || 'epv-rag epv-rag-grey',
                priCls:      PRI_CLS[p.priority]    || 'epv-pri epv-pri-p4',
                progress,
                progressBar: 'width:' + progress + '%',
                targetLabel: target ? target.toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric' }) : '—',
                isOverdue:   target && target < today && !['Delivered','Completed'].includes(p.status),
                dateCls:     (target && target < today && !['Delivered','Completed'].includes(p.status)) ? 'epv-date epv-date-overdue' : 'epv-date',
            });
        });

        const priOrder = { P1:0, P2:1, P3:2, P4:3 };
        const sort = arr => arr.sort((a,b) =>
            (priOrder[a.priority] ?? 9) - (priOrder[b.priority] ?? 9) || a.name.localeCompare(b.name)
        );

        return SWIMLANE_ORDER
            .filter(type => byType[type] && byType[type].length > 0)
            .map(type => {
                const style  = SWIMLANE_STYLE[type] || { header:'background:#F1F5F9;color:#334155;border-left:4px solid #94A3B8', dot:'#94A3B8' };
                const sorted = sort(byType[type]);
                const total  = sorted.length;
                const ongoing = sorted.filter(p => ['On going','Active','Continues'].includes(p.status)).length;
                const onhold  = sorted.filter(p => p.status === 'On Hold').length;
                const done    = sorted.filter(p => ['Delivered','Completed'].includes(p.status)).length;
                return {
                    type,
                    headerStyle: style.header,
                    dotColor:    style.dot,
                    projects:    sorted,
                    total,
                    ongoing,
                    onhold,
                    done,
                    hasProjects: sorted.length > 0,
                };
            });
    }

    get hasSwimlanes() { return this.swimlanes.length > 0; }

    get statusOptions() {
        return [
            { label: 'All Statuses', value: '' },
            { label: 'On going',     value: 'On going' },
            { label: 'Not Started',  value: 'Not Started' },
            { label: 'Pending',      value: 'Pending' },
            { label: 'On Hold',      value: 'On Hold' },
            { label: 'Continues',    value: 'Continues' },
            { label: 'Delivered',    value: 'Delivered' },
        ].map(o => ({ ...o, selected: o.value === this._statusFilter }));
    }

    get totals() {
        const all = this.filteredProjects;
        return {
            total:   all.length,
            ongoing: all.filter(p => ['On going','Active','Continues'].includes(p.status)).length,
            hold:    all.filter(p => p.status === 'On Hold').length,
            done:    all.filter(p => ['Delivered','Completed'].includes(p.status)).length,
            red:     all.filter(p => p.ragStatus === 'Red').length,
            amber:   all.filter(p => p.ragStatus === 'Amber').length,
        };
    }

    handleSearch(e)       { this._filter = e.target.value; }
    handleStatusFilter(e) { this._statusFilter = e.target.value; }

    handleOpenProject(e) {
        const id   = e.currentTarget.dataset.id;
        const proj = (this.projects || []).find(p => p.id === id);
        if (proj) {
            this.dispatchEvent(new CustomEvent('open', { bubbles: true, composed: true, detail: proj }));
        }
    }
}