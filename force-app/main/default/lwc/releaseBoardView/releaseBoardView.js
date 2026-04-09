import { LightningElement, api, track } from 'lwc';
import HAS_UAT_APPROVER_PERM from '@salesforce/customPermission/UAT_Board_Approver';

const COLS = [
    { status: 'QA Approved',  label: 'QA Approved',  hdrStyle: 'background:#F0FDF4;color:#16A34A' },
    { status: 'UAT',          label: 'UAT',          hdrStyle: 'background:#EFF6FF;color:#2563EB' },
    { status: 'UAT Approved', label: 'UAT Approved', hdrStyle: 'background:#ECFDF5;color:#059669' },
    { status: 'Production',   label: 'Production',   hdrStyle: 'background:#FFF7ED;color:#C2410C' },
    { status: 'Done',         label: 'Done',         hdrStyle: 'background:#F0FDF4;color:#15803D' },
];
const STATUSES = COLS.map(c => c.status);
const PRI_CLS = {
    Critical:'rbv-badge rbv-red', High:'rbv-badge rbv-amber',
    Medium:'rbv-badge rbv-blue',  Low:'rbv-badge rbv-grey',
};

export default class ReleaseBoardView extends LightningElement {
    @track _raw = [];
    _searchTerm = '';
    @track _dragOverCol = null;
    @api embedded = false;
    get isNotEmbedded() { return !this.embedded || this.embedded === 'false' || this.embedded === false; }
    _draggingId = null;
    _draggingStatus = null;
    @track _dateFilter = 'all';

    @api
    set stories(val) {
        this._raw = (val || []).map(s => {
            const idx = STATUSES.indexOf(s.Status__c);
            const hasPrev = idx > 0;
            const hasNext = idx < STATUSES.length - 1;
            let taggedProjects = [];
            if (s.Story_Projects__r && s.Story_Projects__r.length > 0) {
                taggedProjects = s.Story_Projects__r.map(link => link.Project__r.Name);
            }
            return {
                ...s,
                priCls:          PRI_CLS[s.Priority__c] || 'rbv-badge rbv-grey',
                assigneeName:    s.Assigned_To__r?.Name  || null,
                featureName:     s.Feature__r?.Name      || null,
                projectNames:    taggedProjects,
                hasProjects:     taggedProjects.length > 0,
                releaseName:     s.Release__r?.Name       || null,
                requirementName: s.Requirement__r?.Name   || null,
                canMovePrev:  hasPrev,
                canMoveNext:  s.Status__c === 'UAT' ? false : hasNext,
                canApprove: HAS_UAT_APPROVER_PERM && s.Status__c === 'UAT',
                prevStatusKey: hasPrev ? (STATUSES[idx-1] + '|' + s.Id) : '',
                nextStatusKey: hasNext ? (STATUSES[idx+1] + '|' + s.Id) : '',
                cardCls: 'rbv-card',
            };
        });
    }
    get stories() { return this._raw; }
    handleApprove(e) {
        const storyId = e.currentTarget.value;
        this._doMove(storyId, 'UAT Approved');
    }

    handleSearch(e) { this._searchTerm = (e.target.value || '').toLowerCase(); }

    get _filtered() {
        const q = this._searchTerm;
        if (!q) return this._raw;
        return this._raw.filter(s =>
            (s.Name || '').toLowerCase().includes(q) ||
            (s.assigneeName || '').toLowerCase().includes(q) ||
            // NEW: Search through the array of project names
            (s.projectNames && s.projectNames.some(pName => pName.toLowerCase().includes(q)))
        );
    }
    handleDateFilter(e) {
        this._dateFilter = e.target.value;
    }

    get columns() {
        return COLS.map(c => {
            let cards = this._filtered.filter(s => s.Status__c === c.status);
            
            // ONLY apply date filtering to the 'Done' column
            if (c.status === 'Done' && this._dateFilter !== 'all') {
                const cutoff = new Date();
                cutoff.setHours(0, 0, 0, 0); // Start at midnight for accurate days
                
                if (this._dateFilter === '15d') {
                    cutoff.setDate(cutoff.getDate() - 15);
                } else if (this._dateFilter === '1m') {
                    cutoff.setMonth(cutoff.getMonth() - 1);
                } else if (this._dateFilter === '2m') {
                    cutoff.setMonth(cutoff.getMonth() - 2);
                } else if (this._dateFilter === '3m') {
                    cutoff.setMonth(cutoff.getMonth() - 3);
                }

                cards = cards.filter(s => {
                    // Changed from CreatedDate to Completed_Date__c
                    // If the date is blank for some reason, we default to Date(0) so it's safely filtered out
                    const recordDate = s.Completed_Date__c ? new Date(s.Completed_Date__c) : new Date(0);
                    return recordDate >= cutoff;
                });
            }

            return {
                ...c, 
                cards, 
                count: cards.length, 
                hasCards: cards.length > 0,
                colCls: 'rbv-col' + (this._dragOverCol === c.status ? ' rbv-col--dragover' : ''),
            };
        });
    }

    
    get uatCount()    { return this._raw.filter(s => s.Status__c === 'UAT').length; }
    get signedCount() { return this._raw.filter(s => s.Status__c === 'UAT Signed Off').length; }
    get prodCount()   { return this._raw.filter(s => s.Status__c === 'Production').length; }
    get totalCount()  { return this._raw.length; }

    handleOpen(e) {
        const id = e.currentTarget.value;
        const s  = this._raw.find(x => x.Id === id);
        if (s) this.dispatchEvent(new CustomEvent('storyopen', { bubbles:true, composed:true, detail:s }));
    }

    handleMove(e) {
        const val = e.currentTarget.value;
        const sep = val.indexOf('|');
        if (sep === -1) return;
        this._doMove(val.substring(sep + 1), val.substring(0, sep));
    }

    handleDragStart(e) {
        this._draggingId = e.currentTarget.dataset.id;
        this._draggingStatus = e.currentTarget.dataset.status;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', this._draggingId);
    }
    handleDragEnd()  { this._draggingId = null; this._draggingStatus = null; this._dragOverCol = null; }
    handleDragOver(e) {
        const target = e.currentTarget.dataset.status;
        const restrictedStatuses = ['UAT Approved', 'Production', 'Done'];
        if (restrictedStatuses.includes(target) && !HAS_UAT_APPROVER_PERM) {
            e.dataTransfer.dropEffect = 'none';
            return; 
        }

        e.preventDefault(); 
        e.dataTransfer.dropEffect = 'move'; 
        this._dragOverCol = target; 
    }
    handleDragLeave(e) { 
        if (!e.currentTarget.contains(e.relatedTarget)) {
            this._dragOverCol = null; 
        }
    }
    handleDrop(e) {
        e.preventDefault();
        const target = e.currentTarget.dataset.status;
        this._dragOverCol = null;
        
        if (!this._draggingId || target === this._draggingStatus) return;
        const restrictedStatuses = ['UAT Approved', 'Production', 'Done'];
        if (restrictedStatuses.includes(target) && !HAS_UAT_APPROVER_PERM) {
            return; 
        }

        this._doMove(this._draggingId, target);
    }

    _doMove(storyId, newStatus) {
        this._raw = this._raw.map(s => {
            if (s.Id !== storyId) return s;
            const idx = STATUSES.indexOf(newStatus);
            const hasPrev = idx > 0, hasNext = idx < STATUSES.length - 1;
            return { ...s, Status__c: newStatus, canMovePrev: hasPrev, canMoveNext: hasNext,
                prevStatusKey: hasPrev ? (STATUSES[idx-1]+'|'+s.Id) : '',
                nextStatusKey: hasNext ? (STATUSES[idx+1]+'|'+s.Id) : '' };
        });
        this.dispatchEvent(new CustomEvent('statuschange', { bubbles:true, composed:true, detail:{ storyId, newStatus } }));
    }
}