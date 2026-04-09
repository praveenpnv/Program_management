import { LightningElement, api } from 'lwc';

const STAGES = ['Planning', 'Development', 'Code Freeze', 'UAT', 'Ready for Release', 'Released'];
const SHORT   = { Planning:'Plan', Development:'Dev', 'Code Freeze':'Freeze', UAT:'UAT', 'Ready for Release':'Ready', Released:'Done' };

const STAGE_CLS = {
    Released:            'pp-stage-pill pill-green',
    UAT:                 'pp-stage-pill pill-blue',
    'Ready for Release': 'pp-stage-pill pill-blue',
    'Code Freeze':       'pp-stage-pill pill-amber',
    Development:         'pp-stage-pill pill-amber',
    Planning:            'pp-stage-pill pill-grey',
};

function buildPipeline(currentStage) {
    const idx = STAGES.indexOf(currentStage);
    return STAGES.map((s, i) => {
        let cls = 'rp-pip-step rp-pip-future';
        if (i < idx)       cls = 'rp-pip-step rp-pip-past';
        else if (i === idx) cls = 'rp-pip-step rp-pip-current';
        return { label: s, shortLabel: SHORT[s] || s, cls };
    });
}

export default class ReleasePanel extends LightningElement {

    _releases    = [];
    _projectName = '';

    @api
    set releases(val) {
        this._releases = (val || []).map(r => ({
            ...r,
            stageCls:      STAGE_CLS[r.Stage__c] || 'pp-stage-pill pill-grey',
            pipelineStages: buildPipeline(r.Stage__c),
        }));
    }
    get releases() { return this._releases; }

    @api
    set projectName(val) { this._projectName = val || ''; }
    get projectName() { return this._projectName; }

    get releaseItems() { return this._releases; }
    get hasReleases()  { return this._releases.length > 0; }
    get releaseCount() { return this._releases.length || null; }

    handleOpen(event) {
        const id  = event.currentTarget.value;
        this.dispatchEvent(new CustomEvent('releaseopen', {
            bubbles:true, composed:true, detail: id,
        }));
    }

    handleAdd() {
        this.dispatchEvent(new CustomEvent('addrelease', {
            bubbles:true, composed:true,
        }));
    }
}