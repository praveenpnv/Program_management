import { LightningElement, api, track } from 'lwc';

const COLS = [
    { status: 'Backlog',     label: 'Backlog',     hdrStyle: 'background:#F1F5F9;color:#475569' },
    { status: 'In Progress', label: 'In Progress', hdrStyle: 'background:#EFF6FF;color:#2563EB' },
    { status: 'Developed',   label: 'Developed',   hdrStyle: 'background:#F5F3FF;color:#7C3AED' },
];
const COL_STATUSES = COLS.map(c => c.status);

const PRI_CLS = {
    Critical: 'sbv-badge sbv-red',
    High:     'sbv-badge sbv-amber',
    Medium:   'sbv-badge sbv-blue',
    Low:      'sbv-badge sbv-grey',
};

export default class StoryBoardView extends LightningElement {

    _raw        = [];
    _searchTerm = '';
    @track _dragOverCol = null;  

    
    get stories() { return this._raw; }

    @api
    set stories(val) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        this._raw = (val || []).map(s => {
            const colIdx    = COL_STATUSES.indexOf(s.Status__c);
            const hasPrev   = colIdx > 0;
            const hasNext   = colIdx < COL_STATUSES.length - 1;
            const overdue   = s.Due_Date__c && new Date(s.Due_Date__c) < today && s.Status__c !== 'Done';
            return {
                ...s,
                priCls:       PRI_CLS[s.Priority__c] || 'sbv-badge sbv-grey',
                assigneeName: s.Assigned_To__r?.Name  || null,
                featureName:  s.Feature__r?.Name       || null,
                isOverdue:    overdue,
                canMovePrev:  hasPrev,
                canMoveNext:  hasNext,
                
                prevStatusKey: hasPrev ? (COL_STATUSES[colIdx - 1] + '|' + s.Id) : '',
                nextStatusKey: hasNext ? (COL_STATUSES[colIdx + 1] + '|' + s.Id) : '',
                cardCls: 'sbv-card' + (overdue ? ' sbv-card--overdue' : ''),
            };
        });
    }

    
    handleSearch(event) {
        this._searchTerm = (event.target.value || '').toLowerCase();
    }

    get _filtered() {
        const q = this._searchTerm;
        if (!q) return this._raw;
        return this._raw.filter(s =>
            (s.Name || '').toLowerCase().includes(q) ||
            (s.assigneeName || '').toLowerCase().includes(q) ||
            (s.featureName  || '').toLowerCase().includes(q)
        );
    }

    
    get columns() {
        return COLS.map(c => {
            const cards = this._filtered.filter(s => s.Status__c === c.status);
            const isDragOver = this._dragOverCol === c.status;
            return {
                ...c,
                cards,
                count:    cards.length,
                hasCards: cards.length > 0,
                colCls:   'sbv-col' + (isDragOver ? ' sbv-col--dragover' : ''),
            };
        });
    }

    
    handleOpen(event) {
        const id = event.currentTarget.value;
        const s  = this._raw.find(x => x.Id === id);
        if (s) {
            this.dispatchEvent(new CustomEvent('storyopen', {
                bubbles: true, composed: true, detail: s,
            }));
        }
    }

    
    
    handleMove(event) {
        const val = event.currentTarget.value;
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
        event.currentTarget.classList.add('sbv-card--dragging');
    }

    handleDragEnd(event) {
        event.currentTarget.classList.remove('sbv-card--dragging');
        this._draggingId     = null;
        this._draggingStatus = null;
        this._dragOverCol    = null;
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
        const col = event.currentTarget.dataset.status;
        if (this._dragOverCol !== col) {
            this._dragOverCol = col;
        }
    }

    handleDragLeave(event) {
        
        const col = event.currentTarget;
        const related = event.relatedTarget;
        if (!col.contains(related)) {
            this._dragOverCol = null;
        }
    }

    handleDrop(event) {
        event.preventDefault();
        const targetStatus = event.currentTarget.dataset.status;
        this._dragOverCol = null;
        if (!this._draggingId || !targetStatus) return;
        if (targetStatus === this._draggingStatus) return; 
        this._doStatusChange(this._draggingId, targetStatus);
    }

    
    _doStatusChange(storyId, newStatus) {
        
        this._raw = this._raw.map(s => {
            if (s.Id !== storyId) return s;
            const colIdx    = COL_STATUSES.indexOf(newStatus);
            const hasPrev   = colIdx > 0;
            const hasNext   = colIdx < COL_STATUSES.length - 1;
            return {
                ...s,
                Status__c:     newStatus,
                canMovePrev:   hasPrev,
                canMoveNext:   hasNext,
                prevStatusKey: hasPrev ? (COL_STATUSES[colIdx - 1] + '|' + s.Id) : '',
                nextStatusKey: hasNext ? (COL_STATUSES[colIdx + 1] + '|' + s.Id) : '',
            };
        });
        
        this.dispatchEvent(new CustomEvent('statuschange', {
            bubbles: true, composed: true,
            detail: { storyId, newStatus },
        }));
    }
}