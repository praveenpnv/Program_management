import { LightningElement, api } from 'lwc';

const COLS = [
    { status: 'Draft',        label: 'New',         hdrStyle: 'background:#F8FAFC;color:#475569' },
    { status: 'Under Review', label: 'In Review',   hdrStyle: 'background:#FDF4FF;color:#7C3AED' },
    { status: 'Approved',     label: 'Approved',    hdrStyle: 'background:#F0FDF4;color:#16A34A' },
    { status: 'Rejected',     label: 'Rejected',    hdrStyle: 'background:#FEF2F2;color:#DC2626' },
];
const PRI_CLS = {
    Critical: 'rlv-badge rlv-red',
    High:     'rlv-badge rlv-amber',
    Medium:   'rlv-badge rlv-blue',
    Low:      'rlv-badge rlv-grey',
};

export default class RequirementListView extends LightningElement {
    _raw = [];
    _searchTerm = '';
    _draggingId = null;
    _draggingStatus = null;
    _dragOverCol = null;
    @api embedded = false;  

    @api
    set requirements(val) {
        this._raw = (val || []).map(r => ({
            ...r,
            priCls:      PRI_CLS[r.Priority__c] || 'rlv-badge rlv-grey',
            featureName: r.Feature__r?.Name || null,
            projectName: r.Project__r?.Name || (r.Feature__r?.Project__r?.Name || null),
            requestor:   r.Requestor__c || null,
            
            storyLink:   !!r.Linked_Story__c,
            storyId:     r.Linked_Story__c || null,
            storyName:   r.Linked_Story__r?.Name || null,
            storyStatus: r.Linked_Story__r?.Status__c || null,
            canApprove:  !r.Auto_Story_Created__c &&
                         ['Draft','Under Review'].includes(r.Status__c),
            cardCls: 'rlv-card',
        }));
    }
    get requirements() { return this._raw; }

    handleSearch(e) { this._searchTerm = (e.target.value || '').toLowerCase(); }

    get _filtered() {
        const q = this._searchTerm;
        if (!q) return this._raw;
        return this._raw.filter(r =>
            (r.Name || '').toLowerCase().includes(q) ||
            (r.projectName || '').toLowerCase().includes(q) ||
            (r.Requestor__c || '').toLowerCase().includes(q)
        );
    }

    get columns() {
        return COLS.map(c => {
            const cards = this._filtered.filter(r => r.Status__c === c.status);
            const isDragOver = this._dragOverCol === c.status;
            return { ...c, cards, count: cards.length, hasCards: cards.length > 0,
                     colCls: 'rlv-col' + (isDragOver ? ' rlv-col--dragover' : '') };
        });
    }

    get statItems() {
        return COLS.map(c => ({
            label: c.label,
            count: this._raw.filter(r => r.Status__c === c.status).length,
            numCls: 'rlv-stat-num',
        }));
    }

    
    handleDragStart(e) {
        const card = e.currentTarget;
        this._draggingId     = card.dataset.id;
        this._draggingStatus = card.dataset.status;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', this._draggingId);
    }
    handleDragEnd() {
        this._draggingId     = null;
        this._draggingStatus = null;
        this._dragOverCol    = null;
    }
    handleDragOver(e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        const col = e.currentTarget.dataset.col;
        if (col !== this._dragOverCol) { this._dragOverCol = col; }
    }
    handleDragLeave(e) {
        
        if (!e.currentTarget.contains(e.relatedTarget)) { this._dragOverCol = null; }
    }
    handleDrop(e) {
        e.preventDefault();
        const targetStatus = e.currentTarget.dataset.col;
        const id = this._draggingId;
        this._dragOverCol = null;
        if (!id || !targetStatus || targetStatus === this._draggingStatus) return;
        
        this._raw = this._raw.map(r => r.Id === id ? { ...r, Status__c: targetStatus } : r);
        this.dispatchEvent(new CustomEvent('reqstatuschange', {
            bubbles: true, composed: true,
            detail: { reqId: id, newStatus: targetStatus }
        }));
    }

    handleView(e) {
        const id = e.currentTarget.value;
        const r  = this._raw.find(x => x.Id === id);
        if (r) this.dispatchEvent(new CustomEvent('reqopen', { bubbles: true, composed: true, detail: r }));
    }

    handleApprove(e) {
        this.dispatchEvent(new CustomEvent('approvereq', { bubbles: true, composed: true,
            detail: e.currentTarget.value }));
    }

    handleStoryLink(e) {
        const storyId = e.currentTarget.value;
        if (!storyId) return;
        this.dispatchEvent(new CustomEvent('storylink', { bubbles: true, composed: true,
            detail: storyId }));
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('newrequirement', { bubbles: true, composed: true }));
    }
}