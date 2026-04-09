import { LightningElement, api } from 'lwc';

export default class ProjectDashboardView extends LightningElement {
    _metrics        = {};
    _recentProjects = [];

    @api set metrics(val) { this._metrics = val || {}; }
    get metrics() { return this._metrics; }

    @api set recentProjects(val) { this._recentProjects = val || []; }
    get recentProjects() { return this._recentProjects; }

    get m() {
        const d = this._metrics || {};
        const n = v => (v != null ? v : 0);
        return {
            totalProjects:     n(d.totalProjects),
            activeProjects:    n(d.activeProjects),
            onHoldProjects:    n(d.onHoldProjects),
            completedProjects: n(d.completedProjects),
            redProjects:       n(d.redProjects),
            amberProjects:     n(d.amberProjects),
            greenProjects:     n(d.greenProjects),
            totalStories:      n(d.totalRequests),
            storiesDone:       n(d.requestsDone),
            storiesInProgress: n(d.requestsInProgress),
            storiesOverdue:    n(d.requestsOverdue),
            pendingApprovals:  n(d.pendingApprovals),
            upcomingReleases:  n(d.upcomingReleases),
            totalFeatures:     n(d.totalFeatures),
            totalRequirements: n(d.totalRequirements),
            completionPct:     d.totalRequests > 0 ? Math.round((n(d.requestsDone) / n(d.totalRequests)) * 100) : 0,
            completionBar:     d.totalRequests > 0 ? Math.round((n(d.requestsDone) / n(d.totalRequests)) * 100) : 0,
        };
    }

    get portfolioHealth() {
        const m = this.m;
        const total = m.redProjects + m.amberProjects + m.greenProjects || 1;
        return [
            { label: 'On Track',  count: m.greenProjects, pct: Math.round(m.greenProjects/total*100), cls: 'rag-bar rag-green', dotCls: 'rag-dot rag-dot-green', barStyle: `width:${Math.round(m.greenProjects/total*100)}%` },
            { label: 'At Risk',   count: m.amberProjects, pct: Math.round(m.amberProjects/total*100), cls: 'rag-bar rag-amber', dotCls: 'rag-dot rag-dot-amber', barStyle: `width:${Math.round(m.amberProjects/total*100)}%` },
            { label: 'Off Track', count: m.redProjects,   pct: Math.round(m.redProjects/total*100),   cls: 'rag-bar rag-red',   dotCls: 'rag-dot rag-dot-red',   barStyle: `width:${Math.round(m.redProjects/total*100)}%`   },
        ];
    }

    get projectStages() {
        const stages = ['Initiation','Planning','Execution','Monitoring','Closure'];
        const projects = this._recentProjects || [];
        return stages.map(stage => ({
            label: stage,
            count: projects.filter(p => p.stage === stage).length,
            short: stage.slice(0,3).toUpperCase(),
        }));
    }

    get portfolioProjects() {
        return (this._recentProjects || []).map(p => ({
            ...p,
            ragDot:    p.ragStatus === 'Red' ? 'proj-rag-red' : p.ragStatus === 'Amber' ? 'proj-rag-amber' : 'proj-rag-green',
            stageCls:  'proj-stage-badge',
            daysLeft:  this._daysUntil(p.targetDate),
            daysLabel: this._daysLabel(p.targetDate),
            daysCls:   this._daysCls(p.targetDate),
        }));
    }

    get nextReleases() {
        return ((this._metrics || {}).nextReleases || []).map(r => ({
            ...r,
            pct:      r.storyCount > 0 ? Math.round(r.doneCount / r.storyCount * 100) : 0,
            barWidth: r.storyCount > 0 ? Math.round(r.doneCount / r.storyCount * 100) : 0,
            barStyle: `width:${r.storyCount > 0 ? Math.round(r.doneCount / r.storyCount * 100) : 0}%`,
            daysLabel: this._daysLabel(r.goLiveDate),
            daysCls:   this._daysCls(r.goLiveDate),
            stageCls:  'rel-stage-badge',
            projectId: r.projectId,
        }));
    }

    get hasPortfolioProjects() { return this.portfolioProjects.length > 0; }
    get hasNextReleases()      { return this.nextReleases.length > 0; }
    get hasOverdue()           { return this.m.storiesOverdue > 0; }
    get hasApprovals()         { return this.m.pendingApprovals > 0; }

    get completionBarStyle() {
        return `width:${this.m.completionBar}%`;
    }
    get ringStyle() {
        const pct = this.m.completionPct;
        
        return `background: conic-gradient(#16A34A ${pct}%, #F1F5F9 ${pct}%)`;
    }

    _daysUntil(dateStr) {
        if (!dateStr) return null;
        const diff = new Date(dateStr) - new Date();
        return Math.ceil(diff / 86400000);
    }
    _daysLabel(dateStr) {
        if (!dateStr) return '';
        const d = this._daysUntil(dateStr);
        if (d < 0)  return `${Math.abs(d)}d overdue`;
        if (d === 0) return 'Today';
        if (d === 1) return 'Tomorrow';
        return `${d}d`;
    }
    _daysCls(dateStr) {
        const d = this._daysUntil(dateStr);
        if (d == null) return '';
        if (d < 0)   return 'days-overdue';
        if (d <= 7)  return 'days-urgent';
        if (d <= 30) return 'days-soon';
        return 'days-ok';
    }

    handleOpenRelease(e) {
        const { projectId, releaseId } = e.currentTarget.dataset;
        this.dispatchEvent(new CustomEvent('releaseopen', { bubbles:true, composed:true, detail: { projectId, releaseId } }));
    }

    handleViewProjects() { this.dispatchEvent(new CustomEvent('viewprojects', { bubbles:true, composed:true })); }
    handleOpen(e) {
        const proj = this.portfolioProjects.find(p => p.id === e.currentTarget.dataset.id);
        if (proj) this.dispatchEvent(new CustomEvent('open', { bubbles:true, composed:true, detail: proj }));
    }
}