import { LightningElement, api, track } from 'lwc';
import HAS_QA_APPROVER_PERM from '@salesforce/customPermission/QA_Board_Approver';
import HAS_UAT_APPROVER_PERM from '@salesforce/customPermission/UAT_Board_Approver';

const COLS = [
    { status: 'Developed',  label: 'Developed',  hdrStyle: 'background:#EFF6FF;color:#2563EB' },
    { status: 'QA Approved', label: 'QA Approved', hdrStyle: 'background:#F0FDF4;color:#16A34A' },
];
const STATUSES  = COLS.map(c => c.status);
const PRI_CLS   = {
    Critical: 'sbv-badge sbv-red', High: 'sbv-badge sbv-amber',
    Medium:   'sbv-badge sbv-blue', Low: 'sbv-badge sbv-grey',
};

export default class QaBoardView extends LightningElement {
    _raw        = [];
    _searchTerm = '';
    @track _dragOverCol = null;
    _draggingId     = null;
    _draggingStatus = null;

    @api
    set stories(val) {
        this._raw = (val || []).filter(s => STATUSES.includes(s.Status__c)).map(s => {
            const idx = STATUSES.indexOf(s.Status__c);
            return {
                ...s,
                priCls:         PRI_CLS[s.Priority__c] || 'sbv-badge sbv-grey',
                assigneeName:   s.Assigned_To__r?.Name  || null,
                qaAssigneeName: s.QA_Assignee__r?.Name   || null,
                featureName:    s.Feature__r?.Name       || null,
                canMovePrev:    idx > 0,
                canMoveNext:    idx < STATUSES.length - 1,
                prevStatus:     idx > 0                       ? STATUSES[idx - 1] : null,
                nextStatus:     idx < STATUSES.length - 1     ? STATUSES[idx + 1] : null,
                cardCls:        'sbv-card',
            };
        });
    }
    get stories() { return this._raw; }

    get columns() {
        const term = (this._searchTerm || '').toLowerCase().trim();
        
        return COLS.map(col => {
            const cards = this._raw
                .filter(s => s.Status__c === col.status)
                .filter(s => {
                    if (!term) return true;
                    return (s.Name || '').toLowerCase().includes(term) ||
                           (s.assigneeName || '').toLowerCase().includes(term) ||
                           (s.qaAssigneeName || '').toLowerCase().includes(term) ||
                           (s.projectNames && s.projectNames.some(pName => pName.toLowerCase().includes(term)));
                })
                .map(s => {
                    let allowMoveNext = s.canMoveNext;
                    let allowApprove = false;
                    let nextStat = s.nextStatus;

                    // Apply the Custom Board Logic
                    if (s.Status__c === 'Developed') {
                        allowMoveNext = false; // Hide right arrow, use Approve button instead
                        allowApprove = HAS_QA_APPROVER_PERM;
                    } else if (s.Status__c === 'QA Approved') {
                        allowMoveNext = HAS_UAT_APPROVER_PERM;
                        nextStat = 'UAT'; // Hardcode next jump since the QA board array stops here
                    }

                    return {
                        ...s,
                        nextStatus: nextStat,
                        canApprove: allowApprove,
                        canMoveNext: allowMoveNext,
                        cardCls: 'sbv-card',
                    };
                });
                
            return {
                ...col,
                cards,
                count: cards.length,
                hasCards: cards.length > 0,
                colCls: 'sbv-col' + (this._dragOverCol === col.status ? ' sbv-col-over' : ''),
            };
        });
    }
    handleQaApprove(e) {
        const id = e.currentTarget.dataset.id;
        this._moveStory(id, 'QA Approved');
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
    handleDragLeave() { this._dragOverCol = null; }
    handleDragOver(e) { 
        const targetStatus = e.currentTarget.dataset.status;

        // 🔴 SILENT BLOCK: Prevent hover effect if no permission
        if (targetStatus === 'QA Approved' && !HAS_QA_APPROVER_PERM) {
            e.dataTransfer.dropEffect = 'none';
            return;
        }

        e.preventDefault(); 
        e.dataTransfer.dropEffect = 'move';
        this._dragOverCol = targetStatus; 
    }

    handleDrop(e) {
        e.preventDefault();
        const targetStatus = e.currentTarget.dataset.status;
        this._dragOverCol = null;
        
        if (!this._draggingId || !targetStatus || targetStatus === this._draggingStatus) return;
        
        // 🔴 SILENT BLOCK: Prevent database update if no permission
        if (targetStatus === 'QA Approved' && !HAS_QA_APPROVER_PERM) {
            return;
        }

        this._moveStory(this._draggingId, targetStatus);
    }
}