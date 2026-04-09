import { LightningElement, api, track } from 'lwc';

const COLS = [
    { status: 'Backlog',      label: 'Backlog',      hdrStyle: 'background:#F1F5F9;color:#475569' },
    { status: 'In Progress',  label: 'In Progress',  hdrStyle: 'background:#EFF6FF;color:#2563EB' },
    { status: 'Developed',    label: 'Developed',    hdrStyle: 'background:#F5F3FF;color:#7C3AED' },
    { status: 'QA Approved',  label: 'QA Approved',  hdrStyle: 'background:#F0FDF4;color:#16A34A' },
    { status: 'Production',   label: 'Production',   hdrStyle: 'background:#FFF7ED;color:#C2410C' },
    { status: 'Done',         label: 'Done',         hdrStyle: 'background:#D1FAE5;color:#065F46' },
];
const STATUSES = COLS.map(c => c.status);

const PRI_CLS = {
    Critical: 'sbv-badge sbv-red',
    High:     'sbv-badge sbv-amber',
    Medium:   'sbv-badge sbv-blue',
    Low:      'sbv-badge sbv-grey',
};

export default class SupportBoardView extends LightningElement {
    _raw        = [];
    _searchTerm = '';
    @track _dragOverCol = null;
    _draggingId     = null;
    _draggingStatus = null;

    @api
    set stories(val) {
        this._raw = (val || []).map(s => {
            const idx = STATUSES.indexOf(s.Status__c);
            return {
                ...s,
                priCls:           PRI_CLS[s.Priority__c]     || 'sbv-badge sbv-grey',
                assigneeName:     s.Assigned_To__r?.Name      || null,
                qaAssigneeName:   s.QA_Assignee__r?.Name      || null,
                featureName:      s.Feature__r?.Name          || null,
                projectName:      s.Project__r?.Name          || null,
                originProjectName:s.Origin_Project__r?.Name   || null,
                canMovePrev:      idx > 0,
                canMoveNext:      idx < STATUSES.length - 1,
                prevStatus:       idx > 0                       ? STATUSES[idx - 1] : null,
                nextStatus:       idx < STATUSES.length - 1     ? STATUSES[idx + 1] : null,
                cardCls:          'sbv-card',
            };
        });
    }
    get stories() { return this._raw; }

    get totalCount() { return this._raw.length; }

    get columns() {
        const term = this._searchTerm.toLowerCase();
        return COLS.map(col => {
            const cards = this._raw
                .filter(s => s.Status__c === col.status)
                .filter(s => !term || s.Name.toLowerCase().includes(term)
                    || (s.projectName || '').toLowerCase().includes(term)
                    || (s.originProjectName || '').toLowerCase().includes(term));
            return {
                ...col,
                cards,
                count: cards.length,
                hasCards: cards.length > 0,
                colCls: 'sbv-col' + (this._dragOverCol === col.status ? ' sbv-col-over' : ''),
            };
        });
    }

    handleSearch(e) { this._searchTerm = e.target.value; }

    handleView(e) {
        const id = e.currentTarget.dataset.id;
        const story = this._raw.find(s => s.Id === id);
        if (story) this.dispatchEvent(new CustomEvent('storyopen', { bubbles: true, composed: true, detail: story }));
    }

    handleArrow(e) {
        const id        = e.currentTarget.dataset.id;
        const newStatus = e.currentTarget.dataset.status;
        this._moveStory(id, newStatus);
    }

    _moveStory(id, newStatus) {
        this._raw = this._raw.map(s => s.Id === id ? { ...s, Status__c: newStatus } : s);
        this.dispatchEvent(new CustomEvent('statuschange', {
            bubbles: true, composed: true,
            detail: { storyId: id, newStatus },
        }));
    }

    handleDragStart(e) {
        this._draggingId     = e.currentTarget.dataset.id;
        this._draggingStatus = e.currentTarget.dataset.status;
        e.dataTransfer.effectAllowed = 'move';
    }
    handleDragEnd()  { this._draggingId = null; this._draggingStatus = null; this._dragOverCol = null; }
    handleDragOver(e) { e.preventDefault(); this._dragOverCol = e.currentTarget.dataset.status; }
    handleDragLeave() { this._dragOverCol = null; }
    handleDrop(e) {
        e.preventDefault();
        const targetStatus = e.currentTarget.dataset.status;
        if (this._draggingId && targetStatus && targetStatus !== this._draggingStatus)
            this._moveStory(this._draggingId, targetStatus);
        this._dragOverCol = null;
    }
}