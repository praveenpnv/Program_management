import { LightningElement, api } from 'lwc';

const RAG_CLS = {
    Green: 'plv-rag plv-rag-green',
    Amber: 'plv-rag plv-rag-amber',
    Red:   'plv-rag plv-rag-red',
};
const RAG_DOT = { Green: '●', Amber: '●', Red: '●' };

const STATUS_CLS = {
    'On going':   'plv-status plv-status-ongoing',
    'Not Started':'plv-status plv-status-notstarted',
    Pending:      'plv-status plv-status-pending',
    'On Hold':    'plv-status plv-status-hold',
    Continues:    'plv-status plv-status-continues',
    Delivered:    'plv-status plv-status-delivered',
    Active:       'plv-status plv-status-ongoing',
    Planning:     'plv-status plv-status-notstarted',
    Completed:    'plv-status plv-status-delivered',
};

const PRI_CLS = {
    P1: 'plv-pri plv-pri-p1',
    P2: 'plv-pri plv-pri-p2',
    P3: 'plv-pri plv-pri-p3',
    P4: 'plv-pri plv-pri-p4',
};

const TYPE_STYLE = {
    'Acceleration':      'plv-type plv-type-accel',
    'Business Expansion':'plv-type plv-type-bizexp',
    'Major Projects':    'plv-type plv-type-major',
    'Run':               'plv-type plv-type-run',
    'Sanitization':      'plv-type plv-type-san',
    'Stabilization':     'plv-type plv-type-stab',
    'Technical Support': 'plv-type plv-type-support',
};

export default class ProjectListView extends LightningElement {
    _raw = [];

    @api
    set projects(val) {
        this._raw = (val || []).map(p => {
            console.log('Project:', p.name, '| p.ownerName==> ', p.ownerName);
            
            // Explicitly return the new object
            return {
                ...p,
                ownerName: p.ownerName ? p.ownerName : 'Unassigned',
                ragCls:    RAG_CLS[p.ragStatus]   || 'plv-rag plv-rag-grey',
                ragDot:    RAG_DOT[p.ragStatus]   || '●',
                statusCls: STATUS_CLS[p.status]   || 'plv-status plv-status-notstarted',
                priCls:    PRI_CLS[p.priority]    || 'plv-pri plv-pri-p4',
                typeCls:   TYPE_STYLE[p.projectType] || 'plv-type plv-type-major',
                cardCls:   'plv-card plv-card-rag-' + (p.ragStatus || 'grey').toLowerCase(),
            };
        });
    }
    get projects()     { return this._raw; }
    get projectItems() { return this._raw; }
    get hasProjects()  { return this._raw.length > 0; }
    get projectCount() { return this._raw.length; }

    handleOpen(event) {
        const id   = event.currentTarget.value;
        const proj = this._raw.find(p => p.id === id);
        if (proj) {
            this.dispatchEvent(new CustomEvent('open', { bubbles:true, composed:true, detail: proj }));
        }
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('newproject', { bubbles:true, composed:true }));
    }
}